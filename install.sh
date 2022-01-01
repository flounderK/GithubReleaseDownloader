#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

mkdir -p "$HOME/.local/bin"

if [ -e "$SCRIPT_DIR/requirements.txt" ];then
	pip install -r "$SCRIPT_DIR/requirements.txt"
fi

install "$SCRIPT_DIR/github_release_downloader.py" "$HOME/.local/bin"
install "$SCRIPT_DIR/github_release_installs.sh" "$HOME/.local/bin"
install "$SCRIPT_DIR/install_opt_symlinks.sh" "$HOME/.local/bin"
