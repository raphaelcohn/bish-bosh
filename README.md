# bish-bosh
bish-bosh is a client and library for using [MQTT](http://mqtt.org/), particularly [MQTT 3.1.1](http://www.oasis-open.org/committees/mqtt/) from the shell and command-line for Linux and Unix. It works with [DASH](http://gondor.apana.org.au/~herbert/dash/), [GNU Bash](https://www.gnu.org/software/bash/bash.html) and [BusyBox](http://www.busybox.net/downloads/BusyBox.html)'s ash, with a minimal set of helper programs that even the most basic of Unix systems should have.

Additionally, it is also a command interpreter. Once installed in your `PATH`, it can be used to script [MQTT](http://mqtt.org/) sessions, eg

    #!/usr/bin/env bish-bosh
	bishbosh_server=test.mosquitto.org
	bishbosh_clientId=CLIENT_ID
	
	...
	
	bishbosh_connection_handler_PUBLISH()
	{
		# We've got a message. bish-bosh handles QoS 1 and 2 for us; we just need to use it.
		printf '%s:' "$topicName"
		cat "$messageFilePath"
	}

Making the above snippet executable (`chmod +x SNIPPET`) creates a fully-fledged MQTT driven program. Ideal for one-off testing, system administrators clearing out queues and simple message driven apps that can use the Unix/Linux ecosystem and philosphy. Also quite handy for small embedded systems without a compiler toolchain and initrd boot time configuration grabbing...

If there's interest, a more advanced version could function as interactive shell driven by ncurses...

## Download and Quick Start
bish-bosh can be used simply by cloning from github. To clone into your home folder, type:-

    cd "$HOME"
	git clone https://github.com/raphaelcohn/bish-bosh.git
	git submodule update --init --recursive
	cd -

This will create a folder `bish-bosh` inside your `$HOME`. bish-bosh can then be used straightaway, eg

    cd "$HOME"/bish-bosh
	./bish-bosh --server test.mosquitto.org --client-id CLIENT_ID

where `CLIENT_ID` is a client id you'd like to use. bosh-bosh will attempt to find its dependencies on the PATH, install any missing dependencies (with your permission) if it recognises your package manager, choose an optimum configuration and connect to the server (in this case, a commonly available test one).

Of course, this might not work, and so you might need to install some dependencies (see below).

## Switches and Configuration
bish-bosh has a lot of switches! Most of them you'll hopefully never use: they're to deal with situations where network access isn't straightforward. Perhaps you've got multiple NICs or IP addresses, or a proxy is blocking you from connecting directly. And all of the switches, bar one, have sensible defaults. All of bish-bosh's switches can be set using configuration (eg in `/etc`), or even in the scripts you run; the choice is yours. However, the basic invocation is very simple:-

    bish-bosh --server SERVER --client-id CLIENT_ID
	
	# or, if you prefer short options
	
	bish-bosh -s SERVER -c CLIENT_ID

If you don't specify `SERVER`, it defaults to `localhost`. `CLIENT_ID` is a MQTT client id. (We have partial support for random client ids, so eventually you'll not even need to specify this).

If your MQTT server isn't running on port `1883`, you can specify it:-

    bish-bosh --server SERVER --client-id CLIENT_ID --port PORT
	
	# or, if you prefer short options
	
	bish-bosh -s SERVER -c CLIENT_ID -p PORT

where `PORT` is a port between 1 and 65535.

### Hang on a minute, where do I put the MQTT username / password / other connect stuff?
Well, it's quite straightforward. Rather than use _even more_ switches (and place sensitive data in the command line where any user with `ps` can see it), you can specify configuration scripts. For example, we could have the script snippet:-

    # Save as script.bishbosh
	bishbosh_connection_write_CONNECT_username='raphcohn'
	bishbosh_connection_write_CONNECT_password='whatever you like'

saved as `file.bishbosh` and use it as

    bish-bosh --server SERVER --client-id CLIENT_ID -- script.bishbosh

The `--` isn't strictly necessary, but it's good practice - just in case you name something `--silly-file-name`, it stops bish-bosh getting confused.

Of course, you can have more than one script, eg

    bish-bosh --server SERVER --client-id CLIENT_ID -- script.bishbosh another-script.bishbosh

So you could keep sensitive data (eg a password) in one file, and everything else in another - a good approach which would let you check all your scripts into source control bar the one with the password, and so do simple production deployments and devops-stuff.

As an added convenience, you can also store configuration scripts on a per-client-id basis, too. This means that common connection settings for a client can be stored, but different runtime invocations catered for. Very useful for system administration tasks.

There's quite a lot of things than can be configured this way. If a setting is missing, bish-bosh appliesa default. For things like QoS, we got for the lowest; for usernames and passwords and wills, we omit them. So it you've got a MQTT server that doesn't need passwords (a bit odd, but possible), then you can just not set it. Please note that not set isn't the same thing as empty:-

    bishbosh_connection_write_CONNECT_username=''
	# is not the same as
	unset bishbosh_connection_write_CONNECT_username

### Switches are the same as Configuration Opions
Everything you specify as a long-option switch can be specified in configuration. By convention, the naming in configuration matches the switches, eg

    --server test.mosquitto.org
	--clients-path /var/lib/bish-bosh

is configured as

    bishbosh_server='test.mosquitto.org'
	bishbosh_clientsPath='/var/lib/bish-bosh'

ie, prefix with `bishbosh_`, remove the `--` and for every `-` followed by a letter, remove the `-` and make the letter capitalized.

### OK, back to switches

#### Proxy Settings
Personally, I find proxies extremely irritating, and of very limited benefit. But many organizations still use them, if simply because once they go in, they tend to stay in - they appeal to the control freak in all of us, I suppose. bish-bosh does its best to support SOCKS and HTTP proxies, but we're reliant on the rather limited support of backends. Many don't support them, not least because most FOSS is produced by developers who wouldn't use them - they're individuals, not power-mad network admins.

When using a proxy, you won't be able to use Unix domain sockets. Not every backend supports using a proxy (there's a compatibility table below). And those that do don't support every option:-

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `--proxy-kind` | `KIND` | `bishbosh_proxyKind` | unset | Use a particular `KIND` of proxy. `KIND` is one of `SOCKS4`, `SOCKS5`, `HTTP` or `none`. Using `none` disables the proxy; this is for when a global configuration has been set for a machine but a local user needs to run without it. |
| `-proxy-server` | `HOST` | `bishbosh_proxyServer` | unset | Connect to a proxy server on a given `HOST`, which may be a name, an IPv4 or IPv6 address (in the case of the latter, you may need to surround it in `[]`; backends vary and do not document IPv6 proxy address handling). If you disable DNS resolution of MQTT server names, it's likely that a backend will do likewise for `HOST`. |
| `--proxy-port` | `PORT` | `bishbosh_proxyPort` | 1080 for `KIND` of `SOCKS4` or `SOCKS5`. 3128 for `HTTP`. unset for `none`. | Port the proxy server `HOST` is running on. |
| `--proxy-username` | `UN` | `bishbosh_proxyUsername` | unset | Username `UN` to use. Please note that passing this as a switch is insecure. |
| `--proxy-password` | `PWD` | `bishbosh_proxyPassword` | unset | Password `PWD` to use. Please note that passing this as a switch is insecure. Rarely supported. |

