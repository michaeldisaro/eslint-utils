#!/bin/bash

USAGE="usage: remove-ignore-rule.sh path rule [--dry-run]
       where:
       - path: the absolute path of the repo to migrate to eslint
       - rule: is the rule to remove
       - --dry-run: (optional) no file will be changed
      "

if [[ $# -lt 2 ]] ; then
    echo "$USAGE"
    exit 1
fi

INPUTS=( "$@" )
BASE_PATH="${INPUTS[0]}"
RULE="${INPUTS[1]}"
ESCAPED_RULE=$(printf '%s\n' "$RULE" | sed -e 's/[\/&*@]/\\&/g')
DRY_RUN="${INPUTS[2]}"

# search for RULE
grep ".*$ESCAPED_RULE.*" -r -l --exclude-dir node_modules --exclude-dir dist --exclude-dir generated --include \*.ts --include \*.njk --include \*.snap $BASE_PATH/* | while read -r FILE ; do
    echo "Removing $RULE from $FILE"
    if [[ -z "$DRY_RUN" ]] ; then
        sed -i '' -e "s/ *\,* *$ESCAPED_RULE\,*//g" "$FILE"
    fi

    echo "Removing empty eslint disable comments in $FILE"
    if [[ -z "$DRY_RUN" ]] ; then
        sed -i '' -e "s/\/\* *eslint-disable *\*\/$//g" "$FILE"
        sed -i '' -e "s/\/\* *eslint-enable *\*\/$//g" "$FILE"
        sed -i '' -e "s/\/\/ *eslint-disable-next-line *$//g" "$FILE"
        sed -i '' -e "s/\/\/ *eslint-disable *$//g" "$FILE"
        sed -i '' -e "s/\/\/ *eslint-enable *$//g" "$FILE"
    fi
done
