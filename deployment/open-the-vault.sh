#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
PASSPHRASE_FILE="$DIR/passphrase.gpg"

gpg --batch --use-agent --decrypt $PASSPHRASE_FILE
