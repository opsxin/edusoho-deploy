FROM debian:stable-20210329 AS base

ENV nginx_version="1.19.9"

RUN sed -e 's#deb.debian.org#mirrors.163.com#g' \
    -e '/security/d' -i /etc/apt/sources.list \
    && apt update \
    && apt install -y git wget build-essential \
    libpcre3 libpcre3-dev zlib1g-dev openssl libssl-dev

RUN cd /root && git clone git://github.com/vozlt/nginx-module-vts.git \
    && wget https://nginx.org/download/nginx-${nginx_version}.tar.gz -O /root/nginx.tgz \
    && tar zxvf /root/nginx.tgz \
    && cd /root/nginx-${nginx_version} \
    && ./configure --prefix=/usr/local/nginx --user=www-data --group=www-data \
    --with-compat --with-file-aio --with-threads --with-http_addition_module \
    --with-http_auth_request_module --with-http_dav_module --with-http_flv_module \
    --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module \
    --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module \
    --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module \
    --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module \
    --with-stream --with-stream_realip_module --with-stream_ssl_module \
    --with-stream_ssl_preread_module --add-module=/root/nginx-module-vts \
    && make && make install


FROM debian:stable-20210329

LABEL maintainer="hsin@opsxin.com"
LABEL edusoho-version="21.1.6"
LABEL nginx-version="1.19.9"
LABEL php-version="7.1"
LABEL nginx-export="http://IP:8080/nginx_status"

ENV TZ Asia/Shanghai

WORKDIR /usr/local/nginx

RUN sed -e 's#deb.debian.org#mirrors.163.com#g' \
    -e '/security/d' -i /etc/apt/sources.list \
    && apt update \
    && apt install -y --no-install-recommends \
        libpcre3 libpcre3-dev zlib1g-dev openssl libssl-dev \
        curl gnupg2 ca-certificates apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://packages.sury.org/php/apt.gpg -o- | apt-key add - \
    && echo "deb https://packages.sury.org/php/ buster main" | tee /etc/apt/sources.list.d/php7.list \
    && apt update && apt install -y --no-install-recommends \
        php-pear php7.1-cli php7.1-common php7.1-curl php7.1-dev php7.1-fpm \
        php7.1-json php7.1-mbstring php7.1-mcrypt php7.1-mysql php7.1-opcache \
        php7.1-zip php7.1-intl php7.1-gd php7.1-xml php7.1-redis \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /run/php

COPY --from=base /usr/local/nginx /usr/local/nginx

COPY nginx.conf /usr/local/nginx/conf/nginx.conf
COPY status.conf edusoho.conf /usr/local/nginx/conf/conf.d/
ADD --chown=www-data:www-data edusoho /var/www/edusoho/

EXPOSE 80 8080

CMD ["bash", "-c", "php-fpm7.1 && /usr/local/nginx/sbin/nginx"]
