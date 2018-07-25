
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

# temporary. remove once feat-VALIDATE is fully deployed
move-requests-cache-file:
    cmd.run:
        - name: |
            set -e
            mkdir -p /ext/cache
            if [ -e /ext/requests-cache.sqlite3 ]; then
                mv /ext/requests-cache.sqlite3 /ext/cache/requests-cache.sqlite3
            else
                echo "no request-cache file to move :)"
            fi

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
        - require:
            - move-requests-cache-file
        - require_in:
            - cmd: bot-lax-writable-dirs

    cmd.run:
        - name: chmod -R g+s {{ path }}
        - require:
            - file: dir-{{ path }}
{% endfor %}

# added 2017-08-01 - temporary state, remove in due course
old-log-files:
    cmd.run:
        - name: rm -f *.log
        - cwd: /opt/bot-lax-adaptor
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - bot-lax-adaptor 

bot-lax-writable-dirs:
    cmd.run:
        - name: echo "dirs created"

#
# bot-lax web api
# 

bot-lax-nginx-conf:
    file.managed:
        - name: /etc/nginx/sites-enabled/bot-lax-adaptor.conf
        - template: jinja
        - source: salt://lax/config/etc-nginx-sitesenabled-bot-lax-adaptor.conf
        - require:
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

uwsgi-bot-lax-adaptor:
    file.managed:
        - name: /etc/init/uwsgi-bot-lax-adaptor.conf
        - source: salt://lax/config/etc-init-uwsgi-bot-lax-adaptor.conf
        - template: jinja
        - mode: 755

    service.running:
        - enable: True
        # doesn't seem to be understood by uwsgi, so we restart manually with a cmd.run state
        # - reload: True
        - require:
            - file: uwsgi-params
            - file: uwsgi-bot-lax-adaptor
            - file: bot-lax-uwsgi-conf
            - file: bot-lax-nginx-conf
            - bot-lax-writable-dirs

    cmd.run:
        # we need to restart to load new Python code just deployed
        - name: restart uwsgi-bot-lax-adaptor
        - require:
            - service: uwsgi-bot-lax-adaptor

uwsgi-bot-lax-smoke-test:
    http.wait_for_successful_query:
        - name: {{ apiprotocol }}://{{ apihost }}:8001/ui/
        - status: 200
        - wait_for: 10 # seconds. five checks with 1 second between each
        - request_interval: 1 # second
        - require:
            - uwsgi-bot-lax-adaptor

