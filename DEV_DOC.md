# Developer Documentation — Inception

## Prerequisites

- A Linux virtual machine (Debian recommended).
- Docker Engine and the Docker Compose plugin (`docker compose`).
- `make`.
- The local domain: `/etc/hosts` containing `127.0.0.1 thevaris.42.fr`.

## Setting up the environment from scratch

1. **Clone the repository** into an empty directory.

2. **Environment file** — `srcs/.env` holds the non-sensitive configuration:

   ```
   DOMAIN_NAME=thevaris.42.fr
   MYSQL_DATABASE=wordpress
   MYSQL_USER=varisdb
   WP_TITLE=Inception
   WP_ADMIN_USER=varismaster
   WP_ADMIN_EMAIL=varismaster@thevaris.42.fr
   WP_USER=variseditor
   WP_USER_EMAIL=variseditor@thevaris.42.fr
   ```

3. **Secrets** — create the `secrets/` directory at the repository root
   (it is git-ignored on purpose):

   ```bash
   mkdir -p secrets
   echo 'SomeRootPass42.'  > secrets/db_root_password.txt
   echo 'SomeDbPass42.'    > secrets/db_password.txt
   printf 'WP_ADMIN_PASSWORD=SomeAdminPass42.\nWP_USER_PASSWORD=SomeUserPass42.\n' > secrets/credentials.txt
   ```

   They are exposed to the containers as Docker secrets under
   `/run/secrets/` (read-only files), declared in `srcs/docker-compose.yml`.

## Building and launching

The Makefile drives everything through Docker Compose:

- `make` — creates the data directories (`/home/thevaris/data/{db,wordpress}`)
  and runs `docker compose -f srcs/docker-compose.yml up -d --build`.
- `make down` / `make stop` / `make start` — lifecycle without rebuilding.
- `make clean` — `down -v` (removes containers **and** volumes).
- `make fclean` — `clean` + `docker system prune -af` + deletes the host data
  directories.
- `make re` — `fclean` followed by `make`.
- `make logs` / `make ps` — convenience wrappers.

## Project layout

```
.
├── Makefile
├── secrets/                  # local only, never committed
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/   {Dockerfile, conf/my.cnf,    tools/init.sh}
        ├── nginx/     {Dockerfile, conf/nginx.conf, tools/init.sh}
        └── wordpress/ {Dockerfile, conf/www.conf,  tools/init.sh}
```

Each image is built from `debian:bookworm`. Each `tools/init.sh` is the
container entrypoint: it performs one-time initialization (create the
database, install WordPress via wp-cli, generate the TLS certificate) and
then `exec`s the service daemon in the foreground so it runs as PID 1.

## Useful commands

```bash
# State and logs
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs -f [service]

# Shell inside a container
docker exec -it mariadb  bash
docker exec -it wordpress bash
docker exec -it nginx    bash

# Database access
docker exec -it mariadb mysql -u root -p            # root (password from secrets)
docker exec -it mariadb mysql -u varisdb -p wordpress

# Rebuild a single service
docker compose -f srcs/docker-compose.yml up -d --build nginx

# Volumes and network
docker volume ls
docker volume inspect inception_db_data inception_wp_data
docker network ls
docker network inspect inception_inception
```

## Data storage and persistence

Two **named volumes** are declared in `docker-compose.yml`, both anchored on
the host under `/home/thevaris/data` via the `local` driver options:

- `db_data` → `/home/thevaris/data/db` → mounted at `/var/lib/mysql`
  in the MariaDB container.
- `wp_data` → `/home/thevaris/data/wordpress` → mounted at `/var/www/html`
  in the WordPress and NGINX containers (NGINX serves the static files,
  php-fpm executes the PHP).

Because the data lives on the host, containers can be removed and rebuilt
(`make down && make`) — or the VM rebooted — without losing the site or the
database. Data is only erased by `make clean`/`make fclean`, which remove the
volumes (and, for `fclean`, the host directories).
