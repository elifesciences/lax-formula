lax:
    app:
        # http://techblog.leosoto.com/django-secretkey-generation/
        secret: dummy-secret-do-not-use-in-prod
        allow_invalid_ajson: False
        reporting_bucket: null
    db:
        name: lax
        username: foouser # case sensitive. use all lowercase
        password: barpass
        host: 127.0.0.1
        port: 5432
    aws:
        access_key_id: null
        secret_access_key: null
        region: us-east-1
        subscriber: null
    sns:
        name: bus-articles
        subscriber: null # TODO: remove in favor of pillar.lax.aws
        region: us-east-1 # TODO: remove in favor of pillar.lax.aws
    restore:
        db: lax/201706/20170605_prod--lax.elifesciences.org_230109-laxprod-psql.gz


