# [bish-bosh]
[bish-bosh] is a client and library for using [MQTT], particularly [[MQTT] 3.1.1](http://www.oasis-open.org/committees/mqtt/) from the shell and command-line for Linux and Unix. It works with [DASH](http://gondor.apana.org.au/~herbert/dash/), [GNU Bash](https://www.gnu.org/software/bash/bash.html) and [BusyBox](http://www.busybox.net/downloads/BusyBox.html)'s ash, with a minimal set of helper programs that even the most basic of Unix systems should have.

Additionally, it is also a command interpreter. Once installed in your `PATH`, it can be used to script [MQTT] sessions, eg

    #!/usr/bin/env [bish-bosh]
	bishbosh_server=test.mosquitto.org
	bishbosh_clientId=CLIENT_ID
	
	...
	
	bishbosh_connection_handler_PUBLISH()
	{
		# We've got a message. [bish-bosh] handles QoS 1 and 2 for us; we just need to use it.
		printf '%s:' "$topicName"
		cat "$messageFilePath"
	}

Making the above snippet executable (`chmod +x SNIPPET`) creates a fully-fledged [MQTT] driven program. Ideal for one-off testing, system administrators clearing out queues and simple message driven apps that can use the Unix/Linux ecosystem and philosphy. Also quite handy for small embedded systems without a compiler toolchain and initrd boot time configuration grabbing...

If there's interest, a more advanced version could function as interactive shell driven by ncurses...

## Download and Quick Start
[bish-bosh] can be used simply by cloning from github. To clone into your home folder, type:-

    cd "$HOME"
	git clone https://github.com/raphaelcohn/[bish-bosh].git
	git submodule update --init --recursive
	cd -

This will create a folder [bish-bosh] inside your `$HOME`. [bish-bosh] can then be used straightaway, eg

    cd "$HOME"/[bish-bosh]
	./bish-bosh --server test.mosquitto.org --client-id CLIENT_ID

where `CLIENT_ID` is a client id you'd like to use. bosh-bosh will attempt to find its dependencies on the `PATH`, install any missing dependencies (with your permission) if it recognises your package manager, choose an optimum configuration and connect to the server (in this case, a commonly available test one).

Of course, this might not work, and so you might need to install some dependencies (see below) or change your backend (see Switched and Configuration, below).

### Getting it from [Homebrew](http://brew.sh/) for Mac OS X
Hopefully in the next few weeks [bish-bosh] will be available as a [Homebrew](http://brew.sh/) recipe, so you should be able to do

    brew install bish-bosh

### Installing into your `PATH` and Packaging
You might want to install [bish-bosh] in your `PATH`, or package it. [bish-bosh] as checked into github _isn't standalone_: it needs to be _fattened_ using [shellfire]. shellfire is a set of common libraries for shell scripting which [bish-bosh] uses. _Fattening_ is the name the shellfire project uses for creating a standalone, self-contained shell binary (even one that can include templates, documents and tarballs) that can then reside anywhere.

_Fattening_ is not currently supported, but is planned to be very soon.

## Switches and Configuration
[bish-bosh] has a lot of switches! Most of them you'll hopefully never use: they're to deal with situations where network access isn't straightforward. Perhaps you've got multiple NICs or IP addresses, or a proxy is blocking you from connecting directly. And all of the switches, bar one, have sensible defaults. All of [bish-bosh]'s switches can be set using configuration (eg in `/etc`), or even in the scripts you run; the choice is yours. However, the basic invocation is very simple:-

    bish-bosh --server SERVER --client-id CLIENT_ID
	
	# or, if you prefer short options
	
	bish-bosh -s SERVER -c CLIENT_ID

If you don't specify `SERVER`, it defaults to `localhost`. `CLIENT_ID` is a [MQTT] client id. (We have partial support for random client ids, so eventually you'll not even need to specify this).

If your [MQTT] server isn't running on port `1883`, you can specify it:-

    bish-bosh --server SERVER --client-id CLIENT_ID --port PORT
	
	# or, if you prefer short options
	
	bish-bosh -s SERVER -c CLIENT_ID -p PORT

where `PORT` is a port between 1 and 65535.

### Hang on a minute, where do I put the [MQTT] username / password / other connect stuff?
Well, it's quite straightforward. Rather than use _even more_ switches (and place sensitive data in the command line where any user with `ps` can see it), you can specify configuration scripts. For example, we could have the script snippet:-

    # Save as script.bishbosh
	bishbosh_connection_write_CONNECT_username='raphcohn'
	bishbosh_connection_write_CONNECT_password='whatever you like'

saved as `file.bishbosh` and use it as

    bish-bosh --server SERVER --client-id CLIENT_ID -- script.bishbosh

The `--` isn't strictly necessary, but it's good practice - just in case you name something `--silly-file-name`, it stops [bish-bosh] getting confused.

Of course, you can have more than one script, eg

    bish-bosh --server SERVER --client-id CLIENT_ID -- script.bishbosh another-script.bishbosh

So you could keep sensitive data (eg a password) in one file, and everything else in another - a good approach which would let you check all your scripts into source control bar the one with the password, and so do simple production deployments and devops-stuff.

As an added convenience, you can also store configuration scripts on a per-client-id basis, too. This means that common connection settings for a client can be stored, but different runtime invocations catered for. Very useful for system administration tasks.

There's quite a lot of things than can be configured this way. If a setting is missing, [bish-bosh] applies a default. For things like QoS, we got for the lowest; for usernames and passwords and wills, we omit them. So it you've got a [MQTT] server that doesn't need passwords (a bit odd, but possible), then you can just not set it. Please note that not set isn't the same thing as empty:-

    bishbosh_connection_write_CONNECT_username=''
	# is not the same as
	unset bishbosh_connection_write_CONNECT_username

### Switches are the same as Configuration Opions
Everything you specify as a long-option switch can be specified in configuration. By convention, the naming in configuration matches the switches, eg

    --server test.mosquitto.org
	--clients-path /var/lib/[bish-bosh]

is configured as

    bishbosh_server='test.mosquitto.org'
	bishbosh_clientsPath='/var/lib/[bish-bosh]'

ie, prefix with `bishbosh_`, remove the `--` and for every `-` followed by a letter, remove the `-` and make the letter capitalized. (With one exception, `--verbosity`, which is specified as `core_init_verbosity`, because it is inherited from the [shellfire] framework).

### OK, back to switches

#### Informational Settings

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `-v, --verbose` | `[LEVEL]` | `core_init_verbosity` | `0` | Adjusts verbosity of output on standard error (stderr). `LEVEL` is optional; omitting causes a +1 increase in verbosity. May be specified multiple times, although levels greater than `2` have no effect currently. The only configuration setting that doesn't reflect convention naming (because it is inherited from [shellfire]) |
| `--version` | | | | Version and license information in a GNU-like format on standard error. |
| `-h,--help` | | | | A very long help message recapping most of this document's information. |

#### [MQTT] Big Hitters

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `-s, --server` | `HOST` | `bishbosh_server` | `localhost` | `HOST` is a DNS-resolved hostname, IPv4 or IPv6 address of an [MQTT] server to connect to, or, if using Unix Domain Sockets (see `--transport` in Source-Routing Settings, below) a file path to a readable Unix Domain Socket. |
| `-p, --port` | `PORT` | `bishbosh_port` | 1883 for most backends; 8883 if backend is secure | Port your [MQTT] `HOST` is running on, between 1 to 65535, inclusive. Ignored if using Unix Domain Sockets. |
| `-i, --client-id` | `ID` | `bishbosh_clientId` | unset | [MQTT] Client ID. Essential; we do not support random ids (yet). When specified, it also, in conjunction with `HOST` and `PORT`, is used to find a folder containing state and scripts for the client id `ID`, to the server `HOST`, on the port `PORT`. |

#### Backends
A backend is the strategy [bish-bosh] uses to connect to a [MQTT] server. It incorporates the encryption capabilities, foibles, and gotchas of the necessary binary that provides a socket connection. Some backends are actually 'meta' backends that use feature detection to work. [bish-bosh] ships with a large number of backends to accommodate the varying state of different operating systems, package managers and Linux distributions. In particular, the situation around 'netcat' is particularly bad, with a large number of variants of a popular program.

By default, [bish-bosh] has a list of backends in preferred order, and tries to choose the first that looks like it will work. Of course, given the vagaries of your system, it might not get that right, so you might want to override it.

The currently supported backends are listed in a section below.

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `-b, --backends` | `A,B,...` | `bishbosh_backends` | `ncat,nc6,nc,bash,socat,tcpclient` | Backends are specified in preference order, comma-separated, with no spaces. To specify just one backend, just give its name, eg `ncat`. |

#### Configuration Tweaks
Ordinarily, you should not need to change any of these settings. The `--clients-path` controls where [bish-bosh] looks for state and script information for a particular client. When [bish-bosh] is installed, it typically defaults to `/var/lib/[bish-bosh]/clients`.

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `-c, --clients-path` | `PATH` | `bishbosh_clientsPath` | See help output | `PATH` to a location to store state and script data for a client-id on a per-server, per-client-id basis |
| `--read-latency` | `MSECS` | `bishbosh_readLatency` | See help output | `MSECS` is a value in milliseconds between 0 and 1000 inclusive to tweak blocking read timeouts. blocking read timeouts are experimental and may not work properly in your shell. The value `0` may be interpreted differently by different shells and should be used with caution. |
| `--lock-latency` | `MSECS` | `bishbosh_lockLatency` | See help output | `MSECS` is a value in milliseconds between 0 and 1000 inclusive to tweak lock acquisitions. Locking is currently done using `mkdir`, which is believed to be an atomic operation on most common filesystems. |

#### Source-Routing Settings
If you have a box with multiple NICs or IP addresses, broken IPv4 / IPv6 networking (or DNS resolution) or strange firewall policies that block certain source ports, you can control those as follows:-

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `--transport` | `TRANSPT` | `bishbosh_transport` | `inet` | Use a particular socket transport `TRANSPT`. `TRANSPT` may be one of `inet`, `inet4`, `inet6` or `unix`. Using `inet` allows the backend to select either a IPv4 or IPv6 connection as appropriate after DNS resolution. `inet4` forces an IPv4 connection; `inet6` likewise forces an IPv6 connection. `unix` forces a Unix Domain Socket connection |
| `--source-address` | `S` | `bishbosh_sourceAddress` | unset | Connect using the NIC with the source address `S`. If `TRANSPT` is `unix` then `S` must reference an extant, accessible Unix Domain Socket file path. Results in packets being sent from this address. `S` may be a host name resolved using DNS, or an IPv4 or IPv6 address. If you disable DNS resolution of [MQTT] server names, it's likely that a backend will do likewise for `HOST`. If `S` is set to `''` (the empty string), then it is treated as if unset. This is to allow local users to override global configuration. |
| `--source-port` | `PORT` | `bishbosh_sourcePort` | unset | Connect using the source port `PORT`. If `TRANSPT` is `unix` then this setting is invalid. Results in packets being sent from this port. If unset, then a random source port is chosen. If `PORT` is set to `''` (the empty string), then it is treated as if unset. This is to allow local users to override global configuration. |

#### Proxy Settings
Personally, I find proxies extremely irritating, and of very limited benefit. But many organizations still use them, if simply because once they go in, they tend to stay in - they appeal to the control freak in all of us, I suppose. [bish-bosh] does its best to support SOCKS and HTTP proxies, but we're reliant on the rather limited support of backends. Many don't support them, not least because most FOSS is produced by developers who wouldn't use them - they're individuals, not power-mad network admins.

When using a proxy, you won't be able to use Unix domain sockets (eg `--transport unix`). Not every backend supports using a proxy (there's a compatibility table below). And those that do don't support every option:-

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `--proxy-kind` | `KIND` | `bishbosh_proxyKind` | unset | Use a particular `KIND` of proxy. `KIND` is one of `SOCKS4`, `SOCKS5`, `HTTP` or `none`. Using `none` disables the proxy; this is for when a global configuration has been set for a machine but a local user needs to run without it. |
| `-proxy-server` | `HOST` | `bishbosh_proxyServer` | unset | Connect to a proxy server on a given `HOST`, which may be a name, an IPv4 or IPv6 address (in the case of the latter, you may need to surround it in `[]`, eg `[::1]`; backends vary and do not document IPv6 proxy address handling). If you disable DNS resolution of [MQTT] server names, it's likely that a backend will do likewise for `HOST`. |
| `--proxy-port` | `PORT` | `bishbosh_proxyPort` | 1080 for `KIND` of `SOCKS4` or `SOCKS5`. 3128 for `HTTP`. unset for `none`. | Port the proxy server `HOST` is running on. |
| `--proxy-username` | `UN` | `bishbosh_proxyUsername` | unset | Username `UN` to use. Please note that passing this as a switch is insecure. |
| `--proxy-password` | `PWD` | `bishbosh_proxyPassword` | unset | Password `PWD` to use. Please note that passing this as a switch is insecure. Rarely supported. |

