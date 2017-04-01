#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source "init.sh"

hyper::install_hypercontainer
