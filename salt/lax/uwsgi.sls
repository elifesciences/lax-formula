{% if pillar.elife.webserver.app == "caddy" %}
lax-caddy-conf:
    file.managed:
        - name: /etc/caddy/sites.d/lax
        - template: jinja
        - source: salt://lax/config/etc-caddy-sites.d-lax
        - require:
            - file: uwsgi-params
            - caddy-config
        - require_in:
            - cmd: caddy-validate-config
            - service: uwsgi-lax
        - watch_in:
            # restart caddy if caddy config changes
            - service: caddy-server-service
            # restart uwsgi if caddy config changes
            - service: uwsgi-lax

{% else %}
lax-nginx-conf:
    file.managed:
        - name: /etc/nginx/sites-enabled/lax.conf
        - template: jinja
        - source: salt://lax/config/etc-nginx-sitesavailable-lax.conf
        - require:
            - file: uwsgi-params
            - pkg: nginx-server
            - cmd: web-ssl-enabled
        - require_in:
            - service: uwsgi-lax
        - watch_in:
            # restart nginx if nginx config changes
            - service: nginx-server-service
            # restart uwsgi if nginx config changes
            - service: uwsgi-lax
{% endif %}

lax-uwsgi-conf:
    file.managed:
        - name: /srv/lax/uwsgi.ini
        - source: salt://lax/config/srv-lax-uwsgi.ini
        - template: jinja
        - require:
            - install-lax

uwsgi-lax.socket:
    service.running:
        - enable: True
        - require:
            - file: uwsgi-socket-lax # builder-base-formula.uwsgi
        - require_in:
            - service: uwsgi-lax

uwsgi-lax:
    service.running:
        - enable: True
        - require:
            - file: uwsgi-service-lax # builder-base-formula.uwsgi
            - file: lax-uwsgi-conf
            - file: lax-log-file
        - watch:
            # restart uwsgi if lax code changes
            - file: install-lax
            # restart uwsgi if lax config changes
            - cfg-file
            # restart uwsgi if uwsgi config changes
            - lax-uwsgi-conf
