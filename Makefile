COMPOSE_FILE = srcs/docker-compose.yml

all:
	@mkdir -p /home/thevaris/data/db
	@mkdir -p /home/thevaris/data/wordpress
	docker compose -f $(COMPOSE_FILE) up -d --build

down:
	docker compose -f $(COMPOSE_FILE) down

stop:
	docker compose -f $(COMPOSE_FILE) stop

start:
	docker compose -f $(COMPOSE_FILE) start

clean:
	docker compose -f $(COMPOSE_FILE) down -v

fclean: clean
	docker system prune -af
	rm -rf /home/thevaris/data/db
	rm -rf /home/thevaris/data/wordpress

re: fclean all

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

ps:
	docker compose -f $(COMPOSE_FILE) ps

.PHONY: all down stop start clean fclean re logs ps
