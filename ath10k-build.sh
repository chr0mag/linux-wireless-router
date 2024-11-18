#!/usr/bin/env bash

# this is Archlinux specific
# it assumes you want to build ath10k modules for the 'linux' or 'linux-lts' kernels installed on the local machine

# resource tarball name is referenced as follows: linux-$MAJOR.$MINOR.$PATCH.tar.xz
# eg. linux-5.10.16.tar.xz
BASE_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x"
SEMVER_REGEX='([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)'


# print an error and exit with failure
# $1: error message
function error() {
  echo "$0: error: $1" >&2
  exit 1
}

# ensure the programs needed to execute are available
function check_progs() {
  local PROGS="pacman curl tar patch make cp zcat xz"
  which ${PROGS} > /dev/null 2>&1 || error "Searching PATH fails to find executables among: ${PROGS}"
}

# ensure dependencies are installed
function check_deps() {
  pacman --query --quiet --check ${KERNEL_PKG_NAME}  ${KERNEL_PKG_NAME}-headers > /dev/null 2>&1 || error "Missing '${KERNEL_PKG_NAME}' and/or '${KERNEL_PKG_NAME}-headers'"
  pacman --query --groups --quiet base-devel > /dev/null 2>&1 || error "The 'base-devel' package group is required."
}

function check_root() {
  [ "${EUID}" = 0 ] || error "Script must be run with root privileges."
}

# usage: ./ath10k-build.sh linux
# usage: ./ath10k-build.sh linux-lts
function main() {
  KERNEL_PKG_NAME=${1}
  check_root
  check_deps
  check_progs

  KERNEL_PKG_VERSION=$(pacman --query --noconfirm "${KERNEL_PKG_NAME}" | awk '{print $2}')
  printf "KERNEL_PKG_VERSION: %s\n" "${KERNEL_PKG_VERSION}"
  KERNEL_SEMVER=$(echo "${KERNEL_PKG_VERSION}" | grep --extended-regexp --only-matching "${SEMVER_REGEX}")
  printf "KERNEL_SEMVER: %s\n" "${KERNEL_SEMVER}"
  KERNEL_LOCAL_VERSION="-$(echo "${KERNEL_PKG_VERSION}" | cut --delimiter='-' --fields=2)"
  printf "KERNEL_LOCAL_VERSION: %s\n" "${KERNEL_LOCAL_VERSION}"

  if [ "$(echo "${KERNEL_PKG_NAME}" | cut --delimiter='-' --fields=2)" == 'lts' ]; then
    KERNEL_EXTRA_VERSION=''
    KERNEL_DIR="${KERNEL_SEMVER}${KERNEL_LOCAL_VERSION}-lts"
  else
    KERNEL_EXTRA_VERSION='-arch1'
    KERNEL_DIR="${KERNEL_SEMVER}${KERNEL_EXTRA_VERSION}${KERNEL_LOCAL_VERSION}"
  fi

  printf "KERNEL_EXTRA_VERSION: %s\n" "${KERNEL_EXTRA_VERSION}"
  printf "KERNEL_DIR: %s\n" "${KERNEL_DIR}"
  printf "Building ath10k module for '%s'...\n" "${KERNEL_PKG_NAME}-${KERNEL_SEMVER}"

  curl --silent --location --remote-name "${BASE_URL}/linux-${KERNEL_SEMVER}.tar.xz" || error "Failed to download kernel"
  tar --verbose --extract --xz --file="linux-${KERNEL_SEMVER}.tar.xz" || error "Failed to extract kernel tarball"
  cd "linux-${KERNEL_SEMVER}" || error "Unable to cd to unpacked directory"
  patch --strip=1 < ../Revert-ath-add-support-for-special-0x0-regulatory-domain.diff
  make clean && make mrproper
  cp "/usr/lib/modules/${KERNEL_DIR}/build/Module.symvers" ./
  cp "/lib/modules/${KERNEL_DIR}/build/.config" .
  sed --in-place "s/^CONFIG_LOCALVERSION=\"\"\$/CONFIG_LOCALVERSION=\"${KERNEL_LOCAL_VERSION}\"/" .config
  make oldconfig && make EXTRAVERSION="${KERNEL_EXTRA_VERSION}" prepare
  make scripts
  cp "/usr/lib/modules/${KERNEL_DIR}/build/scripts/module.lds" scripts/.
  make M=drivers/net/wireless/ath
  xz drivers/net/wireless/ath/ath.ko
}

main "$@"
