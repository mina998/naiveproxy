#!/bin/bash
###############################################################
#################  一键安装 Naive Proxy  #######################
###############################################################
caddy_path=/usr/local/caddy
base_url=https://raw.githubusercontent.com/mina998/naiveproxy/main
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
# 创建随机字符 最长32位
random_str(){
    if [ -z "$1" ]; then
        echo $RANDOM |md5sum |cut -c 1-6
    else 
        echo $RANDOM |md5sum |cut -c 1-$1
    fi
}
domain_dns_test(){
    dns_error=0
    local local_ip=$(wget -U Mozilla -qO - http://ip.42.pl/raw)
    if [ ! -f /usr/bin/ping ]; then
        apt install iputils-ping -y
    fi
    if (ping -c 2 $1 &>/dev/null); then
        domain_ip=$(ping "$1" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
        test "$domain_ip" = "$local_ip" || dns_error=1
    fi
}
input_get(){
    while true
    do
        echo2 "^+C 取消操作" Y
        port=$(echo $[$RANDOM%60000+1000])
        user="u`random_str`"
        pass="p`random_str`"
        read -p "请输入域名" domain
        if [ -n $domain ]; then
            echo2 "开始检测域名解析结果...." G
            domain_dns_test "$domain"
            if [ $dns_error -eq 1 ]; then
                echo2 "域名解析失败."
                continue
            fi
        else
            echo2 "域名不能为空."
            continue
        fi
        read -p "请输入端口(默认:$port)" port2
        if [ -n $port2 ]; then
            port=$port2
        fi
        read -p "请输入账号(默认:$username)" username
        if [ -n $username ]; then
            user=$username
        fi
        read -p "请输入密码(默认:$password)" password
        if [ -n $username ]; then
            pass=$password
        fi
        break
    done
}
install_naive_proxy(){
    local caddy=caddy-forwardproxy-naive
    test -d $caddy_path || mkdir -p $caddy_path
    wget -N $(curl -s https://api.github.com/repos/klzgrad/forwardproxy/releases/latest | grep browser_download_url | cut -f4 -d "\"")
    tar -xvJf $caddy.tar.xz && mv $caddy/caddy $caddy_path && rm -rf $caddy.tar.xz $caddy
    if [ -f /usr/sbin/iptables ]; then
        # /usr/sbin/iptables -I INPUT -p tcp --dport $port -j ACCEPT
        iptables -P INPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -F
        apt-get purge netfilter-persistent -y
    fi
    wget -qO - $base_url/route | sed "{s/\$username/$user/;s/\$password/$pass/;s/\$domain/$domain/g;s/\$port/$port/g}" > $path/Caddyfile
}
caddy_start(){
    input_get
    install_naive_proxy
    $caddy_path/caddy fmt --overwrite $caddy_path/Caddyfile
    $caddy_path/caddy start --config $caddy_path//Caddyfile
    echo2 "等侍启动完成...." Y
    sleep 5
    echo2 "等侍启动完成...." Y
    sleep 5
    echo2 "客户端配置QUIC:" G
    echo -e "\033[32m"
    wget -qO - $base_url/client | sed "{s/\$username/$user/;s/\$password/$pass/;s/\$domain/$domain/g;s/\$port/$port/g}"
    echo -e "\033[0m"
    echo2 "客户端配置HTTPS:" G
    echo -e "\033[32m"
    wget -qO - $base_url/client | sed "{s/\$username/$user/;s/\$password/$pass/;s/\$domain/$domain/g;s/\$port/$port/g}" | sed 's/quic:/https:/'
    echo -e "\033[0m"
}
caddy_start