#!/bin/bash

HOST_VARS_FILE=$1

ansible-vault decrypt $HOST_VARS_FILE
if ! grep -q '^mailuser_password:' $HOST_VARS_FILE; then
	echo "Creating password"
	PASSWORD=$(pwgen -s 128 1)
	echo "mailuser_password: ${PASSWORD}" >> $HOST_VARS_FILE
fi
ansible-vault encrypt $HOST_VARS_FILE
