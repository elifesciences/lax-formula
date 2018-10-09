
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

    # alert! this will mess with the rev/branch specified in above git.latest
    # to affect the git rev, ensure it's pinned in lax's bot-lax-adaptor.sha1
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



#
# logging
#

bot-lax-adaptor-log-file-monitoring:
    file.managed:
        - name: /etc/syslog-ng/conf.d/bot-lax-adaptor.conf
        - source: salt://lax/config/etc-syslog-ng-conf.d-bot-lax-adaptor.conf
        - template: jinja

logrotate-for-bot-lax-adaptor-logs:
    file.managed:
        - name: /etc/logrotate.d/bot-lax-adaptor
        - source: salt://lax/config/etc-logrotate.d-bot-lax-adaptor

{% for path in ['/ext/uploads/', '/ext/cache/', '/var/log/bot-lax-adaptor/'] %}
dir-{{ path }}:
    file.directory:
        - name: {{ path }}
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.webserver.username }}
        # writeable by user+group, readable by all else
        - dir_mode: 774
        - file_mode: 664 # read+write for user and group, read for world
        - recurse:
            - user
            - group
            - mode
        - require_in:
            - cmd: bot-lax-writable-dirs

    cmd.run:
        - name: chmod -R g+s {{ path }}
        - require:
            - file: dir-{{ path }}
{% endfor %}

bot-lax-writable-dirs:
    cmd.run:
        - name: echo "dirs created"

#
#
#

move /opt/bot-lax/article-xml/ to /ext/article-xml:
    cmd.script:
        - cwd: /ext
        - source: salt://lax/scripts/mv-article-xml.sh

    file.managed:
        - name: /ext/mv-article-xml.sh
        - source: salt://lax/scripts/mv-article-xml.sh

#
# bot-lax web api
# 

bot-lax-nginx-conf:
    file.managed:
        - name: /etc/nginx/sites-enabled/bot-lax-adaptor.conf
        - template: jinja
        - source: salt://lax/config/etc-nginx-sitesenabled-bot-lax-adaptor.conf
        - require:
            - file: uwsgi-params
            - pkg: nginx-server
            - web-ssl-enabled
        - watch_in:
            - service: nginx-server-service

bot-lax-uwsgi-conf:
    file.managed:
        - name: /opt/bot-lax-adaptor/uwsgi.ini
        - source: salt://lax/config/opt-bot-lax-adaptor-uwsgi.ini
        - template: jinja
        - require:
            - bot-lax-adaptor-install
            - bot-lax-writable-dirs

{% set domainname = salt['elife.cfg']('cfn.outputs.DomainName') %}
{% set loadbalanced = salt['elife.cfg']('project.elb') %}

{% set apiprotocol = 'https' if domainname and not loadbalanced else 'http' %}
{% set apihost = salt['elife.cfg']('project.full_hostname', 'localhost') %}

bot-lax-uwsgi-upstart:
    file.managed:
        - name: /etc/init/uwsgi-bot-lax-adaptor.conf
        - source: salt://lax/config/etc-init-uwsgi-bot-lax-adaptor.conf
        - template: jinja
        - mode: 755

bot-lax-uwsgi-systemd:
    file.managed:
        - name: /lib/systemd/system/uwsgi-bot-lax-adaptor.service
        - source: salt://lax/config/lib-systemd-system-uwsgi-bot-lax-adaptor.service
        - template: jinja
        - mode: 644

{% set apiprotocol = 'https' if salt['elife.cfg']('cfn.outputs.DomainName') else 'http' %}
{% set apihost = salt['elife.cfg']('project.full_hostname', 'localhost') %}

uwsgi-bot-lax-adaptor:
    service.running:
        - enable: True
        # doesn't seem to be understood by uwsgi, leave the default behavior of restarting rather than reloading, only changes
        # - reload: True
        - require:
            - file: bot-lax-uwsgi-upstart
            - file: bot-lax-uwsgi-systemd
            - file: bot-lax-uwsgi-conf
            - file: bot-lax-nginx-conf
            - bot-lax-writable-dirs

        - watch:
            # will always trigger a restart since it's a `cmd` state
            - cmd: bot-lax-adaptor

# disabled. because of `listen` requisites in builder-base.nginx, I can't get this
# state to reliably run after the service is running without the service then
# being restarted 
#uwsgi-bot-lax-smoke-test:
#    http.wait_for_successful_query:
#        - name: {{ apiprotocol }}://{{ apihost }}:8001/ui/
#        - status: 200
#        - wait_for: 10 # seconds. five checks with 1 second between each
#        - request_interval: 1 # second
#        - require:
#            - uwsgi-bot-lax-adaptor

