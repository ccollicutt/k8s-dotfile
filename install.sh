#!/usr/bin/env bash

set -o errexit 

# ensure required commands are avaiable
function check_for_commands(){
  if ! command -v wget &> /dev/null
  then
      log error "wget missing"
      exit 1
  fi
}

function log(){
  local LEVEL=$1
  local MSG=$2

  # only log debug messages if the DEBUG env var is set to true
  if [ "$LEVEL" != "debug" ]; then
    echo "$LEVEL:" "$MSG" 
  elif [ "$DEBUG" = "true" ] && [ "$LEVEL" = "debug" ]; then
    echo "$LEVEL:" "$MSG" 
  fi

  # exit on error message
  if [ "$LEVEL" = "error" ]; then
    echo "exiting..."
    exit 1
  fi
}

function check_os_version(){

  # by default will be false, but script has option to skip
  if ! command -v lsb_release &> /dev/null; then
    log error "lsb_release not found, please install it or use ubuntu bionic or focal"
    exit 1
  fi
  OS_VERSION=$(lsb_release -c -s | tr -d '\n')
  if [[ "$OS_VERSION" != "focal" && "$OS_VERSION" != "bionic" ]]; then
    log error "only tested on ubuntu bionic and focal"
    exit 1
  fi
}

# fix popd/push
pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd > /dev/null
}

# ensure k8sdotfilesrc is sourced in ~/.bashrc
function install_into_bashrc(){
  if ! grep -q "^source $BIN_DIR/k8sdotfilesrc$" ~/.bashrc; then 
    echo "source $BIN_DIR/k8sdotfilesrc" >> ~/.bashrc
  fi
}

# create the bin dir that we put our useful binaries in 
function create_bin_dir() {
  if [[ ! -d "$BIN_DIR" ]]; then 
    mkdir -p "$BIN_DIR"
  fi
}

# install k8sdotfilesrc file 
function install_k8sdotfile(){
  if [[ ! -f "$BIN_DIR"/k8sdotfilesrc ]]; then 
    if cp "$SCRIPT_DIR"/k8sdotfilesrc "$BIN_DIR"/; then
      log debug "copied $SCRIPT_DIR/k8sdotfilesrc to $BIN_DIR/k8sdotfilesrc"
    else 
      log error "failed to copy to bindir"
      exit 1
    fi
  fi
}

