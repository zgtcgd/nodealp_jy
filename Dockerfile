FROM node:alpine

WORKDIR /app

COPY index.js package.json start.sh /app/

ARG PORT=${PORT:-'3000'}
EXPOSE $PORT

RUN apk update && \
    apk add --no-cache bash wget curl procps && \
    chmod -v 755 start.sh && \
    npm install

ENTRYPOINT [ "node", "/app/index.js" ]
