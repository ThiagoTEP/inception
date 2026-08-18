# User Documentation — Inception

## What services does this stack provide?

This project runs a WordPress website behind an NGINX web server, with a
MariaDB database, each in its own Docker container:

- **NGINX** — the only door into the infrastructure. It serves the site over
  HTTPS (port 443, TLSv1.2/TLSv1.3). Plain HTTP is not available.
- **WordPress (php-fpm)** — the website itself: pages, posts, comments,
  administration dashboard.
- **MariaDB** — the database where WordPress stores all its content.

## Starting and stopping the project

All commands are run from the root of the repository.

| Action                          | Command      |
|---------------------------------|--------------|
| Build and start everything      | `make`       |
| Stop the containers             | `make stop`  |
| Start them again                | `make start` |
| Stop and remove the containers  | `make down`  |
| Remove containers and volumes   | `make clean` |
| Full reset (images, data, all)  | `make fclean`|
| Rebuild from scratch            | `make re`    |

## Accessing the website

- Website: **https://thevaris.42.fr**
- Administration panel: **https://thevaris.42.fr/wp-admin**

The certificate is self-signed, so the browser will show a security warning
the first time — accept it to proceed. The domain must resolve locally:
`/etc/hosts` must contain the line `127.0.0.1 thevaris.42.fr`.

## Credentials

Passwords are **not** stored in the repository. They live in local files in
the `secrets/` directory at the root of the project:

- `secrets/db_root_password.txt` — MariaDB root password.
- `secrets/db_password.txt` — password of the MariaDB user used by WordPress.
- `secrets/credentials.txt` — WordPress passwords, one per line:
  `WP_ADMIN_PASSWORD=...` and `WP_USER_PASSWORD=...`.

Usernames (not secret) are defined in `srcs/.env`:

- WordPress administrator: `WP_ADMIN_USER` (site owner, full access).
- WordPress regular user: `WP_USER` (editor role, can write and comment).

To change a password, edit the corresponding secrets file and rebuild the
stack (`make re`).

## Checking that the services are running

```bash
docker compose -f srcs/docker-compose.yml ps   # all 3 containers "Up"
docker compose -f srcs/docker-compose.yml logs # logs of all services
docker logs nginx                              # logs of one container
```

Quick functional checks:

- `curl -k https://thevaris.42.fr` returns the site's HTML.
- `curl http://thevaris.42.fr` fails (port 80 closed) — this is expected.
- The site opens in a browser and shows the configured WordPress site, not an
  installation wizard.
