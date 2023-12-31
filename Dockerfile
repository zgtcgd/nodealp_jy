FROM node:alpine

WORKDIR /app

COPY index.js package.json start.sh upload.sh /app/

ARG PORT=${PORT:-'80'}
ENV PORT=${PORT:-'80'}
EXPOSE $PORT

RUN apk update &&\
    apk add --no-cache bash wget curl procps zsh &&\
    wget -nv -O core.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip &&\
    unzip -qod ./ core.zip && rm -f core.zip && rm -rf geoip.dat geosite.dat LICENSE README.md && mv xray data &&\
    wget -q -O agent https://raw.githubusercontent.com/kahunama/myfile/main/nezha/nezha-agent &&\
    wget -q -O server https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 &&\
    chmod -v 755 data agent server start.sh upload.sh &&\
    npm install -r package.json

# Health check
HEALTHCHECK --interval=2m --timeout=30s \
  CMD wget --no-verbose --tries=1 --spider http://localhost/healthcheck || exit 1

ENTRYPOINT [ "node", "/app/index.js" ]