_Note: Not running proxies myself, I can't test many of these settings directly._

## Configuration
Configuration is not just about 

### Global, Per-Machine

### Per-User

### Per-Environment

### Per MQTT server & client id

### Per-Invocation
This is the grand-daddy. In effect, any of 

## Dependencies
bish-bosh tries to use as few dependencies as possible, but, since this is shell script, that's not always possible. It's compounded by the need to support the difference between major shells, too. It also does its best to work around differences in common binaries, by using feature detection, and where it can't do any better, by attempting to install using your package manager.

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
Unfortunately, there are a lot of GNU Bash versions that are still in common use. Versions 3 and 4 of Bash differ in their support of key features (such as associative arrays). Even then, Bash 4.1 is arguably not particularly useful with associative arrays, though, as its declare syntax lacks the `-g` global setting. bish-bosh tries to maintain compatibility with `bash` as at version 3.1/3.2, even though it's obsolescent, because it occurs on two common platforms. A quick guide to common bash version occurrence is below.

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
	git clone https://github.com/raphaelcohn/bish-bosh.git
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

_Note: BusyBox configurations will work on Debian/Ubuntu, too, and so can be used for boot-time MQTT activities._

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
	git clone https://github.com/raphaelcohn/bish-bosh.git
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

## Status of Supported Backends

| Backend | Filename | Variant | Connectivity | Status | Force IPv4 | Force IPv6 | Unix Domain Sockets Support | Proxy Support | Source IP / Port |
| ------- | ------- | ------------ | ------ | ---------- | ---------- | --------------------------- | ------------- | ---------------- |
| netcat | nc | Mac OS X | MQTT | Fully functional | Yes | Yes | Yes | SOCKS4, SOCKS5 and HTTP. No usernames or passwords. | Yes |
| netcat | nc | GNU | MQTT | Barely Implemented | Yes | Yes | Yes | No | Yes |
| netcat | nc.openbsd | Debian OpenBSD | MQTT | Barely Implemented | Yes | Yes | Yes | SOCKS4, SOCKS5 and HTTP. Usernames supported. | Yes |
| netcat | nc.traditional | Debian Traditional / Hobbit | MQTT | Barely Implemented | Yes | Yes | No | No | Yes |
| netcat | nc6 | netcat6, nc6 | MQTT | Barely Implemented | Yes | Yes | No | No | Yes |
| netcat | ncat| Nmap ncat | MQTT / MQTTS | Barely Implemented | Yes | Yes | Yes | SOCKS4, SOCKS5 and HTTP. Usernames and passwords supported for HTTP, usernames only for SOCKS. | Yes |
| socat | socat | socat | MQTT / MQTTS | Barely Implemented | Yes | Yes | Yes | ? | ? |
| tcpclient | tcpclient | tcpclient | MQTT | Barely Implemented | Yes | Yes | No | No | Yes |

### TODO
* Turning off DNS resolution
* supporting inactivity timers
* MQTTS using openssl, socat, gnutls and others
* MQTT over SSH
* MQTT over WebSockets

## netcat, Mac OS X Variant
F