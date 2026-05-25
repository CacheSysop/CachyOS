#!/usr/bin/env fish

# Exit immediately if a command exits with a non-zero status
set -e

curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish

omf install lambda
omf theme lambda
