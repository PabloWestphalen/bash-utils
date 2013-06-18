#!/bin/bash -e

do_help() {
	echo "Usage: "
}

# This will fill pixels similar in color to the pixel at x=0 and y=0. We use a fuzz setting of 1% to make colors similar to the background transparent.
#
# This method works best on uniform backgrounds and objects with clear boundaries that make it stand out from the background.
#
# Reference:
# http://www.imagemagick.org/Usage/morphology/#intro
do_remove_bg() {
	file="$1"
	convert "$file" -fill none -fuzz 1% -draw 'matte 0,0 floodfill' -flop  -draw 'matte 0,0 floodfill' -flop "$file"
}

do_remove_bg_collection() {
	pattern=$1
	for f in $pattern
	do
		do_remove_bg "$f"
	done
}

do_trim() {
	file="$1"
	convert -trim "$file" "$file"
}

do_trim_collection() {
	pattern=$1
	for f in $pattern
	do
		do_trim "$f"
	done
}

while test $# -gt 0
do
    case "$1" in
	--help|-h)
	    do_help
	    exit 0
	;;
    --trim) shift
	    do_trim "$1"
    ;;
	--trim-all) shift
	    do_trim_collection "$1"
	;;
    --rm-bg) shift
	    do_remove_bg "$1"
    ;;
    --*) echo "bad option $1"
    ;;
    esac
    shift
done

exit 0
