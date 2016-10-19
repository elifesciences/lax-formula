lax:
    app:
        # http://techblog.leosoto.com/django-secretkey-generation/
        secret: dummy-secret-do-not-use-in-prod
    db:
        name: lax
        username: foouser # case sensitive. use all lowercase
        password: barpass
        host: 127.0.0.1
        port: 5432
    sns:
        name: bus-articles
        subscriber: 1234567890
        region: us-east-1
