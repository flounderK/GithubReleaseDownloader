#!/bin/bash

# from https://wiki.archlinux.org/title/Bash/Functions#Extract
# will fail if extglob is not enabled
extract() {
    local c e i

    (($#)) || return

    for i; do
        c=''
        e=1

        if [[ ! -r $i ]]; then
            echo "$0: file is unreadable: \`$i'" >&2
            continue
        fi

        case $i in
			*.tgz) c=(bsdtar xvf);;
			*.tlz) c=(bsdtar xvf);;
			*.txz) c=(bsdtar xvf);;
			*.tb2) c=(bsdtar xvf);;
			*.tbz) c=(bsdtar xvf);;
			*.tbz2) c=(bsdtar xvf);;
			*.taz) c=(bsdtar xvf);;
			*.tar) c=(bsdtar xvf);;
			*.tar.Z) c=(bsdtar xvf);;
			*.tar.bz) c=(bsdtar xvf);;
			*.tar.bz2) c=(bsdtar xvf);;
			*.tar.gz) c=(bsdtar xvf);;
			*.tar.lzma) c=(bsdtar xvf);;
			*.tar.xz) c=(bsdtar xvf);;
            *.7z)  c=(7z x);;
            *.Z)   c=(uncompress);;
            *.bz2) c=(bunzip2);;
            *.exe) c=(cabextract);;
            *.gz)  c=(gunzip);;
            *.rar) c=(unrar x);;
            *.xz)  c=(unxz);;
            *.zip) c=(unzip);;
            *.zst) c=(unzstd);;
            *)     echo "$0: unrecognized file extension: \`$i'" >&2
                   continue;;
        esac

        command "${c[@]}" "$i"
        ((e = e || $?))
    done
    return "$e"
}


handle_appimage() {

    (($#)) || return

	FILENAME=$(basename -- "$1")
	DIRNAME="/opt/${FILENAME%.*}"
	echo "$DIRNAME"
	mkdir -p "$DIRNAME"
	cp "$1" "$DIRNAME"
	chmod +x "$DIRNAME/$FILENAME"
}


if [ $# -lt 1 ]; then
	echo "Usage: $0 <directory>"
	echo "where <directory> is a directory containing downloaded github release files"
	exit 0

fi

if [ "$EUID" -ne 0 ]; then
	echo "$0: script must be run as root"
	exit
fi

INSTALL_DIR="/opt"

ORGINAL_DIR=$(pwd)
# https://stackoverflow.com/questions/23356779/how-can-i-store-the-find-command-results-as-an-array-in-bash/54561526#54561526 readarray -d '' RELEASE_FILES < <(find "$1" -type f -print0)
FILES_TO_EXTRACT=()

for i in "${RELEASE_FILES[@]}";
do
	# echo "$i"
	case $i in
		*.AppImage)
			handle_appimage "$i"
			continue
			;;
		*.deb)
			dpkg -i "$i"
			continue
			;;
		*)
			FILE_BASE=$(basename -- "$i")
			FILES_TO_EXTRACT+=("$FILE_BASE")
			cp -f "$i" "$INSTALL_DIR/$FILE_BASE"
			# echo "unhandled $i"
			;;
	esac
done

cd "$INSTALL_DIR"
# echo "FILES_TO_EXTRACT"

for i in "${FILES_TO_EXTRACT[@]}";
do
	extract "$i"
	echo "$i"
done

cd "$ORIGINAL_DIR"
