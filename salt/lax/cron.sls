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

daily-ejp-import-cron:
    # don't scrape ejp data outside of prod/adhoc instances
    {% if pillar.elife.env in ['dev', 'continuumtest', 'ci', 'end2end'] %}
    cron.absent:
    {% else %}
    cron.present:
    {% endif %}
        - user: {{ pillar.elife.deploy_user.username }}
        - identifier: daily-ejp-import
        - name: cd /opt/ejp-lax-adaptor/ && ./scrape-ejp-load-lax.sh
        - minute: 30
        - hour: 12
        - require:
            - file: daily-ejp-import
