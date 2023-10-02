
# library for parsing the ejp report into article stubs for lax

bot-lax-adaptor:
    pkg.installed:
        - pkgs:
            - libxml2-dev
            - libxslt1.1
            - lzma-dev # provides 'lz' for compiling lxml
            - sqlite3 # for accessing requests_cache db
        - require:
            - pkg: python-dev

    file.directory:
        - name: /opt/bot-lax-adaptor/
        - user: {{ pillar.elife.deploy_user.username }}

    git.latest:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: https://github.com/elifesciences/bot-lax-adaptor
        # lax will update bot-lax repo to the pinned version.
        - rev: master
        - branch: master
        - target: /opt/bot-lax-adaptor/
        - force_fetch: True
        - force_checkout: True
        - force_reset: True
        - require:
            - file: bot-lax-adaptor

    # alert! this will mess with the rev/branch specified in above git.latest
    # to affect the git rev, ensure it's pinned in lax's bot-lax-adaptor.sha1
    cmd.run:
        - cwd: /opt/bot-lax-adaptor
        - name: |
            # lsh@2023-01-25: added a 'git fetch' as git.latest above isn't fetching a revision that's available.
            # * https://github.com/saltstack/salt/issues/24409#issuecomment-228708638
            # * https://github.com/saltstack/salt/issues/34367
            git fetch
            ./pin.sh /srv/lax/bot-lax-adaptor.sha1
        - runas: {{ pillar.elife.deploy_user.username }}
        - require:
            - pkg: bot-lax-adaptor
            - file: bot-lax-adaptor
            - git: bot-lax-adaptor

bot-lax-adaptor-config:
    file.managed:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: /opt/bot-lax-adaptor/app.cfg
        - source: salt://lax/config/opt-bot-lax-adaptor-app.cfg
        - template: jinja
        - require:
            - bot-lax-adaptor

bot-lax-adaptor-install:
    cmd.run:
        - cwd: /opt/bot-lax-adaptor
        - name: ./install.sh
        - runas: {{ pillar.elife.deploy_user.username }}
        - require:
            - bot-lax-adaptor
            - bot-lax-adaptor-config

#
# logging
#

bot-lax-adaptor-log-file-monitoring:
    file.managed:
        - name: /etc/syslog-ng/conf.d/bot-lax-adaptor.conf
        - source: salt://lax/config/etc-syslog-ng-conf.d-bot-lax-adaptor.conf
        - template: jinja

logrotate-for-bot-lax-adaptor-logs:
    file.managed:
        - name: /etc/logrotate.d/bot-lax-adaptor
        - source: salt://lax/config/etc-logrotate.d-bot-lax-adaptor
        - template: jinja

{% for path in ['/ext/cache/', '/var/log/bot-lax-adaptor/'] %}
dir-{{ path }}:
    file.directory:
        - name: {{ path }}
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.webserver.username }}
        # writeable by user+group, readable by all else
        - dir_mode: 774
        - file_mode: 664 # read+write for user and group, read for world
        - recurse:
            - user
            - group
            - mode
        - require_in:
            - cmd: bot-lax-writable-dirs

    cmd.run:
        # sticky group, new files inherit the group owner of the directory (www-data).
        - name: chmod -R g+s {{ path }}
        - require:
            - file: dir-{{ path }}
{% endfor %}

bot-lax-writable-dirs:
    cmd.run:
        - name: echo "dirs created"

# fix for issue: https://github.com/elifesciences/issues/issues/7534
# bit of a hack. essentially: cache db is created by www-data user and the elife user can't write to it as necessary.
# this creates the cache db as elife and grants the group (www-data, sticky guid set) write access.
# this issue came about when end2end was recreated and then failed end2end tests.
# a subsequent highstate hadn't been run on the end2end instance before the tests.
bot-lax-init-cache-db:
    cmd.run:
        - cwd: /opt/bot-lax-adaptor/src
        - runas: {{ pillar.elife.deploy_user.username }}
        - name: |
            ../venv/bin/python3 -c 'import cache_requests; print(cache_requests.install_cache_requests())'
            chmod g+w /ext/cache/requests_cache.sqlite3
        - require:
            - bot-lax-adaptor-install
            - bot-lax-writable-dirs

periodically-remove-expired-cache-entries:
    cron.present:
        - user: {{ pillar.elife.deploy_user.username }}
        # sqlite essentially duplicates the database for this operation
        # - https://sqlite.org/tempfiles.html#write_ahead_log_wal_files
        - name: SQLITE_TMPDIR=/ext/tmp cd /opt/bot-lax-adaptor/ && ./clear-expired-requests-cache.sh
        - identifier: rm-expired-cache-entries
        - minute: 0
        - hour: 0
        - dayweek: 1 # Monday

#
#
#

move /opt/bot-lax/article-xml/ to /ext/article-xml:
    cmd.script:
        - cwd: /ext
        - source: salt://lax/scripts/mv-article-xml.sh

    file.managed:
        - name: /ext/mv-article-xml.sh
        - source: salt://lax/scripts/mv-article-xml.sh

#
# bot-lax web api
# 

dir-/ext/uploads/:
    file.absent:
        - name: /ext/uploads

bot-lax-nginx-conf:
    file.absent:
        - name: /etc/nginx/sites-enabled/bot-lax-adaptor.conf
        - watch_in:
            - service: nginx-server-service

bot-lax-uwsgi-conf:
    file.absent:
        - name: /opt/bot-lax-adaptor/uwsgi.ini

uwsgi-bot-lax-adaptor.socket:
    service.dead:
        - enable: False

uwsgi-bot-lax-adaptor:
    service.dead:
        - enable: False

# once a week, remove any uploaded files that are more than a year old
periodically-remove-expired-old-uploaded-files:
    cron.absent:
        - user: {{ pillar.elife.deploy_user.username }}
        - identifier: rm-old-uploaded-files
