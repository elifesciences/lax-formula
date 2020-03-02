lax-nginx-conf:
    file.managed:
        - name: /etc/nginx/sites-enabled/lax.conf
        - template: jinja
        - source: salt://lax/config/etc-nginx-sitesavailable-lax.conf
        - require:
            - file: uwsgi-params
            - pkg: nginx-server
            - cmd: web-ssl-enabled
        - watch_in:
            - nginx-server-service

lax-uwsgi-conf:
    file.managed:
        - name: /srv/lax/uwsgi.ini
        - source: salt://lax/config/srv-lax-uwsgi.ini
        - template: jinja
        - require:
            - install-lax

# todo: remove
lax-upstart-conf:
    file.absent:
        - name: /etc/init/uwsgi-lax.conf

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
            - file: lax-nginx-conf
            - file: lax-log-file
        - watch:
            - file: install-lax
