#!/bin/bash

mkdir -p /hiddify-data/ssl/
rm -rf /opt/hiddify-manager/log/*.lock

# Wait for MariaDB to accept TCP connections before panel initialization.
if [ -z "$SQLALCHEMY_DATABASE_URI" ]; then
  db_host="mariadb"
  db_port="3306"
else
  db_host=$(echo "$SQLALCHEMY_DATABASE_URI" | sed -n "s#.*@\([^:/?]*\).*#\1#p")
  db_port=$(echo "$SQLALCHEMY_DATABASE_URI" | sed -n "s#.*@[^:/?]*:\([0-9][0-9]*\).*#\1#p")
  db_port=${db_port:-3306}
fi

for i in $(seq 1 60); do
  if (echo >/dev/tcp/$db_host/$db_port) >/dev/null 2>&1; then
    break
  fi
  echo "Waiting for MySQL at ${db_host}:${db_port} (${i}/60)..."
  sleep 2
done

# Check and set REDIS_URI_MAIN
if [ -z "$REDIS_URI_MAIN" ]; then
  if [ -z "$REDIS_PASSWORD" ]; then
    echo "One of the env variables REDIS_STRONG_PASS or REDIS_URI_MAIN must be set"
    exit 1
  fi
  export REDIS_URI_MAIN="redis://:${REDIS_PASSWORD}@redis:6379/0"
fi

# Check and set REDIS_URI_SSH
if [ -z "$REDIS_URI_SSH" ]; then
  if [ -z "$REDIS_PASSWORD" ]; then
    echo "One of the env variables REDIS_STRONG_PASS or REDIS_URI_SSH must be set"
    exit 1
  fi
  export REDIS_URI_SSH="redis://:${REDIS_PASSWORD}@redis:6379/1"
fi

# Check and set SQLALCHEMY_DATABASE_URI
if [ -z "$SQLALCHEMY_DATABASE_URI" ]; then
  if [ -z "$MYSQL_PASSWORD" ]; then
    echo "One of the env variables MYSQL_PASSWORD or SQLALCHEMY_DATABASE_URI must be set"
    exit 1
  fi
  export SQLALCHEMY_DATABASE_URI="mysql+mysqldb://hiddifypanel:${MYSQL_PASSWORD}@mariadb/hiddifypanel?charset=utf8mb4"
fi


cd $(dirname -- "$0")

# Check systemctl is setup correctly for docker.
systemctl is-active --quiet hiddify-panel
if [ $? -ne 0 ]; then
  echo "systemctl returned non-zero exit code. Re install systemctl..."
  cp other/docker/* /usr/bin/
  systemctl restart hiddify-panel
fi

DO_NOT_INSTALL=true ./install.sh docker --no-gui $@
./status.sh --no-gui

echo Hiddify is started!!!! in 5 seconds you will see the system logs
sleep 5
tail -f /opt/hiddify-manager/log/system/*