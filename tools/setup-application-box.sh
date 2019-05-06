#!/bin/bash

if [ -z "$2" ]; then
  set -- $1 "."
fi
set -euo pipefail

BOX=$1
ROOT_DIR=$(cd $2; pwd)

cd "$ROOT_DIR/deployment"
if [ -d host_vars ]; then
  rm host_vars
fi
ln -sf "../boxes/$BOX/host_vars" host_vars
ln -sf "../boxes/$BOX/passphrase.gpg" passphrase.gpg
ln -sf "../boxes/$BOX/playbook.yml" playbook.yml

function get_variable {
  echo $1 | grep "^$2:" | cut -d: -f2 | awk '{ print $1 }'
}

HOST_VARS=$(ansible-vault view "host_vars/application-box.yml")
HOST_FILES="host_vars/application-box-files"

USER_NAME=$(get_variable $HOST_VARS "user_name")
USER_PASSWORD=$(get_variable $HOST_VARS "user_password")
ROOT_PASSWORD=$(get_variable $HOST_VARS "root_password")
IP_ADDRESS=$(get_variable $HOST_VARS "ip_address")
KNOWN_HOSTS="$HOST_FILES/known_hosts"

if [ -f $KNOWN_HOSTS ]; then
  ansible-vault decrypt $KNOWN_HOSTS
else
  ./tools/know-host.exp $IP_ADDRESS $KNOWN_HOSTS $ROOT_PASSWORD

  if [[ $? -eq 0 ]] ; then
    sshpass -p $ROOT_PASSWORD scp -o UserKnownHostsFile=$KNOWN_HOSTS "../tools/configure-application-box.sh" root@$IP_ADDRESS:~/
    sshpass -p $ROOT_PASSWORD ssh -o UserKnownHostsFile=$KNOWN_HOSTS root@$IP_ADDRESS exec "./configure-application-box.sh $ROOT_DIR $USER_NAME $USER_PASSWORD"
  fi
fi

PUBLIC_KEY="$HOST_FILES/id_rsa.pub"
PRIVATE_KEY="$HOST_FILES/id_rsa"
if [ -f $PUBLIC_KEY ]; then
  ansible-vault decrypt $PUBLIC_KEY $PRIVATE_KEY
fi

function encrypt_host_files {
  ansible-vault encrypt $HOST_FILES/*
}
trap encrypt_host_files EXIT

ansible-playbook playbook.yml
