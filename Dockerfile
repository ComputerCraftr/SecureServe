# Use the official Alpine image as the base image
FROM alpine:latest

# Install dependencies
RUN apk update && apk add --no-cache \
    nginx \
    nginx-mod-http-modsecurity \
    libmodsecurity \
    git \
    gcc \
    g++ \
    make \
    libtool \
    automake \
    autoconf \
    curl \
    yajl-dev \
    lmdb-dev \
    geoip-dev \
    libmaxminddb-dev \
    libxml2-dev \
    pcre-dev \
    zlib-dev \
    linux-headers \
    libstdc++ \
    curl-dev \
    openssl \
    openssl-dev

# Clone ModSecurity v3 repository
RUN git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity /usr/local/src/ModSecurity \
    && cd /usr/local/src/ModSecurity \
    && git submodule init \
    && git submodule update \
    && ./build.sh \
    && ./configure \
    && make \
    && make install

# Clone the ModSecurity-nginx connector repository
RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git /usr/local/src/ModSecurity-nginx

# Build nginx with ModSecurity support
RUN cd /tmp \
    && curl -O http://nginx.org/download/nginx-1.19.6.tar.gz \
    && tar zxvf nginx-1.19.6.tar.gz \
    && cd nginx-1.19.6 \
    && ./configure --with-compat --add-dynamic-module=/usr/local/src/ModSecurity-nginx \
    && make modules \
    && cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules

# Clean up
RUN apk del gcc g++ make libtool automake autoconf \
    && rm -rf /var/cache/apk/* \
    && rm -rf /usr/local/src/ModSecurity \
    && rm -rf /usr/local/src/ModSecurity-nginx \
    && rm -rf /tmp/nginx-1.19.6 \
    && rm /tmp/nginx-1.19.6.tar.gz

# Configure Nginx
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Add ModSecurity configuration files
COPY modsecurity/modsecurity.conf /etc/nginx/modsecurity/modsecurity.conf
COPY modsecurity/crs-setup.conf /etc/nginx/modsecurity/crs-setup.conf
COPY modsecurity/rules /etc/nginx/modsecurity/rules

# Create directories
RUN mkdir -p /var/www/html

# Expose ports
EXPOSE 80
EXPOSE 443

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
