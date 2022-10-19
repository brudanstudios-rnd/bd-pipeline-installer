#!/bin/bash

terminalColorClear='\033[0m'
terminalColorEmphasis='\033[1;32m'
terminalColorError='\033[1;31m'
terminalColorMessage='\033[1;33m'
terminalColorWarning='\033[1;34m'

echoDefault() {
    echo -e "${terminalColorClear}$1${terminalColorClear}"
}
 
echoMessage() {
    echo -e "${terminalColorMessage}$1${terminalColorClear}"
}
 
echoWarning() {
    echo -e "${terminalColorWarning}$1${terminalColorClear}"
}
 
echoError() {
    echo -e "${terminalColorError}$1${terminalColorClear}"
}

current_script=${BASH_SOURCE:-$0}
current_dir="$(cd -P "$(dirname "${current_script}")" && pwd)"

export PIPELINE_ROOT="$HOME/bd-pipeline"

if [[ -d "$PIPELINE_ROOT" ]]; then
    echoError "[Error] Pipeline is already installed into \"${PIPELINE_ROOT}\" directory."
    exit 1
fi

ssh_key=~/.ssh/bd-ppl_rsa

if [[ ! -f "$ssh_key" ]]; then
    ssh-keygen -t ed25519 -f $ssh_key -q -N ""
fi

public_ssh_key_content="$(cat $ssh_key.pub)"

echo
echoError "$public_ssh_key_content"
echo

echoMessage "Your Public SSH key was printed ABOVE."
echoMessage "Please copy it, send to the Administrator, and wait for the APPROVAL to proceed."

echo

read -p "Have you received the Approval to proceed? [yes/no] " reply
reply_lower=$(echo "$reply" | tr '[:upper:]' '[:lower:]')

if [[ "$reply_lower" != "yes" ]]; then
    exit 1
fi

GIT_SHH_COMMAND="ssh -i ${ssh_key} -o IdentitiesOnly=yes"

git clone --depth 1 git@github.com:brudanstudios-rnd/bd-pipeline.git $PIPELINE_ROOT

if [ $? -eq 0 ]; then
    exit $?
fi

unset GIT_SHH_COMMAND

search_string='# -- bd-pipeline activation section --'
data_string="# -- bd-pipeline activation section --\nexport BD_PIPELINE_ROOT=$PIPELINE_ROOT\nalias bd-activate=$PIPELINE_ROOT/activate.sh"

foreach init_file ( "$HOME/.bashrc" "$HOME/.bash_profile" )
  grep -qxF $search_string $init_file || echo -e $data_string >> $init_file
end

echoMessage "Successfuly installed BD Remote Pipeline."