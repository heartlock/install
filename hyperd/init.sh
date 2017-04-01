#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

shopt -s expand_aliases
alias sudo='sudo env PATH=$PATH'

source "logging.sh"
source "hyper.sh"
source "util.sh"

log::install_errexit
