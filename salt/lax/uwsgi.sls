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

lax-upstart-conf:
    file.managed:
        - name: /etc/init/uwsgi-lax.conf
        - source: salt://lax/config/etc-init-uwsgi-lax.conf
        - template: jinja
        - mode: 755

{% if salt['grains.get']('osrelease') != "14.04" %}
uwsgi-lax.socket:
    service.running:
        - enable: True
        - require_in:
            - uwsgi-lax
{% endif %}

uwsgi-lax:
    service.running:
        - enable: True
        - require:
            - file: lax-upstart-conf
            - file: lax-uwsgi-conf
            - file: lax-nginx-conf
            - file: lax-log-file
        - watch:
            - file: install-lax
