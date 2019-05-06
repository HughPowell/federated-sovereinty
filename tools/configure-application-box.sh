#!/bin/bash

set -euo pipefail

ROOT_DIR=$1
USER_NAME=$2
USER_PASSWORD=$3

function exit_server {
  RESULT=$?
  rm configure-application-box.sh
  exit $RESULT
}
trap exit_server EXIT

apt install -yy sudo openssh-server python3

PRIVACY_FILE="/etc/sudoers.d/privacy"
LECTURE="Defaults        lecture = never"
grep "$LECTURE" "$PRIVACY_FILE" || echo "$LECTURE" > "$PRIVACY_FILE"

if ! $(id -u $USER_NAME &>/dev/null) ; then
  adduser --disabled-password --gecos "User" $USER_NAME
  echo "$USER_NAME:$USER_PASSWORD" | chpasswd
  usermod -aG sudo $USER_NAME
fi

passwd -S root | grep "root L" || passwd --delete --lock root
