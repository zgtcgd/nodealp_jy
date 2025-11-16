FROM node:alpine

WORKDIR /app

ARG PORT=3000
ENV PORT=$PORT
EXPOSE $PORT

COPY package.json ./
RUN apk update && \
    apk add --no-cache bash wget curl procps && \
    npm install

COPY app.js start.sh ./
RUN chmod +x start.sh

ENTRYPOINT [ "node", "app.js" ]
