ARG FROM_ARCH

# Multi-stage build, see https://docs.docker.com/develop/develop-images/multistage-build/
FROM alpine AS builder

ENV VERSION 0.5.2

ADD https://github.com/sabre-io/Baikal/releases/download/$VERSION/baikal-$VERSION.zip .
RUN apk add unzip && unzip -q baikal-$VERSION.zip

# Download QEMU, see https://github.com/ckulka/docker-multi-arch-example
ARG QEMU_ARCH
ADD https://github.com/balena-io/qemu/releases/download/v3.0.0%2Bresin/qemu-3.0.0+resin-$QEMU_ARCH.tar.gz .
RUN tar zxvf qemu-3.0.0+resin-$QEMU_ARCH.tar.gz --strip-components 1


# Final Docker image
FROM $FROM_ARCH/php:7.2-apache

LABEL description="Baikal is a Cal and CardDAV server, based on sabre/dav, that includes an administrative interface for easy management."
LABEL version="0.5.2"
LABEL repository="https://github.com/ckulka/baikal-docker"
LABEL website="http://sabre.io/baikal/"

# Add QEMU
ARG QEMU_ARCH
COPY --from=builder qemu-$QEMU_ARCH-static /usr/bin

# Install Baikal and required dependencies
COPY --from=builder baikal /var/www/baikal
RUN chown -R www-data:www-data /var/www/baikal &&\
  docker-php-ext-install pdo pdo_mysql

# Configure Apache + HTTPS
COPY files/apache.conf /etc/apache2/sites-enabled/000-default.conf
RUN a2enmod rewrite ssl && openssl req -x509 -newkey rsa:2048 -subj "/C=  " -keyout /etc/ssl/private/baikal.private.pem -out /etc/ssl/private/baikal.public.pem -days 3650 -nodes

# Expose HTTPS & data directory
EXPOSE 443
VOLUME /var/www/baikal/Specific

COPY files/start.sh /opt
CMD [ "sh", "/opt/start.sh" ]
