#!/bin/sh

srcdir=/exports/src
# Need the -pegasus suffix or Poudriere uses builtin manifests
# and refuses to use our tarballs
srcvers="releng-14.2:14.2-RELEASE-pegasus"
archs=${1:-"amd64"}

poudriere=/usr/local/bin/poudriere

mktarball() {
	local arch src version
	arch=$1
	src=$2
	version=${src##*/}

	echo Updating $src

	(cd $src && git pull --ff-only)

	echo Making tarballs for $arch from $src

	mkdir -p $arch-tarballs/$version

	echo -n Cleaning before...
	make -C $src/release clean >/dev/null 2>&1
	make -C $src cleandir cleandir >/dev/null 2>&1
	echo "...[DONE]"

	echo -n Making the config file PEGASUS
	sed '/^device[[:space:]]*s[on][ud]/d;s/GENERIC/PEGASUS/;/^options[[:space:]]*VESA/d' \
		$src/sys/amd64/conf/GENERIC \
		> $src/sys/amd64/conf/PEGASUS
	echo "...[DONE]"

	echo -n Building world and kernel...
	make -C $src buildworld buildkernel packages TARGET=$arch \
		>$arch-tarballs/$version/buildlog 2>&1 || \
			tail -n 50 $arch-tarballs/$version/buildlog
	echo "...[DONE]"

	echo -n Building tarballs...
	make -C $src/release -DNOPORTS -DNODOC -DNOPKG TARGET_ARCH=$arch \
		TARGET=$arch ftp >$arch-tarballs/$version/releaselog 2>&1
	echo "...[DONE]"
	rm $arch-tarballs/$version/*.txz
	mv /usr/obj/$src/$arch.$arch/release/*.txz /usr/obj/$src/$arch.$arch/release/ftp/MANIFEST $arch-tarballs/$version/
}

mkpjail() {
	local _jname _version _arch _tarball_dir
	_jname=$1
	_version=$2
	_arch=$3
	_tarball_dir=$4

	if $poudriere jail -l | grep -q $_jname; then
		$poudriere jail -u -j $_jname
	else
		$poudriere jail -c -j $_jname -m url=/root/upgradeall/$_arch-tarballs/$_tarball_dir -v $_version
	fi
}

bulkjail() {
	local _jail _pkglists
	_jail=$1

	_pkglists=$(echo /usr/local/etc/poudriere.d/pkglist-FreeBSD* | sed 's, , -f ,g')

	$poudriere bulk -j $_jail -p default -f $_pkglists
}

if [ ! -e /nobuildeverything ]; then
	touch /nobuildeverything
	buildeverything=yes
	buildports=yes
elif [ ! -e /norebuildports ]; then
	touch /norebuildports
	buildports=yes
fi

for v in ${srcvers}; do
    for a in ${archs}; do
	vdir=${v%:*}
	vver=${v#*:}
	[ -z "$buildeverything" ] || mktarball $a $srcdir/$vdir
	#pjail=$(echo $vdir | sed 's,^[^0-9]*\([0-9]*\)\.\([0-9]*\).*$,\1\2,')$a
	pjail=FreeBSD:$(echo $vdir | sed 's,^[^0-9]*\([0-9]*\)\..*,\1,'):$a
	[ -z "$buildeverything" ] || mkpjail $pjail $vver $a $vdir
	[ -z "$buildports" ] || bulkjail $pjail
    done
done
