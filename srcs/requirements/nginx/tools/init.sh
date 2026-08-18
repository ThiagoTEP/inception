#!/bin/bash

mkdir -p /etc/nginx/ssl

openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/thevaris.key \
    -out /etc/nginx/ssl/thevaris.crt \
    -subj "/C=PT/ST=Lisboa/L=Lisboa/O=42/CN=${DOMAIN_NAME}"

exec nginx -g "daemon off;"
