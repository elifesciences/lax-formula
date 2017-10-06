install-lax:
    builder.git_latest:
        - name: git@github.com:elifesciences/lax.git
        - identity: {{ pillar.elife.projects_builder.key or '' }}
        - rev: {{ salt['elife.rev']() }}
        - branch: {{ salt['elife.branch']() }}
        - target: /srv/lax/
        - force_fetch: True
        - force_checkout: True
        - force_reset: True

    file.directory:
        - name: /srv/lax
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - recurse:
            - user
            - group
        - require:
            - builder: install-lax

cfg-file:
    file.managed:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: /srv/lax/app.cfg
        - source: 
            - salt://lax/config/srv-lax-{{ salt['elife.cfg']('project.branch') }}.cfg
            - salt://lax/config/srv-lax-app.cfg
        - template: jinja
        - replace: True
        - require:
            - install-lax

#
# logging
#

lax-log-file:
    file.managed:
        - name: /var/log/lax.log
        - user: {{ pillar.elife.webserver.username }}
        - group: {{ pillar.elife.webserver.username }}
        - mode: 660

lax-ingest-log-file:
    file.managed:
        - name: /var/log/ingestion-lax.log
        - user: {{ pillar.elife.webserver.username }}
        - group: {{ pillar.elife.webserver.username }}
        - mode: 660

lax-syslog-conf:
    file.managed:
        - name: /etc/syslog-ng/conf.d/lax.conf
        - source: salt://lax/config/etc-syslog-ng-conf.d-lax.conf
        - template: jinja
        - require:
            - pkg: syslog-ng
            - file: lax-log-file
        - watch_in:
            - service: syslog-ng

logrotate-for-lax-logs:
    file.managed:
        - name: /etc/logrotate.d/lax
        - source: salt://lax/config/etc-logrotate.d-lax

#
# 
# 

lax-ubr-db-backup:
    file.managed:
        - name: /etc/ubr/lax-backup.yaml
        - source: salt://lax/config/etc-ubr-lax-backup.yaml
        - template: jinja

configure-lax:
    cmd.run:
        - user: {{ pillar.elife.deploy_user.username }}
        - cwd: /srv/lax/
        - name: |
            ./install.sh 
            ./download-api-raml.sh
            ./manage.sh collectstatic --noinput
        - require:
            - install-lax
            - file: cfg-file
            - file: lax-log-file
            - file: lax-ingest-log-file


aws-credentials:
    file.managed:
        - name: /home/{{ pillar.elife.deploy_user.username }}/.aws/credentials
        - user: {{ pillar.elife.deploy_user.username }}
        - makedirs: True
        - source: salt://lax/config/home-deploy-user-.aws-credentials
        - template: jinja
        - require:
            - install-lax

aws-credentials-www-data-user:
    file.managed:
        - name: /var/www/.aws/credentials
        - user: {{ pillar.elife.webserver.username }}
        - makedirs: True
        - source: salt://lax/config/home-deploy-user-.aws-credentials
        - template: jinja


reset-script:
    file.managed:
        - name: /usr/local/bin/reset_script
        - source: salt://lax/config/usr-local-bin-reset_script
        - mode: 555

#{% if pillar.elife.env == 'end2end' and  salt['elife.rev']() == 'approved' %}
#restore-backup-from-production:
#    cmd.script:
#        - name: restore-lax-script
#        - source: salt://lax/scripts/restore-lax.sh
#        - template: jinja
#        # as late as possible
#        - require:
#            - cmd: configure-lax
#{% endif %}
