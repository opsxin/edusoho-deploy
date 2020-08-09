FROM php:7.1-fpm

RUN sed -i "s|http://deb.debian.org|http://mirrors.aliyun.com|g" /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
        libfreetype6-dev libjpeg62-turbo-dev libpng-dev libwebp-dev libxpm-dev \
        zlib1g-dev libzip-dev \
    && docker-php-ext-configure gd --with-gd --with-webp-dir --with-jpeg-dir \
        --with-png-dir --with-zlib-dir --with-xpm-dir --with-freetype-dir \
        --enable-gd-native-ttf \
    && docker-php-ext-install -j$(nproc) gd mbstring mysqli pdo pdo_mysql zip