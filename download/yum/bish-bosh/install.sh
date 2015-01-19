#!/usr/bin/env sh
set -e
set -u

repoFilePath='/etc/yum.repos.d/bish-bosh.repo'
repoFileContent='[bish-bosh]
name=bish-bosh
#baseurl=https://raphaelcohn.github.io/bish-bosh/download/yum/bish-bosh
mirrorlist=https://raphaelcohn.github.io/bish-bosh/download/yum/bish-bosh/mirrorlist
gpgkey=https://raphaelcohn.github.io/bish-bosh/download/yum/bish-bosh/RPM-GPG-KEY-bish-bosh
gpgcheck=1
enabled=1
protect=0'

if [ -t 1 ]; then
	printf '%s\n' "This script will install the yum repository 'bish-bosh'" "It will create or replace '$repoFilePath', update yum and display all packages in 'bish-bosh'." 'Press the [Enter] key to continue.'
	read -r garbage
fi

printf '%s' "$repoFileContent" | sudo -p "Password for %p is required to allow root to install '$repoFilePath': " tee "$repoFilePath" >/dev/null
sudo -p "Password for %p is required to allow root to update yum cache: " yum --quiet makecache
yum --quiet info bish-bosh 2>/dev/null
