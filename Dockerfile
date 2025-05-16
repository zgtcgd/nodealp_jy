FROM node:alpine

WORKDIR /app

COPY server.js package.json /app/

ARG PORT=${PORT:-'3000'}
EXPOSE $PORT

RUN apk update && \
    apk add --no-cache bash wget curl procps && \
    npm install

ENTRYPOINT [ "node", "/app/server.js" ]
