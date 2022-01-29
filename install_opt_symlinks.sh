#!/bin/bash


if [ $# -lt 2 ]; then
    echo "Usage: $0 <pattern> <linkname>"
	echo "Creates symlinks in /opt directory from versioned directories to genericly named directories"
    echo "where <pattern> is a pattern that will match the name of the target directory and "
	echo "where <linkname> is the name of the new link that will be installed"
	echo ""
	echo "E.g.: $0 'ghidra' 'ghidra' would create a new link /opt/ghidra that points to "
	echo "an existing directory /opt/ghidra_10.1.1_PUBLIC (assuming it was the last modified "
	echo "directory that matches the pattern 'ghidra')."
	echo ""
	echo "Uses the last modified time of matching directories to determine which one should be linked."
	echo "As a result, if the directory was unzipped into /opt, the script will often automatically"
	echo "link to the newest release"
    exit 0

fi

if [ "$EUID" -ne 0 ]; then
    echo "$0: script must be run as root"
    exit
fi


INSTALL_DIR="/opt"
# find dirs in install dir and sort by date
SORTED_DIRS=$(find "$INSTALL_DIR" -maxdepth 1 -mindepth 1 -type d -printf "%T+ %p\n" | sort -r | cut -d ' ' -f2)

# 1 is match
# 2 is linkname
TARGET=$(echo "$SORTED_DIRS" | grep --color=never -i "$1" | head -n1)
LINK="$INSTALL_DIR/$2"
if [ -L "$LINK" ]; then
	echo "Found old link, removing it"
	rm "$LINK"
fi

echo "target $TARGET"
echo "link $LINK"
ln -f -s "$TARGET" "$LINK"
