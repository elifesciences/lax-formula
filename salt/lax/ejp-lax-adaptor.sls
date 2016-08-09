ejp-lax-adaptor:
    file.directory:
        - name: /opt/ejp-lax-adaptor/
        - user: {{ pillar.elife.deploy_user.username }}

    git.latest:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: https://github.com/elifesciences/ejp-lax-adaptor
        - target: /opt/ejp-lax-adaptor/
        - force_fetch: True
        - force_checkout: True
        - force_reset: True
        - require:
            - file: ejp-lax-adaptor

    cmd.run:
        - cwd: /opt/ejp-lax-adaptor/
        - name: ./install.sh
        - require:
            - git: ejp-lax-adaptor