# install useful binaries, like helm, into the $BIN_DIR
function install_binaries(){

  if [[ ! -f "$BIN_DIR"/powerline-go ]]; then 
    pushd "$BIN_DIR" || log error "pushd fail"
      wget -q "https://dl.k8s.io/release/v1.20.4/bin/linux/amd64/kubectl"
      chmod 755 kubectl
    popd || log error "pushd fail"
  fi

  if [[ ! -f "$BIN_DIR"/kubectx ]]; then 
    pushd "$TMP_DIR" || log error "pushd fail"
      wget -q https://github.com/ahmetb/kubectx/releases/download/v0.9.3/kubectx_v0.9.3_linux_x86_64.tar.gz
      tar zxf kubectx_v0.9.3_linux_x86_64.tar.gz
      mv kubectx "$BIN_DIR"/
    popd || log error "pushd fail"
  fi 

  if [[ ! -f "$BIN_DIR"/kubens ]]; then 
    pushd "$TMP_DIR" || log error "pushd fail"
      wget -q https://github.com/ahmetb/kubectx/releases/download/v0.9.3/kubens_v0.9.3_linux_x86_64.tar.gz
      tar zxf kubens_v0.9.3_linux_x86_64.tar.gz
      mv kubens "$BIN_DIR"/
    popd || log error "pushd fail"
  fi 

  # install z
  if [[ ! -f "$BIN_DIR"/z.sh ]]; then 
    pushd "$BIN_DIR" || log error "pushd fail"
      wget -q https://raw.githubusercontent.com/rupa/z/master/z.sh
    popd || log error "pushd fail"
  fi

  if [[ ! -f "$BIN_DIR"/helm ]]; then 
    pushd "$TMP_DIR" || log error "pushd fail"
      HELM_FILE=helm-v3.5.3-linux-amd64.tar.gz
      wget -q "https://get.helm.sh/$HELM_FILE"
      tar zxf "$HELM_FILE"
      mv linux-amd64/helm "$BIN_DIR"/
    popd || log error "pushd fail"
  fi

  if [[ ! -f "$BIN_DIR"/kustomize ]]; then 
    pushd "$TMP_DIR" || log error "pushd fail"
      wget -q https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.0.5/kustomize_v4.0.5_linux_amd64.tar.gz
      tar zxf kustomize_v4.0.5_linux_amd64.tar.gz
      mv kustomize "$BIN_DIR"/
    popd || log error "pushd fail"
  fi

  if [[ ! -f "$BIN_DIR"/powerline-go ]]; then 
    pushd "$BIN_DIR" || log error "pushd fail"
      wget -q https://github.com/justjanne/powerline-go/releases/download/v1.21.0/powerline-go-linux-amd64 \
        -O powerline-go
      chmod 755 powerline-go
    popd || log error "pushd fail"
  fi

  if [[ ! -f "$BIN_DIR"/kube-ps1.sh ]]; then 
    pushd "$BIN_DIR" || log error "pushd fail"
      wget -q https://raw.githubusercontent.com/jonmosco/kube-ps1/master/kube-ps1.sh
    popd || log error "pushd fail"
  fi

  # make it easy to import kubeconfigs into your main kubeconfig
  if [[ ! -f "$BIN_DIR"/konfig ]]; then 
    pushd "$BIN_DIR" || log error "pushd fail"
      wget -q https://raw.githubusercontent.com/corneliusweig/konfig/master/konfig
      chmod 755 konfig
    popd || log error "pushd fail"
  fi

  # make it really easy to figure out who you are...
  if [[ ! -f "$BIN_DIR"/kubectl-whoami ]]; then 
    pushd "$TMP_DIR" || log error "pushd fail"
      wget -q https://github.com/rajatjindal/kubectl-whoami/releases/download/v0.0.35/kubectl-whoami_v0.0.35_linux_amd64.tar.gz
      tar zxf kubectl-whoami_v0.0.35_linux_amd64.tar.gz
      mv kubectl-whoami "$BIN_DIR"/
    popd || log error "pushd fail"
  fi

  # dive - look at what is in container images
  if [[ ! -f "$BIN_DIR"/dive ]]; then 
    pushd "$TMP_DIR" || log error "pushd fail"
      wget -q https://github.com/wagoodman/dive/releases/download/v0.10.0/dive_0.10.0_linux_amd64.tar.gz
      tar zxf dive_0.10.0_linux_amd64.tar.gz
      mv dive "$BIN_DIR"/
      chmod 755 "$BIN_DIR"/dive
    popd || log error "pushd fail"
  fi

  # carvel tools
  if [[ ! -f "$BIN_DIR"/ytt ]]; then 
    pushd "$TMP_DIR" || log error "pushd fail"
      wget -q https://github.com/vmware-tanzu/carvel-ytt/releases/download/v0.31.0/ytt-linux-amd64
      mv ytt-linux-amd64 "$BIN_DIR"/ytt
      chmod 755 "$BIN_DIR"/ytt
    popd || log error "pushd fail"
  fi

  if [[ ! -f "$BIN_DIR"/kbld ]]; then 
    pushd "$TMP_DIR" || log error "pushd fail"
      wget -q https://github.com/vmware-tanzu/carvel-kbld/releases/download/v0.29.0/kbld-linux-amd64
      mv kbld-linux-amd64 "$BIN_DIR"/kbld
      chmod 755 "$BIN_DIR"/kbld
    popd || log error "pushd fail"
  fi

  if [[ ! -f "$BIN_DIR"/kapp ]]; then 
    pushd "$TMP_DIR" || log error "pushd fail"
      wget -q https://github.com/vmware-tanzu/carvel-kapp/releases/download/v0.36.0/kapp-linux-amd64
      mv kapp-linux-amd64 "$BIN_DIR"/kapp
      chmod 755 "$BIN_DIR"/kapp
    popd || log error "pushd fail"
  fi

  if [[ ! -f "$BIN_DIR"/imgpkg ]]; then 
    pushd "$TMP_DIR" || log error "pushd fail"
      wget -q https://github.com/vmware-tanzu/carvel-imgpkg/releases/download/v0.5.0/imgpkg-linux-amd64
      mv imgpkg-linux-amd64 "$BIN_DIR"/imgpkg
      chmod 755 "$BIN_DIR"/imgpkg
    popd || log error "pushd fail"
  fi

  if [[ ! -f "$BIN_DIR"/vendir ]]; then 
    pushd "$TMP_DIR" || log error "pushd fail"
      wget -q https://github.com/vmware-tanzu/carvel-vendir/releases/download/v0.17.0/vendir-linux-amd64
      mv vendir-linux-amd64 "$BIN_DIR"/vendir
      chmod 755 "$BIN_DIR"/vendir
    popd || log error "pushd fail"
  fi

  # kubectl-tree
  log debug "installing kubectl-tree"
  if [[ ! -f "$BIN_DIR"/kubectl-tree ]]; then 
    pushd "$TMP_DIR" || log error "pushd fail"
      wget -q https://github.com/ahmetb/kubectl-tree/releases/download/v0.4.0/kubectl-tree_v0.4.0_linux_amd64.tar.gz
      tar zxf kubectl-tree_v0.4.0_linux_amd64.tar.gz
      mv kubectl-tree "$BIN_DIR"/
      chmod 755 "$BIN_DIR"/kubectl-tree
    popd || log error "pushd fail"
  fi

  #skaffold
  if [[ ! -f "$BIN_DIR"/skaffold ]]; then 
    pushd "$TMP_DIR" || log error "pushd fail"
      wget -q https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
      mv skaffold-linux-amd64 "$BIN_DIR"/skaffold
      chmod 755 "$BIN_DIR"/skaffold
    popd || log error "pushd fail"
  fi

  # kind
  if [[ ! -f "$BIN_DIR"/kind ]]; then 
    pushd "$TMP_DIR" || log error "pushd fail"
      wget -q https://kind.sigs.k8s.io/dl/v0.10.0/kind-linux-amd64
      mv kind-linux-amd64 "$BIN_DIR"/kind
      chmod 755 "$BIN_DIR"/kind
    popd || log error "pushd fail"
  fi

}

