# eslint-utils

Usefull scripts to use when dealing with eslint linting:

- *auto-ignore-linting.sh* to automatically add rule flags to a project. Very useful when we can't fix all linting errors and don't want to write specific comments to every line.

# tslint2eslint folder

In this folder there are useful scripts (even if they are a bit rough...) to migrate from tslint to eslint.

You can run them in this sequence:

1) `sh set-eslint.sh <path> [--dry-run]`: will remove tslint and set all tslint's files for the given path; --dry-run will let you know which changes will be done without applying them.
2) `sh replace-comments <path> [--dry-run]`: will replace tslint's rule flags with eslint ones for the given path; --dry-run will let you know which changes will be done without applying them.
3) `sh add-ignores <path> [--dry-run]`: will add rule flags for every lint error in the given path; --dry-run will let you know which changes will be done without applying them.
4) `sh test-project <path>`: will install dependencies, run build, test and lint for the given path to let you know if something got broken.
