lax-nginx-conf:
    file.managed:
        - name: /etc/nginx/sites-enabled/lax.conf
        - template: jinja
        - source: salt://lax/config/etc-nginx-sitesavailable-lax-https.conf
        - require:
            - pkg: nginx-server
{% if salt['elife.cfg']('cfn.outputs.DomainName') %}
            - cmd: web-ssl-enabled
{% endif %}

lax-uwsgi-conf:
    file.managed:
        - name: /srv/lax/uwsgi.ini
        - source: salt://lax/config/srv-lax-uwsgi.ini
        - template: jinja
        - require:
            - install-lax

uwsgi-lax:
    file.managed:
        - name: /etc/init.d/uwsgi-lax
        - source: salt://lax/config/etc-init.d-uwsgi-lax
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
            - install-lax
            # restart uwsgi if nginx service changes
            - service: nginx-server-service
