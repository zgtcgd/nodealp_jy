FROM node:alpine

WORKDIR /app

COPY index.js package.json start.sh up.sh /app/

ARG PORT=${PORT:-'3000'}
ENV PORT=${PORT:-'3000'}
EXPOSE $PORT

RUN apk update &&\
    apk add --no-cache bash wget curl procps zsh &&\
    wget -nv -O core.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip &&\
    unzip -qod ./ core.zip && rm -f core.zip && rm -rf geoip.dat geosite.dat LICENSE README.md && mv xray /tmp/data &&\
    wget -q -O /tmp/agent https://raw.githubusercontent.com/kahunama/myfile/main/nezha/nezha-agent &&\
    wget -q -O /tmp/server https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 &&\
    mv up.sh /tmp && chmod -v 755 /tmp/data /tmp/agent /tmp/server start.sh /tmp/up.sh &&\
    npm install -r package.json

# Health check
HEALTHCHECK --interval=2m --timeout=30s \
  CMD wget --no-verbose --tries=1 --spider http://localhost/healthcheck || exit 1

ENTRYPOINT [ "node", "/app/index.js" ]
