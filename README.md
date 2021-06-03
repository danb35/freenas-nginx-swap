# Work in progress, use at your own risk

This script was written to address kind of a niche situation.  I have a [local certificate authority](https://smallstep.com/blog/build-a-tiny-ca-with-raspberry-pi-yubikey/) running at home, and I was wanting to get certificates for my TrueNAS server from that CA using HTTP validation.  That requires your server to serve a challenge file at `http://your_fqdn/.well-known/acme-challenge/something`, and the TrueNAS web UI conflicts with this.  To make issuance possible, this script replaces the TrueNAS Nginx config file with a temporary configuration, issues the cert, and then restores the previous configuration.

## Installation
Change to a convenient directory on your TrueNAS server and run `https://github.com/danb35/freenas-nginx-swap`

## Configuration
Change to the script's directory and create a configuration file called `nginx-swap-config`.  In its most minimal form, it will look like this:
```
CA_URL="https://ca.internal/acme/acme/directory"
CA_CERT_PATH="/path/to/root_ca.crt"
```
Available options are:
* CA_URL: Mandatory.  The complete URL to the ACME endpoint on your local CA.
* CA_CERT_PATH: Mandatory.  Path to the local CA's root certificate.
* ACME_SH_PATH: Optional.  Path to the `acme.sh` script.  Defaults to `/root/.acme.sh/acme.sh`.
* FREENAS_FQDN: Optional.  Defaults to the FQDN configured for your TrueNAS server.

## Execution
Run the script.  It will back up nginx.conf, replace it with the temporary config, call acme.sh to issue the cert, and then replace nginx.conf with the backed-up version.  **Note:** This script doesn't do anything to deploy the new cert--you may want to investigate [deploy-freenas](https://github.com/danb35/deploy-freenas) for that purpose.