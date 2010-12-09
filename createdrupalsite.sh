#!/bin/bash

if [[ $# -lt 1 ]]; then
    echo "usage:" `basename $0` "<site prefix>" "[domain]"
    echo
    echo "  <site prefix>  site prefix, for example m1000 in m1000.tzapp.com"
    echo "  [domain]       optional domain, default tzapp.com"
    exit 2
fi

PREFIX=$1
DOMAIN=tzapp.com
HOST="$PREFIX.$DOMAIN"
if [ "q$2" != "q" ]; then
    echo "Overriding default domain with \"$2\""
    DOMAIN=$2;
fi

echo -n "Creating database \"$PREFIX\": "
mysqladmin -u root -p create "$PREFIX"

PASSWORD=`pwgen -c -n 12 1`;
echo -n "Creating DB user \"$PREFIX\": "
echo "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON \`$PREFIX\`.* TO '$PREFIX'@'localhost' IDENTIFIED BY '$PASSWORD';" | mysql -u root -p mysql

echo "Creating settings.php at $HOST/settings.php"
TEMPLATE=`find . -name default.settings.php | head -n1`
mkdir "$HOST"

# Find line number of db settings in template
TEMPLATELINES=`wc "$TEMPLATE" | cut -f2 -d' '`
DBLINE=`grep -n '^$db_url = ' "$TEMPLATE" | cut -f1 -d:`
head -n $(($DBLINE - 1)) "$TEMPLATE" > "$HOST"/settings.php
echo "\$db_url = 'mysqli://$PREFIX:$PASSWORD@localhost/$PREFIX';" >> "$HOST"/settings.php
tail -n $(($TEMPLATELINES - $DBLINE)) "$TEMPLATE" >> "$HOST"/settings.php

echo "Settings filesystem permissions"
mkdir "$HOST"/files
chmod 777 "$HOST"/files
chmod 644 "$HOST"/settings.php
