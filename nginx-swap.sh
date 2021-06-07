#!/bin/sh
# Swap nginx.conf on a running FreeNAS/TrueNAS system for a limited, temporary one
# In order to obtain a certificate using ACME HTTP validation
# https://github.com/danb35/freenas-nginx-swap

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

#####
#
# General configuration
#
#####

# Initialize defaults
ACME_SH_PATH="/root/.acme.sh/acme.sh"
ACME_SH_ARGS=""
FREENAS_FQDN=$(hostname -f)
CONFIG_NAME="nginx-swap-config"

# Check for debug flag
while getopts ":d" o; do
	case "${o}" in
		d)
			ACME_SH_ARGS="--debug"
			;;
		*)
			echo "Usage: $0 [-d]"
			exit 1
	esac
done

# Check for nginx-swap-config and set configuration
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
if ! [ -e "${SCRIPTPATH}"/"${CONFIG_NAME}" ]; then
  echo "${SCRIPTPATH}/${CONFIG_NAME} must exist."
  exit 1
fi
. "${SCRIPTPATH}"/"${CONFIG_NAME}"

#####
#
# Input/Config Sanity checks
#
#####

# Check that necessary variables were set by nextcloud-config
if [ -z "${CA_URL}" ]; then
  echo 'Configuration error: CA_URL must be set'
  exit 1
fi

if [ -z "${CA_CERT_PATH}" ]; then
  echo 'Configuration error: CA_CERT_PATH must be set'
  exit 1
fi

# Check the existing nginx.conf, make sure it's the FreeNAS file
if ! grep 'FreeNAS\|TrueNAS' /usr/local/etc/nginx/nginx.conf
then
	echo "nginx.conf appears to have been modified, aborting."
	exit 1
fi

# Back up nginx.conf
cp -f /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf.bak

# Create new nginx.conf
cat <<__EOF__ >/usr/local/etc/nginx/nginx.conf

# 
# Temporary nginx configuration file
# This file should only be used while obtaining a cert from
# an ACME certificate authority
# 

user www www;
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

  server {
    listen 80;
    server_name localhost;
    root /tmp;
    error_page 500 502 504 /50X.html;

    location ^~ / {
      deny all;
    }

    location ^~ /.well-known/acme-challenge/ {
      allow all;
    }

  }
}
__EOF__

# Use new configuration
service nginx reload

# Issue the cert
"${ACME_SH_PATH}" "${ACME_SH_ARGS}" --issue --force -w /tmp \
  -d "${FREENAS_FQDN}" \
  --server "${CA_URL}" \
  --ca-bundle "${CA_CERT_PATH}"
  
# Restore nginx.conf and reload
cp -f /usr/local/etc/nginx/nginx.conf.bak /usr/local/etc/nginx/nginx.conf
service nginx reload
