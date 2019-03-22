lax:
    app:
        secret: dummy-secret-do-not-use-in-prod
        allow_invalid_ajson: False
        reporting_bucket: null
        cache_headers_ttl: null
        users:
            api_gateway:
                username: api-gateway
                password: foo

    botlax:
        api_whitelist:
            - '127.0.0.1' # internal
            - '10.0.2.2' # vagrant

    aws:
        access_key_id: null
        secret_access_key: null
        subscriber: null
        region: us-east-1

    sns:
        name: bus-articles
        subscriber: null # TODO: remove in favor of pillar.lax.aws
        region: us-east-1 # TODO: remove in favor of pillar.lax.aws
    restore:
        db: lax/201706/20170605_prod--lax.elifesciences.org_230109-laxprod-psql.gz

elife:
    db:
        app:
            name: lax

    uwsgi:
        services:
            lax:
                folder: /srv/lax
            bot-lax-adaptor:
                folder: /opt/bot-lax-adaptor
                disable_newrelic: True # todo: revisit

    newrelic:
        enabled: True

    newrelic_python:
        application_folder: /srv/lax
        service: uwsgi-lax
        dependency_state: configure-lax
