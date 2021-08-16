#!/bin/bash

USAGE="usage: replace-comments.sh path [--dry-run]
       where:
       - path: the absolute path of the repo to migrate to eslint
       - --dry-run: (optional) no file will be changed
      "

if [[ $# -lt 1 ]] ; then
    echo "$USAGE"
    exit 1
fi

INPUTS=( "$@" )
BASE_PATH="${INPUTS[0]}"
DRY_RUN="${INPUTS[1]}"

# search for // tslint comments
grep '\s*\/\/\s*tslint\:.*' -o -r --exclude-dir node_modules --exclude-dir dist --exclude-dir generated --include \*.ts --include \*.njk --include \*.snap $BASE_PATH/* | while read -r LINE ; do
    FILE="$(cut -d ':' -f 1 <<< "$LINE" )"
    COMMENT="$(cut -d ':' -f 2- <<< "$LINE" | xargs)"
    echo "$FILE"
    TEMP=${COMMENT/tslint:/eslint-}
    TEMP=${TEMP/eslint-disable /eslint-disable:}
    TEMP=${TEMP/eslint-disable-next-line /eslint-disable-next-line:}
    TEMP=${TEMP/eslint-enable /eslint-enable:}
    NEW_COMMENT="$(cut -d ':' -f 1 <<< "$TEMP" | xargs)"
    RULES="$(cut -d ':' -f 2- <<< "$TEMP" | xargs)"
    RULES=${RULES/:/ }
    NEW_RULES=""
    export IFS=" "
    for RULE in $RULES; do
        MATCH=$(grep ";$RULE$" substitutions)
        SUB=$(cut -d ';' -f 1 <<< "$MATCH" | xargs)
        if [[ -z "$SUB" ]] ; then
            echo " X $RULE"
        fi
        NEW_RULES="$NEW_RULES $SUB"
    done
    NEW_RULES=$(echo "$NEW_RULES" | xargs)
    NEW_RULES=${NEW_RULES// /, }
    RESULT="$NEW_COMMENT $NEW_RULES"
    if [[ -z "$NEW_RULES" ]] ; then
        RESULT=""
    fi
    echo " $COMMENT => $RESULT"
    if [[ "$DRY_RUN" -eq "" ]] ; then
        ESCAPED_COMMENT=$(printf '%s\n' "$COMMENT" | sed -e 's/[\/&*]/\\&/g')
        ESCAPED_RESULT=$(printf '%s\n' "$RESULT" | sed -e 's/[\/&*]/\\&/g')
        sed -i '' -e "s/$ESCAPED_COMMENT/$ESCAPED_RESULT/g" "$FILE"
    fi
    echo ""
done

# search for /* */ tslint comments
grep '\s*\/\*\s*tslint\:.*' -o -r --exclude-dir node_modules --exclude-dir dist --exclude-dir generated --include \*.ts --include \*.njk --include \*.snap $BASE_PATH/* | while read -r LINE ; do
    FILE="$(cut -d ':' -f 1 <<< "$LINE" )"
    COMMENT="$(cut -d ':' -f 2- <<< "$LINE" | xargs)"
    echo "$FILE"
    TEMP=${COMMENT/tslint:/eslint-}
    TEMP=${TEMP/eslint-disable /eslint-disable:}
    TEMP=${TEMP/eslint-disable-next-line /eslint-disable-next-line:}
    TEMP=${TEMP/eslint-enable /eslint-enable:}
    TEMP=${TEMP/\/\*/}
    TEMP=${TEMP/\*\//}
    NEW_COMMENT="$(cut -d ':' -f 1 <<< "$TEMP" | xargs)"
    RULES="$(cut -d ':' -f 2- <<< "$TEMP" | xargs)"
    RULES=${RULES/:/ }
    NEW_RULES=""
    export IFS=" "
    for RULE in $RULES; do
        MATCH=$(grep ";$RULE$" substitutions)
        SUB=$(cut -d ';' -f 1 <<< "$MATCH" | xargs)
        if [[ -z "$SUB" ]] ; then
            echo " X $RULE"
        fi
        NEW_RULES="$NEW_RULES $SUB"
    done
    NEW_RULES=$(echo "$NEW_RULES" | xargs)
    NEW_RULES=${NEW_RULES// /, }
    RESULT="/* $NEW_COMMENT $NEW_RULES */"
    echo " $COMMENT => $RESULT"
    if [[ "$DRY_RUN" -eq "" ]] ; then
        ESCAPED_COMMENT=$(printf '%s\n' "$COMMENT" | sed -e 's/[\/&*]/\\&/g')
        ESCAPED_RESULT=$(printf '%s\n' "$RESULT" | sed -e 's/[\/&*]/\\&/g')
        sed -i '' -e "s/$ESCAPED_COMMENT/$ESCAPED_RESULT/g" "$FILE"
    fi
    echo ""
done


