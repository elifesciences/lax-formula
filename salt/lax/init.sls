install-lax:
    file.directory:
        - name: /srv/lax
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}

    git.latest:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: https://github.com/elifesciences/lax
        - rev: {{ salt['elife.cfg']('project.revision', 'project.branch', 'master') }}
        - branch: {{ salt['elife.branch']() }}
        - target: /srv/lax/
        - force_fetch: True
        - force_checkout: True
        - force_reset: True
        - require:
            - file: install-lax

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
            - git: install-lax

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

#
# db
#

lax-db-user:
    postgres_user.present:
        - name: {{ pillar.lax.db.username }}
        - encrypted: True
        - password: {{ pillar.lax.db.password }}
        - refresh_password: True
        
        - db_user: {{ pillar.elife.db_root.username }}
        - db_password: {{ pillar.elife.db_root.password }}
        {% if salt['elife.cfg']('cfn.outputs.RDSHost') %}
        - db_host: {{ salt['elife.cfg']('cfn.outputs.RDSHost') }}
        - db_port: {{ salt['elife.cfg']('cfn.outputs.RDSPort') }}
        {% endif %}
        - createdb: True

lax-db-exists:
    postgres_database.present:
        - name: {{ pillar.lax.db.name }}
        - owner: {{ pillar.lax.db.username }}

        {% if salt['elife.cfg']('cfn.outputs.RDSHost') %}
        # not sure if first two are necessary
        - db_user: {{ pillar.elife.db_root.username }}
        - db_password: {{ pillar.elife.db_root.password }}
        - db_host: {{ salt['elife.cfg']('cfn.outputs.RDSHost') }}
        - db_port: {{ salt['elife.cfg']('cfn.outputs.RDSPort') }}
        {% endif %}

        - require:
            - postgres_user: lax-db-user

#
# 
# 

configure-lax:
    cmd.run:
        - user: {{ pillar.elife.deploy_user.username }}
        - cwd: /srv/lax/
        - name: ./install.sh && ./manage.sh collectstatic --noinput
        - require:
            - git: install-lax
            - file: cfg-file
            - file: lax-log-file
            - file: lax-ingest-log-file
            - postgres_database: lax-db-exists

