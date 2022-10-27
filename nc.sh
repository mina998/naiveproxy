#!/bin/bash

###############################################################
#################  一键安装 Naive Proxy  #######################
###############################################################

caddy=caddy-forwardproxy-naive
echo2(){
    if [ "$2" = "G" ]; then
        color="38;5;71" 
    elif [ "$2" = "B" ]; then
        color="38;1;34"
    elif [ "$2" = "Y" ]; then
        color="38;5;148" 
    else
        color="38;5;203"
    fi
    echo -e "\033[${color}m${1}\033[39m"
}
domain_dns_test(){
    local ip1=$(wget -U Mozilla -qO - http://ip.42.pl/raw)
    if [ ! -f /usr/bin/ping ]; then
        apt install iputils-ping -y
    fi
    if (ping -c 2 $1 &>/dev/null); then
        domain_ip=$(ping "$1" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
    else 
        echo2 "[$1]:域名解析失败"
        exit 0
    fi
    if [[ $ip1 = $domain_ip ]] ; then
        echo2 "[$1]域名DNS解析IP: $domain_ip" G
    else
        echo2 "[$1]:域名解析目标不正确."
        exit 0
    fi
}
while true
do
    read -p "请输入域名: " domain
    read -p "请输入账号: " username
    read -p "请输入密码: " password
	echo2 "域名:$domain" Y
	echo2 "账号:$username" Y
	echo2 "密码:$password" Y
	read -p "输入确认(y): " yes
	if [ "$yes" = "y" -o "$yes" = "Y" ]; then
        echo2 "开始检测域名解析结果...." G
		domain_dns_test "$domain"
	else
		continue
    fi
    break
done
cd ~
wget -N $(curl -s https://api.github.com/repos/klzgrad/forwardproxy/releases/latest | grep browser_download_url | cut -f4 -d "\"")
tar -xvJf $caddy.tar.xz && mv $caddy/caddy /usr/bin/
rm -rf $caddy.tar.xz $caddy
port=$(echo $RANDOM)
if [[ -f /usr/sbin/iptables ]]; then
    # /usr/sbin/iptables -I INPUT -p tcp --dport $port -j ACCEPT
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
    apt-get purge netfilter-persistent
fi
cat > /etc/Caddyfile <<CONFIG
:$port, $domain:$port
tls admin@$domain
route {
    forward_proxy {
        basic_auth $username $password
        hide_ip
        hide_via
        probe_resistance
    }
    respond "caddy web server test."
}
CONFIG
caddy fmt --overwrite /etc/Caddyfile
caddy start --config /etc/Caddyfile
sleep 10
echo2 "客户端配置如下:" Y
echo -e "\033[32m"
cat <<CLIENT
{
  "listen": "socks://127.0.0.1:1080",
  "proxy": "quic://${username}:${password}@${domain}:$port",
  "log": ""
}
CLIENT
echo -e "\033[0m"
