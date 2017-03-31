daily-query-uploads:
    # don't upload query results outside of prod
    {% if pillar.elife.env == 'prod' %}
    cron.present:
    {% else %}
    cron.absent:
    {% endif %}
        - user: {{ pillar.elife.deploy_user.username }}
        - identifier: daily-query-uploads
        - name: cd /srv/lax && ./manage.sh query_export
        # occurs 1hr after ejp import
        - minute: 30
        - hour: 13
        - require:
            - cmd: configure-lax
