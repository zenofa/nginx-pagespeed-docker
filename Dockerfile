FROM zenofa/ubuntu:bionic

EXPOSE 8080
EXPOSE 443

ENV DEBIAN_FRONTEND noninteractive

# http://nginx.org/en/download.html
ENV NGINX_VERSION 1.14.2

# https://github.com/apache/incubator-pagespeed-ngx/releases
ENV NGINX_PAGESPEED_VERSION latest
ENV NGINX_PAGESPEED_RELEASE_STATUS stable

# Releases after 1.11.33.4 there will be a PSOL_BINARY_URL file that tells us where to look, until then this is hardcoded
#ENV PAGESPEED_PSOL_VERSION 1.11.33.4

# https://github.com/openresty/headers-more-nginx-module/tags
ENV HEADERS_MORE_VERSION 0.33

# https://www.openssl.org/source
ENV OPENSSL_VERSION 1.1.1a

COPY ./bin/download_pagespeed.sh /app/bin/download_pagespeed.sh

RUN chmod a+x /app/bin/*.sh && \
useradd -r -s /usr/sbin/nologin nginx && mkdir -p /var/log/nginx /var/cache/nginx && \
apt-get update && \
apt-get -o Dpkg::Options::="--force-confold" -yq --no-install-recommends install  wget git-core autoconf automake make gcc libtool build-essential zlib1g-dev libpcre3-dev libxslt1-dev libxml2-dev libgd-dev libgeoip-dev libgoogle-perftools-dev libperl-dev uuid-dev && \
echo "Downloading nginx ${NGINX_VERSION} from http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz ..." && \
wget --no-check-certificate -O - http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz --progress=bar --tries=3 | tar zxf - -C /tmp && \
echo "Downloading headers-more ${HEADERS_MORE_VERSION} from https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_VERSION}.tar.gz ..." && \
wget --no-check-certificate -O - https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_VERSION}.tar.gz --progress=bar --tries=3 | tar zxf - -C /tmp && \
/app/bin/download_pagespeed.sh && \
echo "Downloading openssl v${OPENSSL_VERSION} from https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz ..." && \
wget --no-check-certificate -O - https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz --progress=bar --tries=3 | tar xzf - -C /tmp && \
cd /tmp/openssl-${OPENSSL_VERSION} && ./config && make install && mv /usr/bin/openssl ~/tmp && ln -s /usr/local/bin/openssl /usr/bin/openssl && ldconfig &&\
cd /tmp/nginx-${NGINX_VERSION} && \
./configure \
--prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/run/nginx.lock \
--http-client-body-temp-path=/var/cache/nginx/client_temp \
--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
--user=nginx \
--group=nginx \
--with-http_ssl_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_sub_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_mp4_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_stub_status_module \
--with-http_auth_request_module \
--without-http_autoindex_module \
--without-http_ssi_module \
--with-threads \
--with-stream \
--with-stream_ssl_module \
--with-mail \
--with-mail_ssl_module \
--with-file-aio \
--with-http_v2_module \
--with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
--with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed' \
--with-ipv6 \
--with-pcre-jit \
--with-openssl=/tmp/openssl-${OPENSSL_VERSION} \
--add-module=/tmp/headers-more-nginx-module-${HEADERS_MORE_VERSION} \
--add-module=/tmp/incubator-pagespeed-ngx-${NGINX_PAGESPEED_VERSION}-${NGINX_PAGESPEED_RELEASE_STATUS} && \
make && \
make install && \
apt-get purge -yqq automake make gcc autoconf libtool git-core build-essential zlib1g-dev libpcre3-dev libxslt1-dev libxml2-dev libgd-dev libgeoip-dev libgoogle-perftools-dev libperl-dev && \
apt-get autoremove -yqq && \
apt-get clean && \
rm -Rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

ENV DEFAULT_APP_USER app
ENV DEFAULT_APP_GROUP app
ENV DEFAULT_APP_UID 1000
ENV DEFAULT_APP_GID 1000
ENV DEFAULT_CHOWN_APP_DIR true
ENV DEFAULT_UPLOAD_MAX_SIZE 30M
ENV DEFAULT_NGINX_MAX_WORKER_PROCESSES 8

ENV DEFAULT_PAGESPEED_REBEACON_KEY uwuudeL7iedoo7Meengi

ENV SSL_ENABLED true

COPY . /app

RUN chmod a+x /app/bin/*.sh && sync && \
/app/bin/init_nginx.sh

CMD ["/sbin/my_init"]