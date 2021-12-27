#!/bin/bash

# from https://wiki.archlinux.org/title/Bash/Functions#Extract
# will possibly fail if extglob is not enabled
# TODO: disable overwrite on all
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
			*.tgz) c=(bsdtar -k xvf);;
			*.tlz) c=(bsdtar -k xvf);;
			*.txz) c=(bsdtar -k xvf);;
			*.tb2) c=(bsdtar -k xvf);;
			*.tbz) c=(bsdtar -k xvf);;
			*.tbz2) c=(bsdtar -k xvf);;
			*.taz) c=(bsdtar -k xvf);;
			*.tar) c=(bsdtar -k xvf);;
			*.tar.Z) c=(bsdtar -k xvf);;
			*.tar.bz) c=(bsdtar -k xvf);;
			*.tar.bz2) c=(bsdtar -k xvf);;
			*.tar.gz) c=(bsdtar -k xvf);;
			*.tar.lzma) c=(bsdtar -k xvf);;
			*.tar.xz) c=(bsdtar -k xvf);;
            *.7z)  c=(7z x);;  # requires handling of overwrite
            *.Z)   c=(uncompress);; # requires handling of overwrite
            *.bz2) c=(bunzip2);;
            *.exe) c=(cabextract);;
            *.gz)  c=(gunzip);; # requires handling of overwrite
            *.rar) c=(unrar x);; # requires handling of overwrite
            *.xz)  c=(unxz);;
            *.zip) c=(unzip -n);;
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
# https://stackoverflow.com/questions/23356779/how-can-i-store-the-find-command-results-as-an-array-in-bash/54561526#54561526
readarray -d '' RELEASE_FILES < <(find "$1" -type f -print0)

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
			command -v dpkg >/dev/null && dpkg -i "$i"
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
	sync
	rm "$i"
	echo "$i"
done

cd "$ORIGINAL_DIR"