_Note: Not running proxies myself, I can't test many of these settings combinations._

### Configuration Locations
Anything you can do with a command line switch, you can do as configuration. But configuration can also be used with scripts. Indeed, the configuration syntax is simply shell script. Configuration files _should not_ be executable. This means that if you _really_ want to, you can override just about any feature or behaviour of [bish-bosh] - although that's not explicitly supported. Configuration can be in any number of locations. Configuration may be a single file, or a folder of files; in the latter case, every file in the folder is parsed in 'shell glob-expansion order' (typically ASCII sort order of file names). Locations are searched in order as follows:-

* Global, per-machine
  * For all [shellfire]-based programs, including [bish-bosh]
    * As a file `/etc/shellfire/rc`
    * As any file in `/etc/shellfire/rc.d`, parsed in shell glob-expansion order (ASCII sort order, typically)
  * For any [bish-bosh] program
    * As a file in `/`
* Per User
* Per Environment
* By [MQTT] server, port and Client Id
* Per Invocation

#### Global, Per-Machine

  
  /Users/raphcohn/Documents/[bish-bosh]/etc/shellfire/rc
  /Users/raphcohn/Documents/[bish-bosh]/etc/shellfire/rc.d
  /Users/raphcohn/Documents/[bish-bosh]/etc/[bish-bosh]/rc
  /Users/raphcohn/Documents/[bish-bosh]/etc/[bish-bosh]/rc.d
  HOME/.shellfire/rc
  HOME/.shellfire/rc.d
  shellfire_RC
  shellfire_RC_D
  HOME/.[bish-bosh]/rc
  HOME/.[bish-bosh]/rc.d
  [bish-bosh]_RC
  [bish-bosh]_RC_D

