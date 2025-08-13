FROM php:8.2-fpm-alpine

WORKDIR /var/www/html

RUN apk add \
    zip unzip git curl libpq-dev libzip-dev \
    && docker-php-ext-install pdo pdo_pgsql zip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copier le projet Laravel
COPY src/ ./

RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# copier entrypoint
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm"]
