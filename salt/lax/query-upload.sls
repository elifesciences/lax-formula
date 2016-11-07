daily-query-uploads:
    cron.present:
        - user: {{ pillar.elife.deploy_user.username }}
        - identifier: daily-query-uploads
        - special: '@daily'
        - name: cd /srv/lax && ./manage.sh query_export
        - require:
            - cmd: configure-lax
        
