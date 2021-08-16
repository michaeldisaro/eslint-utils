#!/bin/bash

USAGE="usage: test-project.sh path
       where:
       - path: the absolute path of the repo to migrate to eslint
      "

if [[ $# -lt 1 ]] ; then
    echo "$USAGE"
    exit 1
fi

INPUTS=( "$@" )
BASE_PATH="${INPUTS[0]}"

cd $BASE_PATH
echo "--- Working on $(pwd) ---"
yarn install
yarn build
yarn test
yarn lint
