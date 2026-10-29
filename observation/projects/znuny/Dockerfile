# Znuny from the official release tarball (download.znuny.org); no third-party image exists.
# The module list follows the distribution's documented Perl prerequisites; the build
# runs the bundled module checker so a missing dependency shows up in the build log.
FROM debian:bookworm-slim

ARG ZNUNY_VERSION=7.3.8

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apache2 libapache2-mod-perl2 curl ca-certificates cron bzip2 \
        libdbd-mysql-perl libtimedate-perl libnet-dns-perl libnet-ldap-perl libio-socket-ssl-perl \
        libpdf-api2-perl libsoap-lite-perl libtext-csv-xs-perl libjson-xs-perl libapache-dbi-perl \
        libxml-libxml-perl libxml-libxslt-perl libyaml-perl libyaml-libyaml-perl libarchive-zip-perl \
        libcrypt-eksblowfish-perl libencode-hanextra-perl libmail-imapclient-perl libtemplate-perl \
        libdatetime-perl libmoo-perl libauthen-sasl-perl libauthen-ntlm-perl libhash-merge-perl \
        libical-parser-perl libspreadsheet-xlsx-perl libdata-uuid-perl libjavascript-minifier-xs-perl \
        libcss-minifier-xs-perl libnet-smtp-ssl-perl libdbd-odbc-perl libcrypt-jwt-perl \
        libdatetime-timezone-perl libmime-tools-perl libtext-diff-perl libconvert-binhex-perl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/znuny.tar.gz "https://download.znuny.org/releases/znuny-${ZNUNY_VERSION}.tar.gz" \
    && tar -xzf /tmp/znuny.tar.gz -C /opt \
    && mv /opt/znuny-${ZNUNY_VERSION} /opt/otrs \
    && rm /tmp/znuny.tar.gz \
    && useradd -d /opt/otrs -c 'Znuny user' -g www-data -s /bin/bash -M -N otrs \
    && cp /opt/otrs/Kernel/Config.pm.dist /opt/otrs/Kernel/Config.pm \
    && /opt/otrs/bin/otrs.SetPermissions.pl \
    && ln -s /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/conf-enabled/zzz_znuny.conf \
    && a2enmod perl headers deflate filter \
    && (perl /opt/otrs/bin/otrs.CheckModules.pl --all || true)

ENV TZ=UTC
EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
