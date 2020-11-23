FROM alpine:3

LABEL maintainer="Ranielly Ferreira <eu@raniellyferreira.com.br>"

ENV NGINX_VERSION 1.16.1

RUN set -x \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk update --no-cache \
    && apk upgrade --no-cache

RUN set -x \
    && apk add --no-cache --virtual .build-deps \
    tzdata \
    patch \
    build-base \
    linux-headers \
    libressl-dev \
    pcre-dev \
    libc-dev \
    openssl-dev \
    zlib-dev \
    cmake \
    libaio-dev \
    cargo \
    bash \
    git

WORKDIR /tmp

RUN set -x \
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

ADD http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz /tmp

RUN set -x \
    && tar xvf nginx-${NGINX_VERSION}.tar.gz

RUN git clone --recursive https://github.com/cloudflare/quiche --depth 1

RUN set -x \
    && cd /tmp/nginx-${NGINX_VERSION}     \
    && patch -p01 < ../quiche/extras/nginx/nginx-1.16.patch \
    && ./configure                        \
    --user=nobody                         \
    --group=nobody                        \
    --prefix=/etc/nginx                   \
    --sbin-path=/usr/sbin/nginx           \
    --conf-path=/etc/nginx/nginx.conf     \
    --pid-path=/var/run/nginx.pid         \
    --lock-path=/var/run/nginx.lock       \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --with-http_gzip_static_module        \
    --with-http_stub_status_module        \
    --with-http_v2_module                 \
    --with-http_v3_module                 \
    --with-http_ssl_module                \
    --with-pcre                           \
    --with-file-aio                       \
    --with-http_realip_module             \
    --without-http_scgi_module            \
    --without-http_uwsgi_module           \
    --without-http_fastcgi_module ${NGINX_DEBUG:+--debug} \
    --with-cc-opt=-O2                     \
    --with-openssl=../quiche/deps/boringssl \
    --with-quiche=../quiche               \
    && make install

RUN set -x \
    && rm -rf /var/cache/apk/* /tmp/* \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

WORKDIR /etc/nginx

COPY nginx.conf ./

RUN nginx -t

EXPOSE 80
EXPOSE 443/tcp
EXPOSE 443/udp

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
