# Use the official Alpine image as the base image
FROM alpine:latest

# Install dependencies
RUN apk update && apk add --no-cache \
    nginx \
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
    openssl-dev \
    bash \
    gettext

# Clone ModSecurity v3 repository with submodules
RUN git clone --recursive --depth 1 -b v3.0.4 https://github.com/SpiderLabs/ModSecurity /usr/local/src/ModSecurity &&
    cd /usr/local/src/ModSecurity &&
    ./build.sh &&
    ./configure &&
    make &&
    make install

# Clone the ModSecurity-nginx connector repository
RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git /usr/local/src/ModSecurity-nginx

# Get the installed Nginx version
RUN nginx_version=$(nginx -v 2>&1 | awk -F/ '{print $2}') &&
    echo "Nginx version: $nginx_version" &&
    cd /tmp &&
    curl -O http://nginx.org/download/nginx-$nginx_version.tar.gz &&
    tar zxvf nginx-$nginx_version.tar.gz &&
    cd nginx-$nginx_version &&
    ./configure --with-compat --add-dynamic-module=/usr/local/src/ModSecurity-nginx &&
    make modules &&
    mkdir -p /etc/nginx/modules &&
    cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules

# Clean up
RUN apk del gcc g++ make libtool automake autoconf &&
    rm -rf /var/cache/apk/* &&
    rm -rf /usr/local/src/ModSecurity &&
    rm -rf /usr/local/src/ModSecurity-nginx &&
    rm -rf /tmp/nginx-$nginx_version &&
    rm /tmp/nginx-$nginx_version.tar.gz

# Copy Nginx configuration template
COPY nginx/nginx.conf.template /etc/nginx/templates/nginx.conf.template

# Add ModSecurity configuration files
COPY modsecurity/modsecurity.conf /etc/nginx/modsecurity/modsecurity.conf
COPY modsecurity/crs-setup.conf /etc/nginx/modsecurity/crs-setup.conf
COPY modsecurity/rules /etc/nginx/modsecurity/rules

# Create directories
RUN mkdir -p /var/www/html /var/www/certbot

# Expose ports
EXPOSE 80
EXPOSE 443

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
