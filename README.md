*This project has been created as part of the 42 curriculum by thevaris.*

# Inception

## Description

Inception is a system administration project whose goal is to build a small
infrastructure of services using **Docker Compose**, inside a virtual machine.
Every image is built by hand from a plain `debian:bookworm` base (the
penultimate stable version of Debian) — pulling ready-made service images from
DockerHub is forbidden.

The stack is composed of three containers, each one running a single service:

| Service   | Role                                                                 |
|-----------|----------------------------------------------------------------------|
| NGINX     | Sole entrypoint of the infrastructure, HTTPS only (TLSv1.2/TLSv1.3) on port 443 |
| WordPress | The website, served by php-fpm (no web server inside the container)  |
| MariaDB   | The database used by WordPress                                       |

Two named volumes persist the data under `/home/thevaris/data` on the host
(one for the database, one for the WordPress files), and a dedicated bridge
network (`inception`) connects the containers. The site is reachable at
`https://thevaris.42.fr`.

## Instructions

Prerequisites: a Linux virtual machine with Docker Engine and the Docker
Compose plugin installed, and the domain configured locally:

```bash
echo "127.0.0.1 thevaris.42.fr" | sudo tee -a /etc/hosts
```

The `secrets/` directory is not versioned. Before building, create it at the
root of the repository:

```
secrets/db_root_password.txt   # MariaDB root password
secrets/db_password.txt        # MariaDB wordpress-user password
secrets/credentials.txt        # WP_ADMIN_PASSWORD=... and WP_USER_PASSWORD=... (one per line)
```

Then build and start everything:

```bash
make        # builds the images and starts the stack in the background
make logs   # follow the containers' logs
make down   # stop and remove the containers
make clean  # also remove the volumes
make fclean # full cleanup (images, volumes, data directories)
make re     # fclean + rebuild everything
```

Open `https://thevaris.42.fr` in a browser (accept the self-signed
certificate warning).

## Project description and design choices

### Docker in this project

Each service has its own Dockerfile under `srcs/requirements/<service>/`.
The Dockerfiles start from `debian:bookworm`, install the service with `apt`,
copy a configuration file and a small entrypoint script, and run the daemon in
the **foreground** as PID 1 (`nginx -g "daemon off;"`, `php-fpm8.2 -F`,
`mysqld`). No `tail -f`/`sleep infinity` hacks are used: when the daemon dies,
the container dies, and `restart: always` brings it back up.

Non-sensitive configuration (domain, database name, user names) lives in
`srcs/.env`; passwords live in **Docker secrets** mounted at `/run/secrets/`
and are never written in a Dockerfile nor committed to git.

### Virtual Machines vs Docker

A VM virtualizes an entire machine — hardware, kernel, OS — through a
hypervisor, which gives strong isolation at the cost of gigabytes of disk and
minutes of boot time. A container is just an isolated group of processes
sharing the host kernel (namespaces + cgroups): it starts in seconds, weighs
megabytes, and packages exactly one service. That is why this project runs
one process per container, while the whole stack itself sits inside a VM for
an extra isolation layer.

### Secrets vs Environment Variables

Environment variables are visible to every process of the container and leak
easily (`docker inspect`, logs, child processes). Docker secrets are mounted
as read-only files in `/run/secrets/` and only in the containers that
explicitly request them. Here, environment variables hold non-sensitive
settings (domain name, database name, usernames) and secrets hold every
password.

### Docker Network vs Host Network

With `network_mode: host` the container shares the host network stack: no
isolation, every port directly exposed — it is forbidden in this project. A
user-defined bridge network (`inception`) gives the containers their own
isolated network with built-in DNS: containers reach each other by service
name (`mariadb`, `wordpress`) and only NGINX publishes a port (443) to the
outside.

### Docker Volumes vs Bind Mounts

A bind mount maps an arbitrary host path into a container; it depends entirely
on the host layout and is managed by nobody. A named volume is created and
managed by Docker (`docker volume ls/inspect`), can be listed, inspected and
removed through the Docker API, and survives container removal. The subject
requires named volumes; here they are declared with the `local` driver and
options that anchor their data in `/home/thevaris/data/`, so persistence is
easy to verify on the host.

## Resources

- Docker documentation — https://docs.docker.com/
- Dockerfile best practices — https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Docker Compose specification — https://docs.docker.com/compose/compose-file/
- Docker secrets in Compose — https://docs.docker.com/compose/use-secrets/
- NGINX docs — https://nginx.org/en/docs/
- WP-CLI handbook — https://make.wordpress.org/cli/handbook/
- MariaDB knowledge base — https://mariadb.com/kb/en/
- PID 1 and the zombie reaping problem — https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/

### How AI was used

AI (Claude) was used as a reviewing and documentation assistant: checking the
Dockerfiles, compose file and entrypoint scripts against the subject's
constraints (base image version, forbidden patterns, secrets handling),
suggesting fixes (base image upgrade to Bookworm, database wait loop, image
naming), and drafting this documentation. All the configuration and scripts
were written and are understood by the author; AI output was reviewed, tested
and adapted before being committed.
