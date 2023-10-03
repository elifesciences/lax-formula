# 16.04+

# these are the states multiservice.sls depends on
# we can use it to make sure other states are executed before the service is started/restarted
bot-lax-adaptor-service:
    file.managed:
        - name: /lib/systemd/system/bot-lax-adaptor@.service
        - source: salt://lax/config/lib-systemd-system-bot-lax-adaptor@.service
        - template: jinja
        - context:
            process: bot-lax-adaptor
        - require:
            - bot-lax-adaptor-install
