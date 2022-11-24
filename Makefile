APP_NAME = hunger

VERSION=v0.1.4
build:
	docker build --platform linux/amd64 -t hieuphq/${APP_NAME}:${VERSION}-amd64 .

push: build
	docker push hieuphq/${APP_NAME}:${VERSION}-amd64

docker-run:
	docker run -d -p 4000:4000 -e DATABASE_URL=ecto -e SECRET_KEY_BASE="PumZRuDEDPL3UA1fn5aXH+lCDYVqJkobJwI+1SOKXZfDO5a4XWtRxeqFjaDd46ip" hieuphq/${APP_NAME}:${VERSION}-amd64