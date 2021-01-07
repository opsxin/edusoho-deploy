#!/bin/bash

set -eu

running_group="www-data"
running_user="www-data"

ensure_group_and_user_exist() {
    if [ "$(egrep "^${running_group}:" /etc/group | wc -l)" -ne 1 ]; then
        echo "添加组: ${running_group}"
        groupadd ${running_group}
    fi

    if [ "$(egrep "^${running_user}:" /etc/passwd | wc -l)" -ne 1 ]; then
        echo "添加用户: ${running_user}"
        useradd -s /usr/sbin/nologin -g ${running_group} ${running_user}
    fi
}

centos_source() {
    echo "CentOS7: 修改国内 yum 源"
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
    yum makecache
}

install_nginx() {
    echo "开始安装 Nginx"
    if [ "${os}" == "centos" ]; then
        cat > /etc/yum.repos.d/nginx.repo << 'EOF'
[nginx-stable]
name=nginx stable repo
#baseurl=http://mirrors.ustc.edu.cn/nginx/centos/$releasever/$basearch/
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=http://mirrors.ustc.edu.cn/nginx/keys/nginx_signing.key
module_hotfixes=true
EOF
        yum makecache && yum install -y nginx
    else
        apt update && apt install -y \
            curl wget gnupg2 ca-certificates \
            apt-transport-https software-properties-common
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv ABF5BD827BD9BF62
        add-apt-repository "deb http://mirrors.ustc.edu.cn/nginx/ubuntu/ \
            $(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2) nginx"
        apt update && apt install -y nginx 
    fi
    echo "修改 nginx 运行用户和组"
    sed -e '$iclient_max_body_size 1024M;' \
        -e "s/user  nginx;/user ${running_user} ${running_group};/" \
        -i /etc/nginx/nginx.conf
    echo "添加 nginx 配置"
    mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
    cat > /etc/nginx/conf.d/edusoho.conf << 'EOF'
server {
    listen 80;
    server_name _;
    # 程序的安装路径
    root /var/www/edusoho/web;
    # 日志路径
    access_log /var/log/nginx/example.com.access.log;
    error_log /var/log/nginx/example.com.error.log;
    location / {
        index app.php;
        try_files $uri @rewriteapp;
    }
    location @rewriteapp {
        rewrite ^(.*)$ /app.php/$1 last;
    }
    location ~ ^/udisk {
        internal;
        root /var/www/edusoho/app/data/;
    }
    location ~ ^/(app|app_dev)\.php(/|$) {
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
        fastcgi_param  HTTPS              off;
        fastcgi_param HTTP_X-Sendfile-Type X-Accel-Redirect;
        fastcgi_param HTTP_X-Accel-Mapping /udisk=/var/www/edusoho/app/data/udisk;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 8 128k;
    }
    
    # 配置设置图片格式文件
    location ~* \.(jpg|jpeg|gif|png|ico|swf)$ {
        # 过期时间为3年
        expires 3y;
        
        # 关闭日志记录
        access_log off;
        # 关闭gzip压缩，减少CPU消耗，因为图片的压缩率不高。
        gzip off;
    }
    # 配置css/js文件
    location ~* \.(css|js)$ {
        access_log off;
        expires 3y;
    }
    # 禁止用户上传目录下所有.php文件的访问，提高安全性
    location ~ ^/files/.*\.(php|php7.0)$ {
        deny all;
    }
    # 以下配置允许运行.php的程序，方便于其他第三方系统的集成。
    location ~ \.php$ {
        # [改] 请根据实际php-fpm运行的方式修改
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
        fastcgi_param  HTTPS              off;
        fastcgi_param  HTTP_PROXY         "";
    }
}
EOF
    systemctl restart nginx
}

