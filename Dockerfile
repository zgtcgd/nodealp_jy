FROM node:alpine

WORKDIR /app

COPY index.js package.json start.sh /app/

ARG PORT=${PORT:-'3000'}
EXPOSE $PORT

RUN apk update && \
    apk add --no-cache bash wget curl procps zsh && \
    chmod -v 755 start.sh && \
    npm install

HEALTHCHECK --interval=2m --timeout=30s CMD curl --fail http://localhost/healthcheck || exit 1

ENTRYPOINT [ "node", "/app/index.js" ]
