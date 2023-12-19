#! /bin/sh

set -e

chmod +x /bin/evebox

if [ "${1:0:1}" = "-" ]; then
    set -- /bin/evebox server "$@"
fi

exec "$@"
