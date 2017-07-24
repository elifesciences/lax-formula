lax-nginx-conf:
    file.managed:
        - name: /etc/nginx/sites-enabled/lax.conf
        - template: jinja
        - source: salt://lax/config/etc-nginx-sitesavailable-lax.conf
        - require:
            - pkg: nginx-server
            - cmd: web-ssl-enabled

# we used to redirect all traffic to https but don't anymore
# now we simply block all external traffic on port 80
lax-unencrypted-redirect:
    file.absent:
        - name: /etc/nginx/sites-enabled/unencrypted-redirect.conf

lax-uwsgi-conf:
    file.managed:
        - name: /srv/lax/uwsgi.ini
        - source: salt://lax/config/srv-lax-uwsgi.ini
        - template: jinja
        - require:
            - install-lax

uwsgi-lax:
    file.managed:
        - name: /etc/init/uwsgi-lax.conf
        - source: salt://lax/config/etc-init-uwsgi-lax.conf
        - template: jinja
        - mode: 755

    service.running:
        - enable: True
        - reload: True
        - require:
            - file: uwsgi-params
            - pip: uwsgi-pkg
            - file: uwsgi-lax
            - file: lax-uwsgi-conf
            - file: lax-nginx-conf
            - file: lax-log-file
        - watch:
            - install-lax
            # restart uwsgi if nginx service changes
            - service: nginx-server-service
