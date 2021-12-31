# ModSecurity NGINX Proxy

`modsecurity-nginx-proxy` allows running multiple hostnames backed by ModSecurity.

The image is a mix up of [owasp/modsecurity](https://hub.docker.com/r/owasp/modsecurity)
and [jwilder/nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy).


### Example using docker-compose:
```yaml
version: '3.9'

services:
  proxy:
    build:
      dockerfile: Dockerfile
      context: .
    image: eben0/modsecurity-nginx-proxy
    ports:
      - 80:80
      - 443:443
    container_name: proxy
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - ./modsecurity.d/rules:/etc/modsecurity.d/proxy-rules:ro
      - nginx-certs:/etc/nginx/certs
      - nginx-vhost:/etc/nginx/vhost.d
      - nginx-html:/usr/share/nginx/html
    environment:
      MODSEC_DEBUG_LOGLEVEL: 5
    networks:
      service_network:

  web:
    image: nginx
    container_name: web
    environment:
      VIRTUAL_PORT: 8080
      VIRTUAL_HOST: web.example.com
    networks:
      service_network:

networks:
  service_network:

volumes:
  nginx-certs:
  nginx-vhost:
  nginx-html:
```

### Engine Core Rules Set
The image does not include engine rules. you can grab the rules from the official CRS repo:
```
https://github.com/coreruleset/coreruleset/tree/v3.4/dev/rules
```

To include rules you should create  `rules.conf` file within `rules` directory:
```apacheconf
Include REQUEST-901-INITIALIZATION.conf
# ...
```
Mount the folder:
```yaml
volumes:
  - ./rules:/etc/modsecurity.d/proxy-rules
```
