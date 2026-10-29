# osTicket from the official GitHub release archive (no third-party image).
FROM php:8.2-apache-bookworm

ARG OSTICKET_VERSION=v1.18.4

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        unzip curl libc-client-dev libkrb5-dev libpng-dev libjpeg-dev libicu-dev libzip-dev libonig-dev \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" mysqli gd intl imap zip opcache \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/ost.zip \
        "https://github.com/osTicket/osTicket/releases/download/${OSTICKET_VERSION}/osTicket-${OSTICKET_VERSION}.zip" \
    && unzip -q /tmp/ost.zip -d /tmp/ost \
    && cp -a /tmp/ost/upload/. /var/www/html/ \
    && cp /var/www/html/include/ost-sampleconfig.php /var/www/html/include/ost-config.php \
    && chmod 0666 /var/www/html/include/ost-config.php \
    && chown -R www-data:www-data /var/www/html \
    && rm -rf /tmp/ost /tmp/ost.zip

ENV TZ=UTC
RUN echo "date.timezone=UTC" > /usr/local/etc/php/conf.d/tz.ini
