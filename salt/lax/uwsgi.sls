lax-nginx-conf:
    file.managed:
        - name: /etc/nginx/sites-enabled/lax.conf
        - template: jinja
{% if pillar.elife.env == 'dev' %}
        - source: salt://elife-lax/config/etc-nginx-sitesavailable-lax-http.conf
{% else %}
        - source: salt://elife-lax/config/etc-nginx-sitesavailable-lax-https.conf
        - require:
            - cmd: acme-fetch-certs
{% endif %}

lax-uwsgi-conf:
    file.managed:
        - name: /srv/lax/uwsgi.ini
        - source: salt://elife-lax/config/srv-lax-uwsgi.ini
        - template: jinja
        - require:
            - git: install-lax

uwsgi-lax:
    file.managed:
        - name: /etc/init.d/uwsgi-lax
        - source: salt://elife-lax/config/etc-init.d-uwsgi-lax
        - mode: 755

    service.running:
        - enable: True
        - require:
            - file: uwsgi-params
            - pip: uwsgi-pkg
            - file: uwsgi-lax
            - file: lax-uwsgi-conf
            - file: lax-nginx-conf
            - file: lax-log-file
        - watch:
            - git: install-lax
            # restart uwsgi if nginx service changes
            - service: nginx-server-service