#### Per-User

#### Per-Environment

#### Per [MQTT] server & client id

#### Per-Invocation on the command-line
This is the grand-daddy. In effect, any of 

#### Standalone

## Dependencies
[bish-bosh] tries to use as few dependencies as possible, but, since this is shell script, that's not always possible. It's compounded by the need to support the difference between major shells, too. It also does its best to work around differences in common binaries, by using feature detection, and where it can't do any better, by attempting to install using your package manager.

### Required Dependencies
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

If cloning from github, then you'll also need to make sure you have `git`.

### Either Or Dependencies (one is required)
These are listed in preference order. Ordinarily, [bish-bosh] uses the PATH and feature detection to try to find an optimum dependency. Making some choices, however, influences others (eg `hexdump` and `od` preferences change when `stdbuf` is discovered, to try to use GNU `od`). Some choices are sub-optimal, and may cause operational irritation (mostly, bishbosh responds far more slowly to signals and socket disconnections).

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
  * `dd`, any POSIX-compliant version.
* Network Connections (can be configured with the `--backends` option to use a different preference order)
  * `ncat`, part of the `nmap` package (available as `nmap` on Debian/Ubuntu and Mac OS X + Homebrew)
  * `nc6`, a predecessor of `ncat` (available as `nc6` on Debian/Ubuntu and Mac OS X + Homebrew)
  ncDebianTraditional ncDebianOpenBSD ncMacOSX ncGNU ncToybox ncBusyBox
  * `nc`, Debian Traditional variant (available as `netcat-traditional` on Debian/Ubuntu)
  * `nc`, Debian OpenBSD variant (available as `netcat-openbsd` on Debian/Ubuntu; usually installed by default)
  * `nc`, Mac OS X
  * `bash` (if compiled with socket support; this is true for Mac OS X, Mac OS X + Homebrew, RHEL 6+, Centos 6+, Debian 6+, and Ubuntu 10.04 LTS +)
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


