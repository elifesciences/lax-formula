#
# adaptors for lax
# processes that transform/adapt their input to generate lax compatible output
#

# library for parsing the ejp report into article stubs for lax
ejp-scraper:
    file.directory:
        - name: /opt/ejp-scraper/
        - user: {{ pillar.elife.deploy_user.username }}
        
    git.latest:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: https://github.com/elifesciences/ejp-scraper
        - target: /opt/ejp-scraper/
        - force_fetch: True
        - force_checkout: True
        - force_reset: True
        - require:
            - file: ejp-scraper

    cmd.run:
        - cwd: /opt/ejp-scraper/
        - name: ./install.sh
        - require:
            - git: ejp-scraper
