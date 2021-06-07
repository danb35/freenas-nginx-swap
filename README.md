# Work in progress, use at your own risk

This script was written to address kind of a niche situation.  I have a [local certificate authority](https://smallstep.com/blog/build-a-tiny-ca-with-raspberry-pi-yubikey/) running at home, and I was wanting to get certificates for my TrueNAS server from that CA using HTTP validation.  That requires your server to serve a challenge file at `http://your_fqdn/.well-known/acme-challenge/something`, and the TrueNAS web UI conflicts with this.  To make issuance possible, this script replaces the TrueNAS Nginx config file with a temporary configuration, issues the cert, and then restores the previous configuration.

## Installation
Change to a convenient directory on your TrueNAS server and run `git clone https://github.com/danb35/freenas-nginx-swap`

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

For debugging purposes, add the `-d` flag (`./nginx-swap -d`).  This will run `acme.sh` with the `--debug` option.

## Troubleshooting
If you interrupt this script, you may leave your Free/TrueNAS system with the temporary Nginx configuration file, which will break the web UI and API.  If you're getting 403 errors when trying to reach the UI, this has probably happened.  To confirm, check `/usr/local/etc/nginx/nginx.conf`.  If you don't see these first few lines:

```
#
#    FreeNAS nginx configuration file
#
```
...then this has happened to you.  **Do not run the script again.**  You should be able to restore nginx.conf from its backup; take a look at `/usr/local/etc/nginx/nginx.conf.bak` to see if it has this header.  If it does, just do `cp /usr/local/etc/nginx/nginx.conf.bak /usr/local/etc/nginx/nginx.conf` followed by `service nginx reload`.

If the backup file also does not have the header above, simply reboot the machine--the nginx.conf file will be regenerated at that time.
