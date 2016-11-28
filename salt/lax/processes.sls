{% set number = 1 %}
bot-lax-adaptors-task:
    file.managed:
        - name: /etc/init/bot-lax-adaptors.conf
        - source: salt://elife/config/etc-init-multiple-processes.conf
        - template: jinja
        - context:
            process: bot-lax-adaptor
            number: {{ number }}
        - require:
            - bot-lax-adaptor-service

bot-lax-adaptors-start:
    cmd.run:
        - name: start bot-lax-adaptors
        - require:
            - bot-lax-adaptors-task

bot-lax-adaptors-monitor:
    cron.present:
        - identifier: upstart-monitoring-bot-lax-adaptor
        - name: /usr/local/bin/upstart-monitoring "bot-lax-adaptor (1)"
        - minute: '*/5'
        - require:
            - bot-lax-adaptors-start
