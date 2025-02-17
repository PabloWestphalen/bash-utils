#!/bin/bash

if [ ! -n "$JAVA_HOME" ]; then
	echo "JAVA_HOME must be defined"
	exit 1
fi

HOST=$1
if [ ! -n "$1" ]; then
	echo "first arg must be the host, followed by port on 2nd arg (if not specified, 443 is considered"
	exit 1
fi

echo "JAVA_HOME=$JAVA_HOME"

existing=$(keytool -list -keystore "$JAVA_HOME/jre/lib/security/cacerts" -storepass changeit | grep $HOST)
if [[ "$existing" == *${HOST}* ]]; then
	echo "a certificate for $HOST already exists, do you want to remove it? [Y/n]"
	echo "$existing"
	read remove

	if [[ "${remove,,}" != 'n' ]]; then
		echo "removing certificate for $HOST"
		sudo keytool -delete -alias $HOST -keystore "$JAVA_HOME/jre/lib/security/cacerts" -storepass changeit
	else
		exit 0
	fi
fi

PORT=${2:-443}
KEYSTOREFILE="$JAVA_HOME/jre/lib/security/cacerts"
KEYSTOREPASS=changeit

echo "getting $HOST:$PORT..."

# get the SSL certificate
openssl s_client -connect ${HOST}:${PORT} </dev/null \
    | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ${HOST}.cert

# create a keystore and import certificate
sudo keytool -import -noprompt -trustcacerts \
    -alias ${HOST} -file ${HOST}.cert \
    -keystore ${KEYSTOREFILE} -storepass ${KEYSTOREPASS}

echo ""
echo "certificate details:"
keytool -list -keystore "$JAVA_HOME/jre/lib/security/cacerts" -storepass changeit | grep $HOST
