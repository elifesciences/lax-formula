lax:
    app:
        secret: dummy-secret-do-not-use-in-prod
        allow_invalid_ajson: False
        reporting_bucket: null
        cache_headers_ttl: null
        merge_foreign_fragments: True
        users:
            api_gateway:
                username: api-gateway
                password: foo

    glencoe:
        cache_requests: True # default behaviour is to cache requests

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

    botlax:
        api:
            url:

elife:
    webserver:
        app: caddy
    db:
        app:
            name: lax

    uwsgi:
        services:
            lax:
                folder: /srv/lax
                protocol: http-socket

    multiservice:
        services:
            bot-lax-adaptor:
                service_template: bot-lax-adaptor-service
                num_processes: 1
