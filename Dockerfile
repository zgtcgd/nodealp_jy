FROM node:alpine

WORKDIR /app

ENV PORT=3000
EXPOSE $PORT

COPY package.json ./
RUN apk update && \
    apk add --no-cache bash wget curl procps && \
    npm install

COPY app.js start.sh ./
RUN chmod +x start.sh

ENTRYPOINT [ "node", "app.js" ]
