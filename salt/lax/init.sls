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
# db
#

lax-db-user:
    postgres_user.present:
        - name: {{ pillar.lax.db.username }}
        - encrypted: True
        - password: {{ pillar.lax.db.password }}
        - refresh_password: True

        {% if salt['elife.cfg']('cfn.outputs.RDSHost') %}
        # remote psql
        - db_user: {{ salt['elife.cfg']('project.rds_username') }}        
        - db_password: {{ salt['elife.cfg']('project.rds_password') }}
        - db_host: {{ salt['elife.cfg']('cfn.outputs.RDSHost') }}
        - db_port: {{ salt['elife.cfg']('cfn.outputs.RDSPort') }}
        {% else %}
        - db_user: {{ pillar.elife.db_root.username }}
        - db_password: {{ pillar.elife.db_root.password }}
        {% endif %}
        - createdb: True

lax-db-exists:
    postgres_database.present:
        {% if salt['elife.cfg']('cfn.outputs.RDSHost') %}    
        # remote psql
        - name: {{ salt['elife.cfg']('project.rds_dbname') }}
        - db_host: {{ salt['elife.cfg']('cfn.outputs.RDSHost') }}
        - db_port: {{ salt['elife.cfg']('cfn.outputs.RDSPort') }}
        {% else %}
        # local psql
        - name: {{ pillar.lax.db.name }}
        {% endif %}
        - owner: {{ pillar.lax.db.username }}
        - db_user: {{ pillar.lax.db.username }}
        - db_password: {{ pillar.lax.db.password }}
        - require:
            - postgres_user: lax-db-user

#
# 
# 

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
            - postgres_database: lax-db-exists


aws-credentials:
    file.managed:
        - name: /home/{{ pillar.elife.deploy_user.username }}/.aws/credentials
        - user: {{ pillar.elife.deploy_user.username }}
        - makedirs: True
        - source: salt://lax/config/home-deploy-user-.aws-credentials
        - template: jinja
        - require:
            - install-lax

reset-script:
    file.managed:
        - name: /usr/local/bin/reset_script
        - source: salt://lax/config/usr-local-bin-reset_script
        - mode: 555

{% if pillar.elife.env == 'end2end': %}
reset-script-cron:
    cron.present:
        - name: /usr/local/bin/reset_script
        - identifier: daily-reset
        - hour: 5
        - minute: 0
        - require:
            - reset-script
{% endif %}