function install_packages(){
  if ! dpkg -l fonts-powerline > /dev/null; then
    if [[ $EUID -ne 0 ]]; then
      # user is not root, use sudo
      sudo apt update
      sudo apt install -y fonts-powerline
    else
      # user is root
      apt update
      apt install -y fonts-powerline
    fi
  fi
}

function cleanup_tmp(){
  rm -rf "$TMP_DIR"
}
trap cleanup_tmp EXIT

# 
# main
#

run_main() {

  # only run these if skip check is false
  if [ "$SKIP_OS_CHECK" != "true" ]; then
    check_os_version
    install_packages
  fi
  check_for_commands
  log info "creating ~/.k8s-dotfiles directory"
  create_bin_dir
  log info "installing useful binaries"
  install_binaries
  log info "installing k8sdotfilerc"
  install_k8sdotfile
  log info "adding sourcing to ~/.bashrc"
  install_into_bashrc

  echo "***********************************************************************"
  echo "* Now run ~/.bashrc to setup the prompt and start using k8s-dotprofile "
  echo "***********************************************************************"

}

# 
# vars 
# 

readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
readonly DOT_DIR="$HOME/.k8s-dotfiles"
readonly BIN_DIR="$DOT_DIR/bin"
# tmpdir
readonly TMP_DIR=$(mktemp -d -t k8s-dotfiles-XXXXXXXXXX)
SKIP_OS_CHECK=false

while getopts ":hs" opt; do
  case ${opt} in
    h ) echo "install.sh [-h for help] [-s skip OS check]"
        exit 0
      ;;
    s ) SKIP_OS_CHECK=true
        log info "skipping os checks"
      ;;
    \? ) log error "invalid option"
        exit 1
      ;;
  esac
done

# only run main if running from scripts not testing with bats
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  run_main
fi