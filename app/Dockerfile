# One build, two images:
#   --target fpm  -> PHP-FPM with the app code (also runs queue workers, cron and migrations)
#   --target web  -> Nginx with only the public/ assets baked in

# ---- source: a stock Laravel app plus the demo routes ----
FROM composer:2 AS source
WORKDIR /app
RUN composer create-project laravel/laravel . "12.*" \
      --no-dev --no-scripts --prefer-dist --no-interaction --no-progress \
 && rm -f .env database/database.sqlite
COPY routes/web.php routes/web.php

# ---- fpm ----
FROM php:8.3-fpm-alpine AS fpm
# pcntl lets queue:work stop cleanly on SIGTERM during rollouts
RUN docker-php-ext-install -j"$(nproc)" pdo_mysql opcache bcmath pcntl
COPY docker/php.ini       /usr/local/etc/php/conf.d/zz-app.ini
# "zzz-" sorts after the image's zz-docker.conf, so our listen address wins
COPY docker/fpm-pool.conf /usr/local/etc/php-fpm.d/zzz-app.conf
# Pool sizing is set per deployment from the Helm values
ENV PHP_FPM_MAX_CHILDREN=10 \
    PHP_FPM_MAX_REQUESTS=500
WORKDIR /var/www/html
COPY --from=source --chown=www-data:www-data /app /var/www/html
USER www-data
RUN php artisan package:discover --ansi
EXPOSE 9000

# ---- web ----
FROM nginx:1.27-alpine AS web
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=source /app/public /var/www/html/public
EXPOSE 8080