### GNU Bash versions
Unfortunately, there are a lot of GNU Bash versions that are still in common use. Versions 3 and 4 of Bash differ in their support of key features (such as associative arrays). Even then, Bash 4.1 is arguably not particularly useful with associative arrays, though, as its declare syntax lacks the `-g` global setting. [bish-bosh] tries to maintain compatibility with `bash` as at version 3.1/3.2, even though it's obsolescent, because it occurs on two common platforms. A quick guide to common bash version occurrence is below.

* bash 3.1+
  * Git-Bash
  * MinGW
* bash 3.2
  * Mac OS X
* bash 4.1
  * Ubuntu 10.04 LTS
  * RedHat RHEL 6
  * Centos 6
  * Cygwin (as of Sep 2014, although 4.3 is in the works)
* bash 4.2
  * Ubuntu 12.04 LTS
* bash 4.3
  * Ubuntu 14.04 LTS
  * Mac OS X + Homebrew

### File System Requirements
There must be a writable temporary folder (eg `/tmp`), ideally mounted on an in-memory file system (eg tmpfs). `/dev/null` must be present and permission available for writing to (we do not read from it). Incoming messages and session state are by default stored in `/var/lib`; this can be changed (most easily by a symlink, see below). If generating random client ids, then one of `/dev/urandom` or `/dev/random` may be required (if not using `openssl`).

