#!/bin/bash

USAGE="This script automatically adds eslint rule disabling comments to the given project
       usage: auto-ignore-linting.sh path [--dry-run]
       where:
       - path: the absolute path of the project failing linting
       - --dry-run: (optional) no file will be changed
      "

if [[ $# -lt 1 ]] ; then
    echo "$USAGE"
    exit 1
fi

INPUTS=( "$@" )
BASE_PATH="${INPUTS[0]}"
DRY_RUN="${INPUTS[1]}"

cd $BASE_PATH
echo "====== Disabling eslint rules on $(pwd) ======"

PREV_FILE=""
CUR_FILE=""
OFFSET=0
PREV_LINE=0
CUR_LINE=0
RULE=""
RULES=""

function ADD_IGNORE() {
    if [[ -z "$PREV_FILE" ]] ; then
        return;
    fi

    RULES=$(echo "$RULES" | sed -e 's/,$//g' | sed -e 's/^ //g')
    COMMENT_LINE=$(($PREV_LINE+$OFFSET))
    COMMENT="// eslint-disable-next-line $RULES"

    echo "|-> insert line $COMMENT_LINE -> $COMMENT"
    echo ""

    if [[ "$DRY_RUN" -eq "" ]] ; then
        sed -i '' -e "$COMMENT_LINE i\ 
            $COMMENT
            \
            " $PREV_FILE
    fi

    RULES=""
    OFFSET=$(($OFFSET+1))
}

LINTING=`yarn lint -f compact`

while read -r LINT_LINE ; do
    
    ESCAPED_LINE="$(echo "$LINT_LINE" | sed -e 's/[`$]//g')"

    if [[ -z "$ESCAPED_LINE" ]] ; then
        continue;
    fi
    
    if [[ $ESCAPED_LINE == /* ]] ; then
    
        CUR_FILE=$(cut -d ':' -f 1 <<< "$ESCAPED_LINE")
        REST_OF_LINE=$(cut -d ':' -f 2- <<< "$ESCAPED_LINE")
        CUR_LINE=$(cut -d ',' -f 1 <<< "$REST_OF_LINE" | sed -e 's/line //g' | xargs)
        
        if [[ "$CUR_FILE" != "$PREV_FILE" ]] ; then
            ADD_IGNORE
            echo ""
            echo "----------- PROCESSING $CUR_FILE ---------------"
            echo ""
            PREV_FILE=$CUR_FILE
            PREV_LINE=0
            OFFSET=0
        fi
        
        if [[ "$PREV_LINE" != "0" && "$CUR_LINE" != "$PREV_LINE" ]] ; then
            ADD_IGNORE
        fi

        echo "-$REST_OF_LINE"

        RULE=${REST_OF_LINE##*(}

        if [[ $RULE != *"line "* && $RULE != *"github.com"* ]] ; then
            RULE=$(echo "$RULE" | sed -e 's/)//g')
            if [[ $RULES != *$RULE* ]] ; then
                RULES="$RULES $RULE,"
            fi
        fi
        PREV_LINE=$CUR_LINE
    else
        if [[ ! -z "$PREV_FILE" ]] ; then
            if [[ $ESCAPED_LINE != *" problems" && $ESCAPED_LINE != *"yarnpkg.com"* ]] ; then
                RULE="@typescript-eslint/ban-types"
                if [[ $RULES != *$RULE* ]] ; then
                    RULES="$RULES $RULE,"
                fi  
            fi
        fi
    fi
    
done <<< "$LINTING"

ADD_IGNORE
