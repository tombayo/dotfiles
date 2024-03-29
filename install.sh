#!/bin/bash

###
### Mainly copied from https://github.com/TechDufus/dotfiles
### Credits to TechDufus
###

# color codes
LBLACK='\033[01;30m'
LRED='\033[01;31m'
LGREEN='\033[01;32m'
OVERWRITE='\e[1A\e[K'

# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html#index-set
set -e

# Paths
DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_LOG="$HOME/.dotfiles.log"
GIT_REPO_URL="https://github.com/tombayo/dotfiles.git"
ANSIBLE_MAIN_PLAYBOOK="$DOTFILES_DIR/main.yml"
ANSIBLE_GALAXY_REQUIREMENTS="$DOTFILES_DIR/requirements.yml"

# _header colorize the given argument with spacing
function _task {
  # if _task is called while a task was set, complete the previous
  if [[ $TASK != "" ]]; then
    _task_done
  fi
  # set new task title and print
  TASK=$1
  printf "${LBLACK} [ ]  ${TASK} \n${LRED}"
}

# _cmd performs commands with error checking
function _cmd {
  #create log if it doesn't exist
  if ! [[ -f $DOTFILES_LOG ]]; then
    touch "$DOTFILES_LOG"
  fi
  # empty conduro.log
  echo "" > "$DOTFILES_LOG"
  # hide stdout, on error we print and exit
  if eval "$1" 1> /dev/null 2> "$DOTFILES_LOG"; then
    return 0 # success
  fi
  # read error from log and add spacing
  printf "${OVERWRITE}${LRED} [X]  ${TASK}${LRED}\n"
  while read line; do
    printf "      ${line}\n"
  done < "$DOTFILES_LOG"
  printf "\n"
  # remove log file
  rm "$DOTFILES_LOG"
  # exit installation
  exit 1
}

function _task_done {
  printf "${OVERWRITE}${LGREEN} [✓]  ${LGREEN}${TASK}\n"
  TASK=""
}

function install_ansible() {
  _task "Installing Ansible"
  if ! dpkg -s ansible >/dev/null 2>&1; then
    _cmd "sudo apt-get update"
    _cmd "sudo apt-get install -y ansible"
  fi
}

function update_ansible_galaxy() {
  _task "Updating Ansible Galaxy"
  _cmd "ansible-galaxy install -r $ANSIBLE_GALAXY_REQUIREMENTS"
}

if ! [[ -d "$DOTFILES_DIR" ]]; then
  _task "Cloning repository"
  _cmd "git clone --quiet $GIT_REPO_URL $DOTFILES_DIR"
else
  _task "Updating repository"
  _cmd "git -C $DOTFILES_DIR pull --quiet"
fi

install_ansible
update_ansible_galaxy

_task "Running playbook"; _task_done
ansible-playbook "$ANSIBLE_MAIN_PLAYBOOK"
