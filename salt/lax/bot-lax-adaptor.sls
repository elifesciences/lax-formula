
# library for parsing the ejp report into article stubs for lax

bot-lax-adaptor:
    pkg.installed:
        - pkgs:
            - libxml2-dev 
            - libxslt-dev
            - lzma-dev # provides 'lz' for compiling lxml
        - require:
            - pkg: python-dev

    file.directory:
        - name: /opt/bot-lax-adaptor/
        - user: {{ pillar.elife.deploy_user.username }}

    git.latest:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: https://github.com/elifesciences/bot-lax-adaptor
        - rev: master
        - branch: master
        - target: /opt/bot-lax-adaptor/
        - force_fetch: True
        - force_checkout: True
        - force_reset: True
        - require:
            - file: bot-lax-adaptor

    cmd.run:
        - cwd: /opt/bot-lax-adaptor
        - name: ./pin.sh /srv/lax/bot-lax-adaptor.sha1
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - pkg: bot-lax-adaptor
            - file: bot-lax-adaptor
            - git: bot-lax-adaptor

bot-lax-adaptor-config:
    file.managed:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: /opt/bot-lax-adaptor/app.cfg
        - source: salt://lax/config/opt-bot-lax-adaptor-app.cfg
        - template: jinja
        - require:
            - bot-lax-adaptor

bot-lax-adaptor-install:
    cmd.run:
        - cwd: /opt/bot-lax-adaptor
        - name: ./install.sh
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - bot-lax-adaptor
            - bot-lax-adaptor-config

bot-lax-adaptor-service:
    file.managed:
        - name: /etc/init/bot-lax-adaptor.conf
        - source: salt://lax/config/etc-init-bot-lax-adaptor.conf
        - template: jinja
        - require:
            - bot-lax-adaptor-install
            
    #service.running # see `processes.sls` for how it is run and `/var/log/upstart/bot-lax-adaptor-{proc}.log` for errors


#
# logging
#

bot-lax-adaptor-log-file-monitoring:
    file.managed:
        - name: /etc/syslog-ng/conf.d/bot-lax-adaptor.conf
        - source: salt://lax/config/etc-syslog-ng-conf.d-bot-lax-adaptor.conf
        - template: jinja
        - require: 
            - bot-lax-adaptor-service

logrotate-for-bot-lax-adaptor-logs:
    file.managed:
        - name: /etc/logrotate.d/bot-lax-adaptor
        - source: salt://lax/config/etc-logrotate.d-bot-lax-adaptor

{% for fname in ['test.log', 'scrape.log', 'validate.log'] %}
{{ fname }}:
    file.managed:
        - name: /opt/bot-lax-adaptor/{{ fname }}
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.webserver.username }}
        # writeable by user+group, readable by all else
        - mode: 664
        - require_in:
            - bot-lax-log-files
{% endfor %}

bot-lax-log-files:
    cmd.run:
        - name: echo "logs done"


#
# bot-lax web api
# 

bot-lax-nginx-conf:
    file.managed:
        - name: /etc/nginx/sites-enabled/bot-lax.conf
        - template: jinja
        - source: salt://lax/config/etc-nginx-sitesenabled-bot-lax.conf
        - require:
            - pkg: nginx-server
            - web-ssl-enabled

bot-lax-uwsgi-conf:
    file.managed:
        - name: /opt/bot-lax-adaptor/uwsgi.ini
        - source: salt://lax/config/opt-bot-lax-adaptor-uwsgi.ini
        - template: jinja
        - require:
            - bot-lax-adaptor-install

uwsgi-bot-lax-adaptor:
    file.managed:
        - name: /etc/init/uwsgi-bot-lax-adaptor.conf
        - source: salt://lax/config/etc-init-uwsgi-bot-lax-adaptor.conf
        - template: jinja
        - mode: 755

    service.running:
        - enable: True
        - reload: True
        - require:
            - file: uwsgi-params
            - file: uwsgi-bot-lax-adaptor
            - file: bot-lax-uwsgi-conf
            - file: bot-lax-nginx-conf
            - bot-lax-log-files
        - watch:
            - bot-lax-adaptor
            # restart uwsgi if nginx service changes
            - service: nginx-server-service
