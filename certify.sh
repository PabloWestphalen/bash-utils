#!/bin/bash

set -e

ALIAS=`hostname`
PASS=123456
MODE=0
JKS=false
CACERTS_PASS=changeit
VALID_DAYS=3650
JBOSS=""

check_alias() {
	if [[ ! -n "$ALIAS" ]]; then
		echo "alias is required, define your hostname or provide one with --alias"
		exit 1
	fi
} 

install_in_all_jres() {
	check_alias
	
	echo "finding java installations (can take a while)..."
	#TODO find a faster way to list java installations to all jres
	ALL_CACERTS=`sudo find / -wholename "*/lib/security/cacerts" | sort -u`
	echo "$ALL_CACERTS"
	for java_cacerts in $ALL_CACERTS
	do
		echo "installing certificate to $java_cacerts..."
		sudo keytool -import -noprompt -trustcacerts -alias $ALIAS -file ~/cacerts/$ALIAS.cer -keystore $java_cacerts -storepass $CACERTS_PASS
		echo "NOTE: you can verify that the certificate was added correctly to this installation with the command:"
		echo "keytool -list -keystore $java_cacerts -storepass $CACERTS_PASS | grep $ALIAS"
	done
}

while test $# -gt 0
do
    case "$1" in
    	--help)
    		echo "full example:"
    		echo "$0 --alias foo --pass 123456 --jks --cacerts-pass 123456 --jboss /jboss/home"
    		echo "examplo apenas instalação:"
    		echo "$0 --alias foo --cacerts-pass 123456 --install"
    		exit 0
    	;;		
		--alias|-a) shift
			ALIAS=$1
			echo "defined alias as $ALIAS"
        ;;
		--pass|p) shift
			PASS=$1			
        ;;
        --jks)
        	JKS=true
        ;;
        --validity) shift
        	VALID_DAYS=$1
        ;;        
        --cacerts-pass) shift
        	CACERTS_PASS=$1
        ;;
        --jboss) shift
        	JBOSS=$1
        ;;
        --install|-i) 
	        install_in_all_jres
        	exit 0
        ;;
		--*) echo "bad option $1"
			exit 1
        ;;
    esac
    shift
done

check_alias

mkdir -p ~/cacerts

echo "using alias '$ALIAS' and password '$PASS'..."

echo "generating certificate and keystore..."
keytool -genkey -alias $ALIAS -keyalg RSA -validity $VALID_DAYS -keystore ~/cacerts/$ALIAS.keystore -storepass $PASS -keypass $PASS -dname "CN=$ALIAS, OU=CONTEXPRESS, O=MURAH, L=SAOPAULO, ST=SP, C=BR"

echo "exporting certificate to keystore..."
keytool -export -alias $ALIAS -keystore ~/cacerts/$ALIAS.keystore -storepass $PASS -file ~/cacerts/$ALIAS.cer

if [ "$JKS" == "true" ]; then
	echo "generating jks..."
	keytool -import -file ~/cacerts/$ALIAS.cer -alias $ALIAS -keystore $ALIAS.jks
fi

if [[ -n "$JBOSS" ]]; then
	mkdir -p "$JBOSS/cacerts"
	cp ~/cacerts/$ALIAS.keystore "$JBOSS/cacerts"
	echo "<!-- HTTPS -->
   	<Connector port=\"8443\" protocol=\"HTTP/1.1\" SSLEnabled=\"true\"
       maxThreads=\"1500\" scheme=\"https\" secure=\"true\"
       clientAuth=\"false\" sslProtocol=\"TLS\"
       address=\"\${jboss.bind.address}\" strategy=\"ms\"
       keystoreFile=\"$JBOSS/cacerts/$ALIAS.keystore\"
       keystorePass=\"$PASS\" />" > ~/cacerts/server.xml.snippet
    echo "connector template for Jboss created in ~/cacerts/server.xml.snippet"
fi

install_in_all_jres

echo "testing alias conectivity..."
ping -c 3 $ALIAS
