FROM node:alpine

WORKDIR /app

COPY index.js package.json start.sh upload.sh /app/

EXPOSE 3000

ARG FLIE_PATH=${FLIE_PATH:-'/tmp/'}
ENV FLIE_PATH=${FLIE_PATH:-'/tmp/'}

RUN apk update &&\
    apk add --no-cache bash wget curl procps &&\
    wget -nv -O core.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip &&\
    unzip -qod ./ core.zip && rm -f core.zip && rm -rf geoip.dat geosite.dat LICENSE README.md && mv xray ${FLIE_PATH}web &&\
    wget -q -O ${FLIE_PATH}nezha-agent https://raw.githubusercontent.com/kahunama/myfile/main/nezha/nezha-agent && \
    wget -q -O ${FLIE_PATH}argo https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 &&\
    chmod -v 755 ${FLIE_PATH}web ${FLIE_PATH}nezha-agent ${FLIE_PATH}argo start.sh upload.sh &&\
    npm install -r package.json

# Health check
HEALTHCHECK --interval=5s --timeout=3s  --retries=3 \
    CMD curl -fs https://localhost/healthcheck || exit 1

ENTRYPOINT [ "node", "index.js" ]
