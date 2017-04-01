#!/bin/bash

util::wait_for_url() {
  local url=$1
  local prefix=${2:-}
  local wait=${3:-0.5}
  local times=${4:-25}

  which curl >/dev/null || {
    log::error_exit "curl must be installed"
  }

  local i
  for i in $(seq 1 $times); do
    local out
    if out=$(curl -fs $url 2>/dev/null); then
      log::status "On try ${i}, ${prefix}: ${out}"
      return 0
    fi
    sleep ${wait}
  done
  log::error "Timed out waiting for ${prefix} to answer at ${url}; tried ${times} waiting ${wait} between each"
  return 1
}
