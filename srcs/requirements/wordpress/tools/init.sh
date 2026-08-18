#!/bin/bash

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(grep WP_ADMIN_PASSWORD /run/secrets/credentials | cut -d= -f2)
WP_USER_PASSWORD=$(grep WP_USER_PASSWORD /run/secrets/credentials | cut -d= -f2)

mkdir -p /var/www/html /run/php
cd /var/www/html

tries=0
until mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"${DB_PASSWORD}" --silent; do
    tries=$((tries + 1))
    if [ "$tries" -ge 30 ]; then
        echo "MariaDB is not reachable, aborting."
        exit 1
    fi
    echo "Waiting for MariaDB... ($tries)"
    sleep 2
done

if [ ! -f wp-config.php ]; then
    wp core download --allow-root

    wp config create --allow-root \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${DB_PASSWORD} \
        --dbhost=mariadb:3306

    wp core install --allow-root \
        --url=https://${DOMAIN_NAME} \
        --title="${WP_TITLE}" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL}

    wp user create --allow-root \
        ${WP_USER} ${WP_USER_EMAIL} \
        --role=editor \
        --user_pass=${WP_USER_PASSWORD}
fi

chown -R www-data:www-data /var/www/html

exec php-fpm8.2 -F
