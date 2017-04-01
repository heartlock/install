#!/bin/bash

HYPERD_TEMP=${HYPERD_TEMP:-/tmp}
GO_HYPERHQ_PATH=${GO_HYPERHQ_PATH:-${HYPERD_TEMP}/src/github.com/hyperhq}

hyper::install_hypercontainer() {
  # subshell so that we can export GOPATH without breaking other things
  (
    export GOPATH=${HYPERD_TEMP}
    mkdir -p "${GO_HYPERHQ_PATH}"

    log::status "install necessary tools"
    hyper::preinstall

    log::status "build hyperd"
    hyper::build_hyperd

    log::status "build hyperstart"
    hyper::build_hyperstart
  )

  log::status "install hyperd and hyperstart"
  hyper::export_related_path
  hyper::start_hyperd
}

hyper::build_hyperstart() {
  local hyperstart_root=${GO_HYPERHQ_PATH}/hyperstart
  log::info "clone hyperstart repo"
  git clone https://github.com/hyperhq/hyperstart ${hyperstart_root}
  cd ${hyperstart_root}
  log::info "build hyperstart"
  ./autogen.sh
  ./configure
  make

  HYPER_KERNEL_PATH="${hyperstart_root}/build/kernel"
  if [ ! -f ${HYPER_KERNEL_PATH} ]; then
      return 1
  fi
  HYPER_INITRD_PATH="${hyperstart_root}/build/hyper-initrd.img"
  if [ ! -f ${HYPER_INITRD_PATH} ]; then
      return 1
  fi
}

hyper::build_hyperd() {
  local hyperd_root=${GO_HYPERHQ_PATH}/hyperd

  log::info "clone hyperd repo"
  git clone https://github.com/hyperhq/hyperd ${hyperd_root}

  cd ${hyperd_root}
  log::info "build hyperd"
  ./autogen.sh
  ./configure
  make

  HYPERD_BINARY_PATH="${hyperd_root}/hyperd"
  if [! -f ${HYPERD_BINARY_PATH}]; then
      return 1
  fi
}
hyper::start_hyperd() {
    log::status "starting hyperd"
    local config=${HYPERD_TEMP}/hyper_config
    local hyper_api_port=12346
    cat > ${config} << __EOF__
Kernel=${HYPER_KERNEL_PATH}
Initrd=${HYPER_INITRD_PATH}
StorageDriver=overlay
gRPCHost=127.0.0.1:22318
__EOF__

    sudo "${HYPERD_BINARY_PATH}" \
        --host="tcp://127.0.0.1:${hyper_api_port}" \
        --log_dir=${HYPERD_TEMP} \
        --v=3 \
        --config="${config}" &>/dev/null &
    HYPERD_PID=$!
    util::wait_for_url "http://127.0.0.1:${hyper_api_port}/info" "hyper-info"
}
# install dependencies to build hyperd and hyperstart
# only support ubuntu disto for now
hyper::preinstall() {
  if ! type "apt-get" > /dev/null 2>&1 ; then
    return 0
  fi
  sudo apt-get update -qq
  sudo apt-get install -y autoconf automake pkg-config libdevmapper-dev libsqlite3-dev libvirt-dev qemu libvirt-bin -qq
}

hyper::export_related_path() {
  # hyperstart kernel and image path
  HYPER_KERNEL_PATH="${GO_HYPERHQ_PATH}/hyperstart/build/kernel"
  HYPER_INITRD_PATH="${GO_HYPERHQ_PATH}/hyperstart/build/hyper-initrd.img"

  # hyperd binary path
  HYPERD_BINARY_PATH="${GO_HYPERHQ_PATH}/hyperd/hyperd"
}

hyper::cleanup() {
  rm -rf "${GO_HYPERHQ_PATH}/*"
}
