newrelic-license-configuration:
    cmd.run:
        - name: venv/bin/newrelic-admin generate-config {{ pillar.elife.newrelic.license }} newrelic.ini
        - cwd: /srv/lax
        - user: {{ pillar.elife.deploy_user.username }}
        - require: 
            - configure-lax

newrelic-ini-configuration-appname:
    file.replace:
        - name: /srv/lax/newrelic.ini
        - pattern: '^app_name.*'
        - repl: app_name = {{ salt['elife.cfg']('project.stackname', 'cfn.stack_id', 'Python application') }}
        - require:
            - newrelic-license-configuration
        - listen_in:
            - service: uwsgi-lax

newrelic-ini-configuration-logfile:
    file.replace:
        - name: /srv/lax/newrelic.ini
        - pattern: '^#?log_file.*'
        - repl: log_file = /tmp/newrelic-python-agent.log
        - require:
            - newrelic-license-configuration
        - listen_in:
            - service: uwsgi-lax

