#!/usr/bin/env sh
echo  ${PHPIZE_DEPS}
set -ex

PHP_EXTENSIONS="opcache bcmath bz2 calendar exif gd gettext gmp json intl mysqli pdo_mysql pdo_pgsql pgsql shmop soap sockets zip"
PECL_EXTENSIONS_PACKAGES="apcu imagick sqlsrv pdo_sqlsrv mcrypt"
PECL_EXTENSIONS="apcu imagick sqlsrv pdo_sqlsrv mcrypt"
RUN_DEPS="unzip libzip icu libxslt imagemagick libmcrypt recode tidyhtml freetype libjpeg-turbo libpng libwebp libxpm make"
BUILD_DEPS="autoconf g++ libzip-dev zlib-dev libpng-dev libxml2-dev icu-dev bzip2-dev libc-dev gmp-dev libmcrypt-dev recode-dev gettext-dev tidyhtml-dev libxslt-dev imagemagick-dev freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev libxpm-dev tzdata unixodbc-dev"

apk update

apk add --no-cache fcgi file gettext  bash postgresql-dev

# install gnu-libiconv and set LD_PRELOAD env to make iconv work fully on Alpine image.
# see https://github.com/docker-library/php/issues/240#issuecomment-763112749
apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.12/community/ gnu-libiconv-dev=1.15-r2
export LD_PRELOAD="/usr/lib/preloadable_libiconv.so"

apk add --no-cache --virtual rundeps ${RUN_DEPS}
apk add --no-cache --virtual .build-deps ${BUILD_DEPS}
apk add unixodbc-dev

curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.6.1.1-1_amd64.apk
curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.6.1.1-1_amd64.apk

apk add --allow-untrusted msodbcsql17_17.6.1.1-1_amd64.apk
apk add --allow-untrusted mssql-tools_17.6.1.1-1_amd64.apk

docker-php-source extract
docker-php-ext-configure gd --with-freetype --with-jpeg
docker-php-ext-install -j"$(nproc)" ${PHP_EXTENSIONS}
pecl install ${PECL_EXTENSIONS_PACKAGES}
docker-php-ext-enable ${PECL_EXTENSIONS}

docker-php-source delete
rm -r /tmp/pear/cache/* /tmp/pear/download/*

### TimeZone
cp /usr/share/zoneinfo/Europe/Paris /etc/localtime
echo "Europe/Paris" >  /etc/timezone

apk del .build-deps

### create php-session DIR
mkdir /tmp/php-sessions/
chmod +rw /tmp/php-sessions/
