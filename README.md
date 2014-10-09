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
All of these should be present even on the most minimal system. Usage is restricted to those flags known to work.

* `mkdir`
* `mkfifo`
* `touch`
* `mv`
* `rm`
* `rmdir`
* `tr`
* `cat`
* `sed`, any POSIX-compliant version. busybox has been tested against MacOSX sed, GNU sed and BusyBox sed.
* `grep`, any POSIX-compliant version. busybox has been tested against MacOSX grep, GNU grep and BusyBox grep.

### Either Or
These are listed in preference order. Ordinarily, bish-bosh uses the PATH and feature detection to try to find an optimum dependency. Making some choices, however, influences others (eg `hexdump` and `od` preferences change when `stdbuf` is discovered, to try to use GNU `od`). Some choices are sub-optimal, and may cause operational irritation (mostly, bishbosh responds far more slowly to signals and socket disconnections).

* Binary to Hexadecimal conversion
  * `hexdump`, BSD-derived (part of the `bsdmainutils` packages in Debian/Ubuntu; usually installed by default)
  * `hexdump`, in BusyBox
  * `hexdump`, in Toybox
  * `od`, from GNU `coreutils` package
  * `od`, in BusyBox
  * `od`, in Toybox
  * `od`, BSD-derived
* Turning off buffering of hexadecimal conversion
  * `stdbuf`, from the GNU `coreutils` package
  * `stdbuf`, FreeBSD
  * `unbuffer`, from the expect package (known as `expect-dev` on Debian/Ubuntu)
  * `dd` (used if stdbuf or unbuffer not available)
* Network Connections (can be configured with the `--backends` option to use a different preference order)
  * `bash` (if compiled with socket support; this is true for Mac OS X, Mac OS X + Homebrew, RHEL 6+, Centos 6+, Debian 6+, and Ubuntu 10.04 LTS +)
  * `ncat`, part of the `nmap` package (available as `nmap` on Debian/Ubuntu and Mac OS X + Homebrew)
  * `nc6`, a predecessor of `ncat` (available as `nc6` on Debian/Ubuntu and Mac OS X + Homebrew)
  ncDebianTraditional ncDebianOpenBSD ncMacOSX ncGNU ncToybox ncBusyBox
  * `nc`, Debian Traditional variant (available as `netcat-traditional` on Debian/Ubuntu)
  * `nc`, Debian OpenBSD variant (available as `netcat-openbsd` on Debian/Ubuntu; usually installed by default)
  * `nc`, Mac OS X
  * `socat`
  * `tcpclient`, part of D J Bernstein's [`ucspi-tcp`](http://cr.yp.to/ucspi-tcp.html) package (available as `ucspi-tcp` on Debian/Ubuntu and Mac OS X + Homebrew)
* Validating UTF-8 strings
  * `iconv`, from the GNU `glibc` package
  * `iconv`, BSD-derived
  * Nothing (validation not performed)
* Random client-id generation
  * `openssl`
  * `dd` with access to either `/dev/urandom` or `/dev/random`
  * `gpg`
  * `awk`, any POSIX compliant-version, but using it is not cryptographically robust
  * Nothing, if the shell has a RANDOM psuedo-environment variable: not cryptographically robust
  * Nothing, if random client-ids are not needed


### `bash` versions


### Optimum, Fully-featured Configurations

#### For Debian 7, Ubuntu 12.04 LTS and 14.04 LTS
* GNU `coreutils` deb package
* GNU `sed` deb package
* GNU `grep` deb package
* `bsdmainutils` deb package
* 
* BusyBox configured to use as builtin the list of required dependencies (above) and the following
  * `ash` (GNU Bash-like features aren't required)
  * `hexdump`
  * `dd`
* From GNU coreutils (because BusyBox doesn't have a builtin for stdbuf)
  * `stdbuf`
  * `od`
* From GNU glibc
  * `iconv`

#### For BusyBox Embedded Use (as of version 1.22.1)
* BusyBox configured to use as builtins the list of required dependencies (above) and the following
  * `ash` (GNU Bash-like features aren't required)
  * `hexdump`
  * `dd`
* From GNU coreutils (because BusyBox doesn't have a builtin for stdbuf)
  * `stdbuf`
  * `od`
* From GNU glibc
  * `iconv`


### Minimum Configurations

#### For BusyBox Embedded Use (as of version 1.22.1)
* BusyBox configured to use as builtings the list of required dependencies (above) and the following
  * `ash` (GNU Bash-like features aren't required)
  * `dd` with `/dev/urandom`
* From GNU coreutils (because BusyBox doesn't have a builtin for stdbuf)
  * `stdbuf`
  * `od`
* From

### Supported Operating Systems and Linux Distributions
To be effective

## Supported Shells
bish-bosh tries very hard to make sure it works under any POSIX-compliant shell. However, in practice, that's quite hard to do; many features on the periphery of POSIX compliance, are subtly different (eg signal handling during read). That can lead to a matrix of pain. We constrain the list to widely-used shells common in the sorts of places you'd want to use bish-bosh: system administration, one-off scripting, boot-time and embedded devices with no compiler toolchain. Consequently, we test against:-

* [Almquist-derived](https://en.wikipedia.org/wiki/Almquist_shell) shells, particularly
  * [DASH](http://gondor.apana.org.au/~herbert/dash/)
  * [BusyBox](http://www.busybox.net/downloads/BusyBox.html)'s ash
 * [GNU Bash](https://www.gnu.org/software/bash/bash.html)

All of these shells support dynamically-scoped `local` variables, something we make extensive use of. Some of them also support read timeouts, which is essential for making

### Zsh and KornShell
bish-bosh is not actively tested under [zsh](http://www.zsh.org/) although it should work once the inevitable few bugs are fixed. zsh is a nice interactive shell, and good for scripting, too. In particular, it is the only shell where it's possible for the `read` builtin to read data containing Unicode `\u0000` (ACSCII `NUL` as was), and is also trully non-blocking.

We try hard to maintain some compatibility with KornShell ksh88 derivatives; bish-bosh may work under [mksh](https://www.mirbsd.org/mksh.htm) or [pdksh](http://www.cs.mun.ca/~michael/pdksh/) (although the latter hasn't been actively updated since 1999). At this time, [ksh93](http://www.kornshell.org/) is known not to work. We have no access to ksh88 so can't support it.

### Unsupported Shells
The following shells are untested and unsupported:-

* [oksh](http://www.connochaetos.org/oksh/) (A Linux derivative of OpenBSD's ksh shell)
* [yash](http://sourceforge.jp/projects/yash/)
* ksh88
