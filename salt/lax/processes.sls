{% if salt['grains.get']('osrelease') != '14.04' %}

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

{% else %}

# 14.04

{% set number = 1 %}

bot-lax-adaptor-upstart:
    file.managed:
        - name: /etc/init/bot-lax-adaptor.conf
        - source: salt://lax/config/etc-init-bot-lax-adaptor.conf
        - template: jinja
        - require:
            - bot-lax-adaptor-install

    #service.running 
    # see `processes.sls` for how it is run 
    # see `/var/log/upstart/bot-lax-adaptor-{proc}.log` for errors in 14.04

bot-lax-adaptors-task:
    file.managed:
        - name: /etc/init/bot-lax-adaptors.conf
        - source: salt://elife/config/etc-init-multiple-processes.conf
        - template: jinja
        - context:
            process: bot-lax-adaptor
            number: {{ number }}
        - require:
            - bot-lax-adaptor-upstart

bot-lax-adaptors-start:
    cmd.run:
        - name: start bot-lax-adaptors
        - require:
            - bot-lax-adaptors-task

bot-lax-adaptors-monitor:
    cron.present:
        - identifier: upstart-monitoring-bot-lax-adaptor
        - name: /usr/local/bin/upstart-monitoring bot-lax-adaptor
        - minute: '*/5'
        - require:
            - bot-lax-adaptors-start
{% endif %}

