FROM jwilder/nginx-proxy:0.8.0 as nginx-proxy
FROM owasp/modsecurity:3.0.4 as modsecurity
LABEL maintainer="Eyal Benatav <eyalb81@gmail.com>"

# copy stuff from nginx-proxy
COPY --from=nginx-proxy /etc/nginx/ /etc/nginx/
COPY --from=nginx-proxy /usr/local/bin/forego /usr/local/bin/forego
COPY --from=nginx-proxy /usr/local/bin/docker-gen /usr/local/bin/docker-gen
COPY --from=nginx-proxy /app/ /app/

# env vars
ENV DOCKER_HOST unix:///tmp/docker.sock
ENV RULES_PATH /etc/modsecurity.d/rules
ENV RULES_FILE ${RULES_PATH}/rules.conf

RUN rm -rf /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/logging.conf \
    # replace bash env and exec command
    && sed -i -e 's:#!/bin/bash -e::g' -e 's:etc/:/etc/:g' /docker-entrypoint.sh \
    && sed -i 's:exec "$@":\n:g' /app/docker-entrypoint.sh \
    # concatinate both entry pointers
    && cat /docker-entrypoint.sh >> /app/docker-entrypoint.sh \
    # create rules dir and file
    && mkdir -p ${RULES_PATH} && touch ${RULES_FILE} \
    # add rules file to setup.conf
    && echo "Include ${RULES_FILE}" >> /etc/modsecurity.d/setup.conf \
    # add nginx modsecurity module
    && sed -i '1s;^;load_module modules/ngx_http_modsecurity_module.so\;\n;' /etc/nginx/nginx.conf \
    # do some cleanup
    && rm -rf /nginx-1.17.9 /nginx-1.17.9.tar.gz /ModSecurity-nginx /var/lib/apt/lists/*

# add volumes
VOLUME ["/etc/nginx/certs", "/etc/nginx/dhparam"]

# let's go to work
WORKDIR /app/
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]