## Configurations
The widely varying list of dependencies and preferences can be confusing, so here's a little guidance.

### Optimum, Fully-featured

#### For Debian 7, Ubuntu 12.04 LTS and 14.04 LTS
All of these dependencies bar `nc-traditional` should already be installed on a standard Debian or Ubuntu installation:-
* `bash`
* `coreutils`
* `sed`
* `grep`
* `bsdmainutils`
* `libc-bin`
* `bash`
* `nc-traditional`
* `git`, if cloning from github

In a terminal window running bash or dash, do:-

    sudo apt-get update
	sudo apt-get install bash coreutils sed grep bsdmainutils libc-bin bash nc-traditional git
	cd "$HOME"
	git clone https://github.com/raphaelcohn/[bish-bosh].git
	git submodule update --init --recursive
	cd -

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

_Note: BusyBox configurations will work on Debian/Ubuntu, too, and so can be used for boot-time [MQTT] activities._

#### For Mac OS X
* [Homebrew package manager](http://brew.sh/), with
  * `bash`, for bash 4.3
  * `coreutils`
  * `gnu-sed`
  * `grep`
  * `git`, if cloning from github

In a terminal window running bash, do:-

    brew update
	brew install bash coreutils gnu-sed grep git

### Minimal Configurations

#### For Debian 7, Ubuntu 12.04 LTS and 14.04 LTS
As for the optimum configuration, but substituting `dash` for `bash` and `nc-openbsd` for `nc-traditional`. All of the dependencies should already be installed, but if not, in a terminal window do:-

    sudo apt-get update
	sudo apt-get install dash coreutils sed grep bsdmainutils libc-bin bash nc-openbsd git
	cd "$HOME"
	git clone https://github.com/raphaelcohn/[bish-bosh].git
	git submodule update --init --recursive
	cd -

#### For BusyBox Embedded Use (as of version 1.22.1)
* BusyBox configured to use as builtins the list of required dependencies (above) and the following
  * `ash` (GNU Bash-like features aren't required)
  * `hexdump`
  * `dd`

#### For Mac OS X
No installation should be required.

#### For Toybox Embedded Use (as of 0.5.0)
* BusyBox configured to use as builtins the list of required dependencies (above) and the following
  * `hexdump`
  * `dd`
* `dash` shell

## Supported Shells
[bish-bosh] tries very hard to make sure it works under any POSIX-compliant shell. However, in practice, that's quite hard to do; many features on the periphery of POSIX compliance, are subtly different (eg signal handling during read). That can lead to a matrix of pain. We constrain the list to widely-used shells common in the sorts of places you'd want to use [bish-bosh]: system administration, one-off scripting, boot-time and embedded devices with no compiler toolchain. Consequently, we test against:-

* The [Almquist-derived](https://en.wikipedia.org/wiki/Almquist_shell) shells
  * [DASH](http://gondor.apana.org.au/~herbert/dash/)
  * [BusyBox](http://www.busybox.net/downloads/BusyBox.html)'s ash
* [GNU Bash](https://www.gnu.org/software/bash/bash.html)

All of these shells support dynamically-scoped `local` variables, something we make extensive use of. Some of them also support read timeouts, which is very useful for making [bish-bosh] responsive.

### Zsh and KornShell
[bish-bosh] is not actively tested under [zsh](http://www.zsh.org/) although it should work once the inevitable few bugs are fixed. zsh is a nice interactive shell, and good for scripting, too. In particular, it is the only shell where it's possible for the `read` builtin to read data containing Unicode `\u0000` (ACSCII `NUL` as was), and is also trully non-blocking.

We try hard to maintain some compatibility with KornShell ksh88 derivatives; [bish-bosh] may work under [mksh](https://www.mirbsd.org/mksh.htm) or [pdksh](http://www.cs.mun.ca/~michael/pdksh/) (although the latter hasn't been actively updated since 1999). At this time, [ksh93](http://www.kornshell.org/) is known not to work. We have no access to ksh88 so can't support it.

### Unsupported Shells
The following shells are untested and unsupported:-

* [oksh](http://www.connochaetos.org/oksh/) (A Linux derivative of OpenBSD's ksh shell)
* [yash](http://sourceforge.jp/projects/yash/)
* ksh88

## Status of Supported Backends

| Backend | Filename | Variant | Connectivity | Status | Force IPv4 | Force IPv6 | Unix Domain Sockets Support | Proxy Support | Source IP / Port |
| ------- | ------- | ------------ | ------ | ---------- | ---------- | --------------------------- | ------------- | ---------------- |
| ncMacOSX | `nc` | Mac OS X | MQTT | Fully functional | Yes | Yes | Yes | SOCKS4, SOCKS5 and HTTP. No usernames or passwords. | Yes |
| ncGNU | `nc` | GNU | MQTT | Barely Implemented | Yes | Yes | Yes | No | Yes |
| ncDebianTraditional | `nc.openbsd` | Debian OpenBSD | MQTT | Barely Implemented | Yes | Yes | Yes | SOCKS4, SOCKS5 and HTTP. Usernames supported. | Yes |
| ncDebianOpenBSD | `nc.traditional` | Debian Traditional / Hobbit | MQTT | Barely Implemented | Yes | Yes | No | No | Yes |
| ncToybox | `nc` / `busybox nc` | BusyBox | MQTT | Barely Implemented | No | No | No, although serial device files are supported | No | Yes |
| ncBusyBox | `nc` / `toybox nc` / `toybox-$(uname)` /  | Toybox / Hobbit | MQTT | Barely Implemented | No | No | No, although serial device files are supported | No | Source Port only |
| nc6 | `nc6` | netcat6, nc6 | MQTT | Barely Implemented | Yes | Yes | No | No | Yes |
| ncat | `ncat`| Nmap ncat | MQTT / MQTTS | Barely Implemented | Yes | Yes | Yes | SOCKS4, SOCKS5 and HTTP. Usernames and passwords supported for HTTP, usernames only for SOCKS. | Yes |
| socat | `socat` | socat | MQTT / MQTTS | Barely Implemented | Yes | Yes | Yes | ? | ? |
| tcpclient | `tcpclient` | tcpclient | MQTT | Barely Implemented | Yes | Yes | No | No | Yes |

In addition, there is the 'meta' backend, `nc`, which attempts to distinguish between `ncMacOSX`, `ncGNU`, `ncDebianTraditional`, `ncDebianOpenBSD`, `ncToybox` and `ncBusyBox`.

### TODO
* Turning off DNS resolution
* supporting inactivity timers
* [MQTT]S using openssl, socat, gnutls, ncat and others
* [MQTT] over SSH
* [MQTT] over WebSockets
* Investigate suckless tools

### Gotchas
* fattening
* suid / sgid

[bish-bosh]: https://github.com/raphaelcohn/bish-bosh  "bish-bosh on GitHub"
[shellfire]: https://github.com/shellfire-dev  "shellfire on GitHub"
[MQTT]: http://mqtt.org/ "[MQTT]"
