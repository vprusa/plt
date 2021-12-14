#!/bin/bash
############################################################
# vprusa, 2021, prusa.vojtech@gmail.com
############################################################

#THIS_DIR=$(dirname $(realpath "$0"))
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
echo "THIS_DIR: ${THIS_DIR}"
# set -e
# set -x

# for variables DEBUG (for echo) and RUN_FUN (for exec) it is defined that
# containing specific flag character enables calling
# appropriate functions/procedures/debug/...
# Flags meanings:
# p -> prepare enviroment
# e -> additional scripts
# x -> let the script decide
# a -> apt
# y -> yum
# r -> rpm
# i -> install
# d -> dnf
# c -> cpan
# s -> sudo

RUN_FUN_DEFAULT="ix"

[[ -z "$1" ]] && RUN_FUN="${RUN_FUN_DEFAULT}" || RUN_FUN="$1"

# TODO as array with delimiter ';'
NOW_STR=$(date +%Y-%m-%d_%H-%M-%S) # can be used as filename
echo "NOW_STR: ${NOW_STR}"

INSTALL_CMD="apt"

[[ "${RUN_FUN}" == *"a"* ]] && INSTALL_CMD="apt"
[[ "${RUN_FUN}" == *"y"* ]] && INSTALL_CMD="yum"
[[ "${RUN_FUN}" == *"d"* ]] && INSTALL_CMD="dnf"
if [[ "${RUN_FUN}" == *"x"* ]]; then

 if [ -x "$(command -v apk)" ]; then
  INSTALL_CMD="apk"
 elif [ -x "$(command -v apt-get)" ]; then
  INSTALL_CMD="apt-get"
 elif [ -x "$(command -v apt)" ]; then
  INSTALL_CMD="apt"
 elif [ -x "$(command -v dnf)" ]; then
  INSTALL_CMD="dnf"
 elif [ -x "$(command -v yum)" ]; then
  INSTALL_CMD="yum"
 # elif [ -x "$(command -v rpm)" ]; then
 #  INSTALL_CMD="rpm"
 else
  echo "Failed to find package manager. exiting!"
  exit 1
 fi
fi

if [[ $RUN_FUN == *"s"* ]]; then
 [[ $RUN_FUN == *"i"* ]] && echo "Using sudo!"
 # TODO
 INSTALL_CMD="sudo ${INSTALL_CMD}"
 # exit
fi

function ex() {
 CMD=$1
 echo "Ex: $CMD"
 RES=$(eval "$CMD")
 echo "res: $RES"
}

function install_cpan() {
 echo "install_cpan"
 # cpan Chocolate::Belgian
}
# TODO ... install_yum, install_dnf, install_rpm, ...

function install() {
 [[ $RUN_FUN == *"i"* ]] && echo "Installing env..."
 # TODO ...
 I_CMD="${INSTALL_CMD} install -y "
 # ex "${INSTALL_CMD} update"
 # https://docs.bitnami.com/installer/faq/linux-faq/administration/install-perl-linux/
 ex "${I_CMD} perl" # apt, fedora, rhel
 # ex "${I_CMD} perl-Data-Dumper" # fedora, rhel
 # ex "${I_CMD} git"
 # ex "${I_CMD} vim"
 # ex "${I_CMD} screen"

 # install additional stuff specific to distro and tool
 [[ "${RUN_FUN}" == *"c"* ]] && install_cpan
}

function prepare() {
 [[ $RUN_FUN == *"p"* ]] && echo "Preparing env..."
 # TODO ...
}

[[ $RUN_FUN == *"i"* ]] && install
[[ $RUN_FUN == *"p"* ]] && prepare

# set +x
#
