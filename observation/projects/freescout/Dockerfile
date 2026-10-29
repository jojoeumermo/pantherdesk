# FreeScout from the official tagged source archive (dist branch content, vendor included).
FROM php:8.2-apache-bookworm

ARG FREESCOUT_VERSION=1.8.248

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        unzip curl libc-client-dev libkrb5-dev libpng-dev libjpeg-dev libicu-dev libzip-dev libonig-dev libxml2-dev \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" mysqli pdo_mysql mbstring xml gd intl imap zip opcache pcntl \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/fs.zip \
        "https://github.com/freescout-help-desk/freescout/archive/refs/tags/${FREESCOUT_VERSION}.zip" \
    && unzip -q /tmp/fs.zip -d /tmp/fs \
    && rm -rf /var/www/html && mv /tmp/fs/freescout-${FREESCOUT_VERSION} /var/www/html \
    && chown -R www-data:www-data /var/www/html \
    && rm -rf /tmp/fs /tmp/fs.zip

# Serve the public/ directory.
RUN sed -ri 's#/var/www/html#/var/www/html/public#g' /etc/apache2/sites-available/000-default.conf \
    && printf '<Directory /var/www/html/public>\n  AllowOverride All\n</Directory>\n' > /etc/apache2/conf-enabled/freescout.conf

ENV TZ=UTC
RUN echo "date.timezone=UTC" > /usr/local/etc/php/conf.d/tz.ini
