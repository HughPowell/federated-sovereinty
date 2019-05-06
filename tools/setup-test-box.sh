#!/bin/bash

if [ -z "$2" ]; then
  set -- $1 "." "-a"
fi
if [ -z "$3" ]; then
  set -- $1 "." "-a"
fi
set -euo pipefail

BOX=$1
ROOT_DIR=$(cd $2; pwd)
RESET=$3

cd "$ROOT_DIR/deployment"
if [ -d host_vars ]; then
  rm host_vars
fi
ln -sf "../boxes/$BOX/host_vars" host_vars
ln -sf "../boxes/$BOX/passphrase.gpg" passphrase.gpg
ln -sf "../boxes/$BOX/playbook.yml" playbook.yml

function get_variable {
  echo $1 | grep $2 | cut -d: -f2 | awk '{ print $1 }'
}

HOST_FILES="host_vars/application-box-files"
PRIVATE_KEY="$HOST_FILES/id_rsa"
PUBLIC_KEY="$HOST_FILES/id_rsa.pub"
HOST_VARS=$(ansible-vault view "host_vars/application-box.yml")
IP_ADDRESS=$(get_variable $HOST_VARS "ip_address")

if [ "$RESET" = "-r" ]; then
  
  if [ "$(ls -A $HOST_FILES)" ]; then
    rm -rf $HOST_FILES/*
  fi

  if $(VBoxManage list vms | grep -q StretchCurrent) ; then
    if $(VBoxManage list runningvms | grep -q StretchCurrent) ; then
      VBoxManage controlvm StretchCurrent acpipowerbutton
      sleep 5
    fi

    VBoxManage unregistervm StretchCurrent --delete
  fi

  VBoxManage clonevm StretchBase --options keepallmacs --name StretchCurrent --register
fi

if ! $(VBoxManage list runningvms | grep -q StretchCurrent); then
  VBoxManage startvm StretchCurrent --type headless &&
  until ping -c1 $IP_ADDRESS &>/dev/null; do sleep 1; done
fi

KNOWN_HOSTS="$HOST_FILES/known_hosts" 
if [ -f $KNOWN_HOSTS ]; then
  ansible-vault decrypt $KNOWN_HOSTS 
else
  USER_NAME=$(get_variable $HOST_VARS user_name)
  ../tools/know-host.exp $IP_ADDRESS $KNOWN_HOSTS ""
fi

if [ -f $PUBLIC_KEY ]; then
  ansible-vault decrypt $PUBLIC_KEY $PRIVATE_KEY
fi

function encrypt_files {
  ansible-vault encrypt $HOST_FILES/*
}
trap encrypt_files EXIT

ansible-playbook playbook.yml
