#!/bin/bash
AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:9.0.1) Gecko/20100101 Firefox/9.0.1"
VERBOSE="-v"

COOKIE="./cookies.txt"

if [ ! -f $COOKIE ]; then 
	echo "please get cookies.txt here"
	exit -1
fi

function urldown {
	while read ; do
		NAME=$(echo $REPLY |perl -F'\s+' -ane 'print $F[0]')
		URL=$(echo $REPLY |perl -F'\s+' -ane 'print $F[1]' |sed -e 's/\s//g')
		curl -C - -o "$NAME" -L -b $COOKIE -A "$AGENT" $VERBOSE "$URL"
	done
}

function page {
	URL=$1
	TMP="./page.html"
#	echo "[INFO] Get Index Page ... "
	curl -s -b $COOKIE -o "$TMP" -L -A "$AGENT" "$URL"
	
	IFS=$'\x0A'$'\x0D'
	for ii in $(./xunlei_parser.pl -p $TMP); do
		NAME=$(echo $ii |perl -F'\t' -ane 'print $F[0]')
		URL=$(echo $ii |perl -F'\t' -ane 'print $F[1]' |sed -e 's/\s*$//g')
		if echo $URL |grep 'dynamic' &>/dev/null; then
			JTMP="d.json"
#			echo "[INFO] Open $NAME to get download URL"
			curl -s -o "$JTMP" -L -b $COOKIE -A "$AGENT" $URL
			./xunlei_parser.pl -j $JTMP
		else
			echo -e "$NAME\t$URL"
		fi
	done
}



while [ $# -gt 0 ]; do
	case "$1" in
	-u)
		urldown
		;;
	-p)
		shift
		page "$1"
		;;
	esac
	shift
done
