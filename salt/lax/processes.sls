# 16.04+

# these are the states multiservice.sls depends on
# we can use it to make sure other states are executed before the service is started/restarted
bot-lax-adaptor-service:
    file.absent:
        - name: /lib/systemd/system/bot-lax-adaptor@.service

