FROM node:12-alpine as builder

RUN apk add --no-cache git python make openssl tar gcc

COPY yapi.tar.gz /home

RUN cd /home && tar zxvf yapi.tar.gz && mkdir /api && mv /home/yapi-1.8.9 /api/vendors

RUN cd /api/vendors && \
    npm install --production --registry https://registry.npm.taobao.org



FROM node:12-alpine

MAINTAINER 1546382022@qq.com

ENV TZ="Asia/Shanghai" HOME="/"

WORKDIR ${HOME}

COPY --from=builder /api/vendors /api/vendors

COPY config.json /api/

EXPOSE 3000

COPY docker-entrypoint.sh /api/

RUN chmod 755 /api/docker-entrypoint.sh

ENTRYPOINT ["/api/docker-entrypoint.sh"]