#!/bin/bash
# assumes /ext exists
# executed in /ext as root

set -eux

if [ ! -e /opt/bot-lax-adaptor/article-xml ]; then
    # no article-xml, no problems
    exit 0
fi

if [ -h /opt/bot-lax-adaptor/article-xml ]; then
    # symlink exists, do nothing
    exit 0
fi

if [ -d /opt/bot-lax-adaptor/article-xml ]; then
    # source xml dir hasn't been moved yet

    if [ -d article-xml ]; then
        # but an /ext/article-xml dir exists too!
        rm -rf /ext/article-xml
    fi

    mv /opt/bot-lax-adaptor/article-xml /ext/
    cd /opt/bot-lax-adaptor
    ln -s /ext/article-xml

    # done
    exit 0
fi

echo "cannot move bot-lax article-xml, unknown state"
exit 1
