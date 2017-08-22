{% set number = 1 %}

{% if salt['grains.get']('oscodename') == 'xenial' %}

# template service
bot-lax-adaptor-systemd:
    file.managed:
        - name: /lib/systemd/system/bot-lax-adaptor@.service
        - source: salt://lax/config/lib-systemd-system-bot-lax-adaptor@.service
        - template: jinja
        - require:
            - bot-lax-adaptor-install

# manages many bot-lax-adaptor services
bot-lax-adaptor-script:
    file.managed:
        - name: /opt/bot-lax-adaptors.sh
        - source: salt://elife/templates/systemd-multiple-processes.sh
        - template: jinja
        - context:
            process: bot-lax-adaptor
            number: {{ number }}

# service for management script
bot-lax-adaptors-task:
    file.managed:
        - name: /lib/systemd/system/bot-lax-adaptors.service
        - source: salt://lax/config/lib-systemd-system-bot-lax-adaptors.service
        - require:
            - bot-lax-adaptor-script

    service.running:
        - name: bot-lax-adaptors
        - require:
            - file: bot-lax-adaptors-task

{% else %}

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
{% endif %}

bot-lax-adaptors-monitor:
    cron.present:
        - identifier: upstart-monitoring-bot-lax-adaptor
        - name: /usr/local/bin/upstart-monitoring bot-lax-adaptor
        - minute: '*/5'
        - require:
            - bot-lax-adaptors-start
