
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
        - name: ./install.sh
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - git: bot-lax-adaptor
            - pkg: bot-lax-adaptor

bot-lax-adaptor-service:
    file.managed:
        - name: /etc/init/bot-lax-adaptor.conf
        - source: salt://lax/config/etc-init-bot-lax-adaptor.conf
        - template: jinja
        - require:
            - bot-lax-adaptor
            
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
