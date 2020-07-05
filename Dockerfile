FROM openresty/openresty:alpine

RUN apk update && apk add \
    gcc \
    git \
    libc-dev \
    openssl-dev \
    luarocks5.1 \
    lua5.1-dev
RUN luarocks-5.1 install lapis
RUN luarocks-5.1 install moonscript

WORKDIR /app
COPY . .
RUN moonc .
RUN lapis build production

EXPOSE 8080
CMD lapis server production