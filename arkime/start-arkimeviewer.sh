#!/bin/bash

echo "Giving ES time to start..."

echo "check directory "

echo "isinya $ARKIME_DIR/ : " && ls -l $ARKIME_DIR/
echo "isinya $ARKIME_DIR/etc/ : " && ls -l $ARKIME_DIR/etc/

echo "set config" && \

CFG_ini=$ARKIME_DIR/etc/config.ini
if test -f "$CFG_ini"; then
    echo "$CFG_ini exists."
else
    echo "$CFG_ini not exists."
    cp --verbose /config/ $ARKIME_DIR/etc/
fi

OUI_txt=/data/config/oui.txt
if test -f "$OUI_txt"; then
    echo "$OUI_txt exists."
else
    echo "$OUI_txt not exists."
    /opt/arkime/bin/arkime_update_geo.sh
fi

until curl -sS "http://$ES_HOST:$ES_PORT/_cluster/health?wait_for_status=yellow" > /dev/null 2>&1
do
    echo "Waiting for ES to start"
    sleep 3
done

echo "ES started..."

until [[ -d "/suricata-logs/fpc" ]] && [[ -f "/suricata-logs/eve.json" ]]
do
    echo "Waiting for Suricata to populate FPC and eve.json"
    sleep 3
done

# set runtime environment variables
export ARKIME_ELASTICSEARCH="http://"$ES_HOST":"$ES_PORT

if [ ! -f $ARKIME_DIR/etc/.initialized ]; then
    echo INIT | $ARKIME_DIR/db/db.pl $ARKIME_ELASTICSEARCH init
    $ARKIME_DIR/bin/arkime_add_user.sh $ARKIME_ADMIN_USERNAME "SELKS Admin User" $ARKIME_ADMIN_PASSWORD --admin
    $ARKIME_DIR/bin/arkime_add_user.sh moloch moloch moloch --admin --webauth
    echo $ARKIME_VERSION > $ARKIME_DIR/etc/.initialized
else
    # possible update
    read old_ver < $ARKIME_DIR/etc/.initialized
    # detect the newer version
    newer_ver=`echo -e "$old_ver\n$ARKIME_VERSION" | sort -rV | head -n 1`
    # the old version should not be the same as the newer version
    # otherwise -> upgrade
    if [ "$old_ver" != "$newer_ver" ]; then
        echo "Upgrading ES database..."
        echo UPGRADE | $ARKIME_DIR/db/db.pl http://$ES_HOST:$ES_PORT upgrade
        echo $ARKIME_VERSION > $ARKIME_DIR/etc/.initialized
    fi
fi

echo "Starting Arkime capture in the background..."
exec $ARKIME_DIR/bin/capture -m -s -R /suricata-logs/fpc/ >> $ARKIME_DIR/logs/capture.log 2>&1 &

echo "Look at log files for errors"
echo "  /data/logs/viewer.log"
echo "  /data/logs/capture.log"
echo "Visit http://127.0.0.1:8005 with your favorite browser."
echo "  user: $ARKIME_ADMIN_USERNAME"
echo "  password: $ARKIME_ADMIN_PASSWORD"

echo "Launch viewer..."
cd $ARKIME_DIR/viewer
$ARKIME_DIR/bin/node $ARKIME_DIR/viewer/viewer.js >> $ARKIME_DIR/logs/viewer.log 2>&1