install_php() {
    echo "开始安装 PHP 7.1"
    if [ "${os}" == "centos" ]; then
        yum install -y https://mirrors.tuna.tsinghua.edu.cn/remi/enterprise/remi-release-7.rpm
#        sed -e 's!^metalink=!#metalink=!g' \
#            -e 's!^#baseurl=!baseurl=!g' \
#            -e 's!//download\.fedoraproject\.org/pub!//mirrors.tuna.tsinghua.edu.cn!g' \
#            -e 's!http://mirrors\.tuna!https://mirrors.tuna!g' \
#            -i /etc/yum.repos.d/epel*.repo
#        sed -e 's!^metalink=!#metalink=!g' \
#            -e 's!^mirrorlist=!#mirrorlist=!g' \
#            -e 's!^#baseurl=!baseurl=!g' \
#            -e '/^baseurl=/s!https\?://[^/]*/\(remi/\)\?\(.*\)!http://mirrors.huaweicloud.com/remi/\2!g;' \
#            -i /etc/yum.repos.d/remi*.repo
        yum makecache && yum install -y \
            php71-php-pear php71-php-cli php71-php-common \
            php71-php-curl php71-php-fpm php71-php-json \
            php71-php-mbstring php71-php-mcrypt php71-php-mysql php71-php-opcache \
            php71-php-zip php71-php-intl php71-php-gd php71-php-xml
        sed -e "s/apache/${running_user}/g" \
            -e "s/^listen = .*/listen = 127.0.0.1:9000/" \
            -i /etc/opt/remi/php71/php-fpm.d/www.conf
        systemctl restart php71-php-fpm
    else
        export DEBIAN_FRONTEND=noninteractive
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 4F4EA0AAE5267A6C
        add-apt-repository -y 'ppa:ondrej/php'
        apt update && apt install -y \
            php-pear php7.1-cli php7.1-common php7.1-curl php7.1-dev php7.1-fpm \
            php7.1-json php7.1-mbstring php7.1-mcrypt php7.1-mysql php7.1-opcache \
            php7.1-zip php7.1-intl php7.1-gd php7.1-xml
        echo "listen = 127.0.0.1:9000" >> /etc/php/7.1/fpm/pool.d/www.conf
        systemctl restart php7.1-fpm
    fi
}

install_mysql() {
    echo "开始安装 MySQL"
    if [ "${os}" == "centos" ]; then
#        yum install -y https://mirrors.ustc.edu.cn/mysql-repo/mysql57-community-release-el7-9.noarch.rpm
        yum install -y http://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
        yum makecache && yum install -y mysql-community-server mysql-community-client
        systemctl restart mysqld
    else
        if [ "${os_version}" -lt 2004 ]; then
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8C718D3B5072E1F5
#            add-apt-repository "deb https://mirrors.tuna.tsinghua.edu.cn/mysql/apt/ubuntu/ \
#                $(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2) mysql-5.7"
            add-apt-repository "deb https://repo.mysql.com/apt/ubuntu/ \
                $(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2) mysql-5.7"
            apt update && apt install -y mysql-server mysql-client
        else
            apt install -y mysql-server-8.0 mysql-client-8.0
        fi
        systemctl restart mysql
    fi
}

install_edusoho() {
    echo "开始下载 web 文件"
    if [ ! -d "/var/www" ]; then mkdir "/var/www"; fi
    set +e; yum install -y unzip || apt install -y unzip; set -e
    curl http://download.edusoho.com/edusoho-8.7.15.zip -o /tmp/edusoho.zip
    unzip /tmp/edusoho.zip -d "/var/www/"
    chown -R ${running_user}:${running_group} "/var/www/edusoho"
}

if [ $EUID -ne 0 ]; then
    echo "请使用 root 运行此脚本。"
    exit 1
fi 

if grep -qs "ubuntu" /etc/os-release; then
	os="ubuntu"
	os_version="$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')"
elif [ -e /etc/centos-release ]; then
	os="centos"
	os_version="$(grep -oE '[0-9]+' /etc/centos-release | head -1)"
else
	echo "暂时只支持 Ubuntu 16.04、18.04、20.04 和 CentOS 7。"
	exit 1
fi

## 修改为国内源，加速下载
#[ "${os}" == "centos" ] && centos_source

ensure_group_and_user_exist
install_nginx
install_php
install_mysql
install_edusoho
