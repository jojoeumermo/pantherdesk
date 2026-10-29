#!/bin/bash
# Creates the site on first start (needs the db container), then runs the bench.
# Unlike the upstream dev script, outgoing mail is NOT muted: it goes to the lab
# GreenMail server once an outgoing Email Account is configured.
set -e
cd /home/frappe/frappe-bench

bench set-mariadb-host db
bench set-redis-cache-host redis://redis:6379
bench set-redis-queue-host redis://redis:6379
bench set-redis-socketio-host redis://redis:6379

if [ ! -d sites/helpdesk.localhost ]; then
  until mysqladmin ping -h db -uroot -pobs-lab-only --silent; do sleep 2; done
  bench new-site helpdesk.localhost --force \
    --mariadb-root-password obs-lab-only --admin-password admin --no-mariadb-socket
  bench --site helpdesk.localhost install-app telephony
  bench --site helpdesk.localhost install-app helpdesk
  bench --site helpdesk.localhost set-config developer_mode 0
  bench --site helpdesk.localhost set-config server_script_enabled 1
  # Scheduler on: needed for mail pull, SLA and automation observations.
  bench --site helpdesk.localhost enable-scheduler
  bench use helpdesk.localhost
fi

exec bench start
