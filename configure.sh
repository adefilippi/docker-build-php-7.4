#!/usr/bin/env sh
echo  ${PHPIZE_DEPS}
set -ex

PHP_EXTENSIONS="opcache bcmath bz2 calendar exif gd gettext gmp json intl mysqli pdo_mysql pdo_pgsql pgsql shmop soap sockets zip"
PECL_EXTENSIONS_PACKAGES="apcu imagick sqlsrv pdo_sqlsrv mcrypt"
PECL_EXTENSIONS="apcu imagick sqlsrv pdo_sqlsrv mcrypt"
RUN_DEPS="unzip libzip icu libxslt imagemagick libmcrypt recode tidyhtml freetype libjpeg-turbo libpng libwebp libxpm make"
BUILD_DEPS="autoconf g++ libzip-dev zlib-dev libpng-dev libxml2-dev icu-dev bzip2-dev libc-dev gmp-dev libmcrypt-dev recode-dev gettext-dev tidyhtml-dev libxslt-dev imagemagick-dev freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev libxpm-dev tzdata unixodbc-dev"

apk update

apk add --no-cache fcgi file gettext bash postgresql-dev

apk add gnu-libiconv=1.15-r2
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


# Install GNU libiconv
mkdir -p /opt \
&& cd /opt \
&& wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz \
&& tar xzf libiconv-1.15.tar.gz \
&& cd libiconv-1.15 \
&& sed -i 's/_GL_WARN_ON_USE (gets, "gets is a security hole - use fgets instead");/#if HAVE_RAW_DECL_GETS\n_GL_WARN_ON_USE (gets, "gets is a security hole - use fgets instead");\n#endif/g' srclib/stdio.in.h \
&& ./configure --prefix=/usr/local \
&& make \
&& make install \
# Install PHP iconv from source
&& cd /opt \
&& wget http://php.net/distributions/php-7.1.5.tar.gz \
&& tar xzf php-7.1.5.tar.gz \
&& cd php-7.1.5/ext/iconv \
&& phpize \
&& ./configure --with-iconv=/usr/local \
&& make \
&& make install \
&& mkdir -p /etc/php7/conf.d \
&& echo "extension=iconv.so" >> /etc/php7/conf.d/iconv.ini \
# Cleanup
&& apk del $BUILD_PACKAGES \
&& rm -rf /opt \
&& rm -rf /var/cache/apk/* \
&& rm -rf /usr/share/*


docker-php-source delete
rm -r /tmp/pear/cache/* /tmp/pear/download/*

### TimeZone
cp /usr/share/zoneinfo/Europe/Paris /etc/localtime
echo "Europe/Paris" >  /etc/timezone

apk del .build-deps

### create php-session DIR
mkdir /tmp/php-sessions/
chmod +rw /tmp/php-sessions/

