#!/bin/bash
# restore a production backup of lax onto any instance
set -exv

cd /opt/ubr/

# downloads
./ubr.sh download s3 adhoc {{ pillar.lax.restore.db }}

# restore PostgreSQL
{% set db_basename = salt['file.basename'](pillar.lax.restore.db) %}
./ubr.sh restore file adhoc /tmp/ubr/{{ db_basename }} postgresql-database.laxend2end
