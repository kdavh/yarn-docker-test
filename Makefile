NAME := yarn-docker-test

# rebuild in case Dockerfile changes
build:
	touch yarn.lock

	# Init empty cache file
	if [ ! -f .yarn-cache.tgz ]; then \
		echo "Init empty .yarn-cache.tgz" ; \
		tar cvzf .yarn-cache.tgz --files-from /dev/null ; \
	fi

	docker build -t ${NAME} .

	docker run --rm --entrypoint cat ${NAME}:latest /tmp/yarn.lock > /tmp/yarn.lock
	if ! diff -q yarn.lock /tmp/yarn.lock > /dev/null  2>&1; then \
		echo "Saving Yarn cache" ; \
		docker run --rm --entrypoint touch ${NAME}:latest /root/.yarn-cache/ ; \
		docker run --rm --entrypoint tar ${NAME}:latest czf - /root/.yarn-cache/ > .yarn-cache.tgz ; \
		echo "Saving yarn.lock" ; \
		cp /tmp/yarn.lock yarn.lock ; \
	fi

	docker-compose --project-name ${NAME} build

run:
	docker-compose --project-name ${NAME} run -p 3000:3000 -p 3001:3001 --rm server npm start

test:
	docker-compose --project-name ${NAME} run -p 4000:3000 -p 4001:3001 --rm server npm test

sh:
	docker-compose --project-name ${NAME} run -p 5000:3000 -p 5001:3001 --rm server sh

clean:
	docker ps -a --format '{{.Image}} {{.ID}}' | grep "${NAME}_server\s" | awk '{print $2}' | xargs docker rm
	docker rmi "${NAME}_server"
