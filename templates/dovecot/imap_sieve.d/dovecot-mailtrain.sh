#!/bin/sh

root_dir=/var/spool/mailtrain/

umask 077

case "$1" in
ham)
	add='ham'
	remove='spam'
	;;
spam)
	add='spam'
	remove='ham'
	;;
*)
	exit 1
	;;
esac

# Generate a unique ID for the message while saving to tmp
trap '[ -e "$root_dir/tmp/$$" ] && rm -f "$root_dir/tmp/$$" 2>/dev/null' INT HUP TERM EXIT

sha=$(cat | tee "$root_dir/tmp/$$" | shasum -a 256 | awk '{print $1}')

# Remove file if it already exists in the wrong folder
[ -e "$root_dir/$remove/$sha" ] && rm "$root_dir/$remove/$sha"

# Move tmp file into correct folder
mv "$root_dir/tmp/$$" "$root_dir/$add/$sha"
exit 0
