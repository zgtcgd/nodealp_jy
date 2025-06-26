FROM node:alpine

WORKDIR /app

COPY package.json ./
RUN apk update && \
    apk add --no-cache bash wget curl procps && \
    npm install

COPY app.js start.sh ./
RUN chmod +x start.sh

EXPOSE 3000

ENTRYPOINT [ "node", "app.js" ]
