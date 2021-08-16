#!/bin/bash

USAGE="usage: set-eslint.sh path [--dry-run]
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

# $1 pattern, $2 filename
function remove_lines_matching_pattern() {
    grep "$1" -o -r "$BASE_PATH/$2" | while read -r LINE ; do
        FILE="$(cut -d ':' -f 1 <<< "$LINE" )"
        TOCHANGE="$(cut -d ':' -f 2- <<< "$LINE" | sed -e 's/[*^$.]/\\&/g')"
        echo "Found -> $TOCHANGE <- in -> $FILE <-"
        if [[ "$DRY_RUN" -eq "" ]] ; then
            sed -i '' -e "s/$TOCHANGE//g" "$FILE"
            echo "...removed!"
        fi
    done
    sed -i '' -e "/^$/d" "$BASE_PATH/$2"
}

# $1 reference pattern, $2 filename, $3 newline
function append_line_after_reference_pattern() {
    ESCAPED_NEWLINE="$(echo "$3" | sed -e 's/[*^$.]/\\&/g')"
    if [[ "$DRY_RUN" -eq "" ]] ; then
        sed -i '' -e "/$1/ a\ 
        $ESCAPED_NEWLINE
        \
        " $BASE_PATH/$2
        echo "...added!"
    fi
}

# $1 pattern, $2 filename, $3 newline
function replace_lines_matching_pattern() {
    grep "$1" -o -r "$BASE_PATH/$2" | while read -r LINE ; do
        FILE="$(cut -d ':' -f 1 <<< "$LINE" )"
        TOCHANGE="$(cut -d ':' -f 2- <<< "$LINE" | sed -e 's/[*^$.]/\\&/g')"
        ESCAPED_NEWLINE="$(echo "$3" | sed -e 's/[*^$.]/\\&/g')"
        echo "Found -> $TOCHANGE <- with -> $ESCAPED_NEWLINE <- in -> $FILE <-"
        if [[ "$DRY_RUN" -eq "" ]] ; then
            sed -i '' -e "s/$TOCHANGE/$ESCAPED_NEWLINE/g" "$FILE"
            echo "...changed!"
        fi
    done
}

# $1 package
function remove_package() {
    if [[ "$DRY_RUN" -eq "" ]] ; then
        cd $BASE_PATH
        echo "--- Working on $(pwd) ---"
        yarn remove $1
        echo "...added!"
        cd -
    fi
}

# $1 package
function add_package() {
    if [[ "$DRY_RUN" -eq "" ]] ; then
        cd $BASE_PATH
        echo "--- Working on $(pwd) ---"
        yarn add -D $1
        echo "...added!"
        cd -
    fi
}

echo "Searching 'tslint.json'..."
if [[ "$DRY_RUN" -eq "" ]] ; then
    rm "$BASE_PATH/tslint.json"
    echo "...deleted!"
fi

echo "Searching and removing 'italia-tslint-rules' reference from 'package.json'..."
remove_package "italia-tslint-rules"

echo "Searching and removing 'tslint' reference from 'package.json'..."
remove_package "tslint"

echo "Adding '@pagopa/eslint-config' to 'package.json' dev dependencies..."
add_package "@pagopa/eslint-config"

echo "Adding 'eslint-plugin-prettier' to 'package.json' dev dependencies..."
add_package "eslint-plugin-prettier"

echo "Searching and removing 'lint-autofix' task from 'package.json'..."
remove_lines_matching_pattern '\s*"lint-autofix":\s*".*",' 'package.json'

echo "Replacing 'lint' task on 'package.json'..."
replace_lines_matching_pattern '"lint":\s*"tslint.*",' 'package.json' '"lint": "eslint . -c .eslintrc.js --ext .ts,.tsx",'

echo "Appending 'eslint' rules section to '.gitignore'..."
if [[ "$DRY_RUN" -eq "" ]] ; then
    echo "" >> "$BASE_PATH/.gitignore"
    echo "# eslint section" >> "$BASE_PATH/.gitignore"
    echo "!.eslintrc.js" >> "$BASE_PATH/.gitignore"
    echo ".eslintcache" >> "$BASE_PATH/.gitignore"  
    echo "...added!"
fi

echo "Creating '.eslintrc.js' and '.eslintignore' files..."
if [[ "$DRY_RUN" -eq "" ]] ; then
    cp .eslintrc.js.template "$BASE_PATH/.eslintrc.js"
    #cp .eslintignore.template "$BASE_PATH/.eslintignore"
    echo "...created!"
fi
