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
            - caddy-server-service

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
            - nginx-server-service
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
            - file: install-lax
