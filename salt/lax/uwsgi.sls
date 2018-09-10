lax-nginx-conf:
    file.managed:
        - name: /etc/nginx/sites-enabled/lax.conf
        - template: jinja
        - source: salt://lax/config/etc-nginx-sitesavailable-lax.conf
        - require:
            - file: uwsgi-params
            - pkg: nginx-server
            - cmd: web-ssl-enabled

lax-uwsgi-conf:
    file.managed:
        - name: /srv/lax/uwsgi.ini
        - source: salt://lax/config/srv-lax-uwsgi.ini
        - template: jinja
        - require:
            - install-lax

lax-upstart-conf:
    file.managed:
        - name: /etc/init/uwsgi-lax.conf
        - source: salt://lax/config/etc-init-uwsgi-lax.conf
        - template: jinja
        - mode: 755

lax-systemd-conf:
    file.managed:
        - name: /lib/systemd/system/uwsgi-lax.service
        - source: salt://lax/config/lib-systemd-system-uwsgi-lax.service
        - template: jinja
        - mode: 644

uwsgi-lax:
    service.running:
        - enable: True
        #- reload: True # uwsgi+systemd problems
        - require:
            - file: lax-upstart-conf
            - file: lax-systemd-conf
            - file: lax-uwsgi-conf
            - file: lax-nginx-conf
            - file: lax-log-file
        - watch:
            - install-lax
            # restart uwsgi if nginx service changes
            - service: nginx-server-service
