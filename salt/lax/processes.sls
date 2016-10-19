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
