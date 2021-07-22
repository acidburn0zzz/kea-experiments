#!/bin/sh

# Copyright (C) 2021 Internet Systems Consortium, Inc. ("ISC")
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Usage:
#
# ./src/share/yang/modules/reinstall.sh [-d|--debug] [-h|--help] [-s|--sysrepo ${SYSREPO_INSTALLATION}]

# Exit with error if commands exit with non-zero and if undefined variables are
# used.
set -eu

script_path=$(cd "$(dirname "${0}")" && pwd)
kea_sources=$(cd "${script_path}/../../../../.." && pwd)
modules="${kea_sources}/src/share/yang/modules"

# Print usage.
# Expressions don't expand in single quotes, use double quotes for that. [SC2016]
# shellcheck disable=SC2016
print_usage() {
  printf \
'Usage: %s {{options}}
Options:
  [-d|--debug]                              enable debug mode, showing every executed command
  [-h|--help]                               print usage (this text)
  [-s|--sysrepo ${SYSREPO_INSTALLATION}]    point to sysrepo installation which is needed for sysrepoctl
' \
    "$(basename "${0}")"
}

# Define some ANSI color codes.
if test -t 1; then
  red='\033[91m'
  reset='\033[0m'
else
  red=
  reset=
fi

# Parse parameters.
while test ${#} -gt 0; do
  case "${1}" in
    # [-d|--debug]                              enable debug mode, showing every executed command
    '-d'|'--debug') set -vx ;;

    # [-h|--help]                               print usage (this text)
    '-h'|'--help') print_usage; exit 0 ;;

    # [-s|--sysrepo ${SYSREPO_INSTALLATION}]    point to sysrepo installation which is needed for sysrepoctl
    '-s'|'--sysrepo') shift; sysrepo=${1} ;;

    # Unrecognized argument
    *)
    printf "${red}ERROR: Unrecognized argument '%s'${reset}\\n" "${1}" 1>&2; print_usage; exit 1 ;;
  esac; shift
done

# Default arguments
test -z "${sysrepo+x}" && sysrepo='/usr/local'

#------------------------------------------------------------------------------#

# Check if model is installed.
is_model_installed() {
  model=${1}
  if test "$("${sysrepo}/bin/sysrepoctl" -l | grep -F '| I' | cut -d ' ' -f 1 | tail -n +7 | head -n -1 | grep -Ec "^${model}")" -eq 0; then
    # not installed
    return 1
  fi
  # installed
  return 0
}

# Install a model from the Kea sources. Should upgrade automatically to a newer
# revision.
install_kea_model() {
  model=${1}
  find "${modules}" -maxdepth 1 -type f -name "${model}*.yang" -exec \
    ${sysrepo}/bin/sysrepoctl -i {} -s "${modules}" -v 4 \;
}

# Uninstall a model if installed.
uninstall_model() {
  model=${1}
  if ! is_model_installed "${model}"; then
    return;
  fi
  "${sysrepo}/bin/sysrepoctl" -u "${model}" -v 4
}

# Install all YANG models in dependency order.
install_yang_models() {
  install_kea_model 'keatest-module'
  install_kea_model 'ietf-interfaces'
  install_kea_model 'ietf-dhcpv6-common'
  install_kea_model 'ietf-dhcpv6-client'
  install_kea_model 'ietf-dhcpv6-relay'
  install_kea_model 'ietf-dhcpv6-server'
  install_kea_model 'ietf-yang-types'
  install_kea_model 'ietf-dhcpv6-options'
  install_kea_model 'ietf-dhcpv6-types'
  install_kea_model 'ietf-inet-types'
  install_kea_model 'kea-types'
  install_kea_model 'kea-dhcp-types'
  install_kea_model 'kea-dhcp-ddns'
  install_kea_model 'kea-ctrl-agent'
  install_kea_model 'kea-dhcp4-server'
  install_kea_model 'kea-dhcp6-server'
}

# Uninstall all YANG models in reverse dependency order.
# Currently not working. It complains:
#   Internal module "ietf-inet-types" cannot be uninstalled.
# Something about another module depending on ietf-inet-types.
# Might be related to a module that is internal to sysrepo.
# Might be for the better since installing YANG modules is idempotent and
# actually has logic to only install if the revision is newer which is arguably
# beneficial.
uninstall_yang_models() {
  uninstall_model 'kea-dhcp6-server'
  uninstall_model 'kea-dhcp4-server'
  uninstall_model 'kea-ctrl-agent'
  uninstall_model 'kea-dhcp-ddns'
  uninstall_model 'kea-dhcp-types'
  uninstall_model 'kea-types'
  uninstall_model 'ietf-inet-types'
  uninstall_model 'ietf-dhcpv6-types'
  uninstall_model 'ietf-dhcpv6-options'
  uninstall_model 'ietf-yang-types'
  uninstall_model 'ietf-dhcpv6-server'
  uninstall_model 'ietf-dhcpv6-relay'
  uninstall_model 'ietf-dhcpv6-client'
  uninstall_model 'ietf-dhcpv6-common'
  uninstall_model 'ietf-interfaces'
  uninstall_model 'keatest-module'
}

# uninstall_yang_models
install_yang_models