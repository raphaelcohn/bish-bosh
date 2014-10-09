bish-bosh
=========

MQTT bash client

## Download and Installation
bish-bosh can be used simply by cloning from github. In a terminal window, type:-

    git clone git@github.com:raphaelcohn/bish-bosh.git

In the newly created folder `bish-bosh`, is a binary `bish-bosh`. It's ready to use straightaway. Just type `bish-bosh` to connect to a local MQTT server. To connect to a remote server, use `bish-bosh --server SERVER`, where `SERVER` can be a host name, IPv4 or IPv6 address. Of course, that might not work 100% for you; bish-bosh requires a number of common binaries to be on the PATH. It will try to install them if missing, if it recognises your package manager or Linux distribution.

* You can't copy the script `bish-bosh` anywhere else and just use it; this is because it depends 

### Gotchas


## Dependencies
bish-bosh tries to use as few dependencies as possible, but, since this is shell script, that's not always possible. It's compounded by the need to support the difference between major shells, too. It also does its best to work around differences in common binaries, by using feature detection, and where it can't do any better, by attempting to install using your package manager.

### Required
  * mkdir
  * mkfifo
  * mv
  * rm
  * rmdir

### Either Or
These are listed in preference order.

  * Binary to Hexadecimal conversion
    * hexdump (preferred)
    * od (GNU coreutils, but GNU preferred)
  * Turning off buffering
	* stdbuf (part of GNU coreutils; also present in FreeBSD) or unbuffer (part of expect)
  * unbuffer
  * dd (used if stdbuf or unbuffer not available)
* Optional
  * `iconv` (BSD derived or GNU glibc derived)

### Supported Operating Systems and Linux Distributions
To be effective

## Supported Shells
bish-bosh tries very hard to make sure it works under any POSIX-compliant shell. However, in practice, that's quite hard to do; many features on the periphery of POSIX compliance, are subtly different (eg signal handling during read). That can lead to a matrix of pain. We constrain the list to widely-used shells common in the sorts of places you'd want to use bish-bosh: system administration, one-off scripting, boot-time and embedded devices with no compiler toolchain. Consequently, we test against:-

* [Almquist-derived](https://en.wikipedia.org/wiki/Almquist_shell) shells, particularly
  * [DASH](http://gondor.apana.org.au/~herbert/dash/)
  * [BusyBox](http://www.busybox.net/downloads/BusyBox.html)'s ash
 * [GNU Bash](https://www.gnu.org/software/bash/bash.html)

All of these shells support dynamically-scoped `local` variables, something we make extensive use of. Some of them also support read timeouts, which is essential for making

### KornShell
We try hard to maintain some compatibility with KornShell ksh88 derivatives; bish-bosh may work under [mksh] or [pdksh]() (although the latter hasn't been actively updated since 1999). At this time, [ksh93] is known not to work. Any help g

 Additionally, Where possible,  that support local variables. Where a shell provides a more efficient implementation, that can  Primary  (, ) and . (developed on Mac OS X

### Others

pdksh
osh
yash
mkdsh
ksh93
ksh88
