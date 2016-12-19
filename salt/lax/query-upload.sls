daily-query-uploads:
    cron.present:
        - user: {{ pillar.elife.deploy_user.username }}
        - identifier: daily-query-uploads
        - name: cd /srv/lax && ./manage.sh query_export
        # occurs 1hr after ejp import
        - minute: 30
        - hour: 13
        - require:
            - cmd: configure-lax
