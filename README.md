# [bish-bosh]
[bish-bosh] is a client and library for using [MQTT], particularly [MQTT 3.1.1](http://www.oasis-open.org/committees/mqtt/) from the shell and command-line for Linux and Unix. It works with [DASH], [GNU Bash] and [BusyBox]'s ash, with a minimal set of helper programs that even the most basic of Unix systems should have.

Additionally, it is also a command interpreter. Once installed in your `PATH`, it can be used to script [MQTT] sessions, eg

```bash
#!/usr/bin/env bish-bosh
bishbosh_server='test.mosquitto.org'
bishbosh_clientId='my-client-id'

# We've got a message
bishbosh_connection_handler_PUBLISH()
{
	# bish-bosh handles QoS 1 and 2 for us
	# and redirects stdout so we can write to the MQTT server
	printf '%s:' "$topicName" 1>&2
	cat "$messageFilePath" 1>&2
}
```

Making the above snippet executable (`chmod +x SCRIPT`) creates a fully-fledged [MQTT] driven program. Ideal for one-off testing, system administrators clearing out queues and simple message driven apps that can use the Unix/Linux ecosystem and philosphy. Also quite handy for small embedded systems without a compiler toolchain and initrd boot time configuration grabbing...

If there's interest, a more advanced version could function as interactive shell driven by ncurses...

## Download and Quick Start
[bish-bosh] can be used simply by cloning from [GitHub]. To clone into your home folder, type:-

```bash
cd "$HOME"
git clone https://github.com/raphaelcohn/bish-bosh.git
git submodule update --init --recursive
cd -
```

This will create a folder [bish-bosh] inside your home folder. [bish-bosh] can then be used straightaway, eg

```bash
cd "$HOME"/bish-bosh
./bish-bosh --server test.mosquitto.org --client-id CLIENT_ID
```

where `CLIENT_ID` is a client id you'd like to use. bosh-bosh will attempt to find its dependencies on the `PATH`, install any missing dependencies (with your permission) if it recognises your package manager, choose an optimum configuration and connect to the server (in this case, a commonly available test one).

Of course, this might not work, and so you might need to install some [dependencies](#dependencies) or change your [backend](#backends).

### Getting it from [Homebrew](http://brew.sh/) for Mac OS X
Hopefully in the next few weeks [bish-bosh] will be available as a [Homebrew](http://brew.sh/) recipe, so you should be able to do

```
brew install bish-bosh
```

### Installing into your `PATH` and Packaging
You might want to install [bish-bosh] in your `PATH`, or package it. [bish-bosh] as checked into [GitHub] _isn't standalone_: it needs to be _fattened_ using [shellfire]. shellfire is a set of common libraries for shell scripting which [bish-bosh] uses. _Fattening_ is the name the shellfire project uses for creating a standalone, self-contained shell binary (even one that can include templates, documents and tarballs) that can then reside anywhere.

_Fattening_ is not currently supported, but is planned to be very soon.

## Switches and Configuring
[bish-bosh] has a lot of switches! Most of them you'll hopefully never use: they're to deal with situations where network access isn't straightforward. Perhaps you've got multiple NICs or IP addresses, or a proxy is blocking you from connecting directly. And all of the switches, bar one, have sensible defaults. All of [bish-bosh]'s switches can be set using configuration (eg in `/etc`), or even in the scripts you run; the choice is yours. However, the basic invocation is very simple:-

```bash
bish-bosh --server SERVER --client-id CLIENT_ID

# or, if you prefer short options

bish-bosh -s SERVER -c CLIENT_ID
```

If you don't specify `SERVER`, it defaults to `localhost`. `CLIENT_ID` is a [MQTT] client id. (We have partial support for random client ids, so eventually you'll not even need to specify this).

If your [MQTT] server isn't running on port `1883`, you can specify it:-

```bash
bish-bosh --server SERVER --client-id CLIENT_ID --port PORT

# or, if you prefer short options

bish-bosh -s SERVER -c CLIENT_ID -p PORT
```

where `PORT` is a port between 1 and 65535.

### Hang on a minute, where do I put the [MQTT] username / password / other connect stuff?
Well, it's quite straightforward. Rather than use _even more_ switches (and place sensitive data in the command line where any user with `ps` can see it), you can specify configuration scripts. For example, we could have the script snippet:-

```bash
bishbosh_connection_write_CONNECT_username='raphcohn'
bishbosh_connection_write_CONNECT_password='whatever you like'
```

saved as `script.bishbosh` and use it as

```bash
bish-bosh --server SERVER --client-id CLIENT_ID -- script.bishbosh
```

The `--` isn't strictly necessary, but it's good practice - just in case you name something `--silly-file-name`, it stops [bish-bosh] getting confused.

Of course, you can have more than one script, eg

```bash
bish-bosh --server SERVER --client-id CLIENT_ID -- script.bishbosh another-script.bishbosh
```

So you could keep sensitive data (eg a password) in one file, and everything else in another - a good approach which would let you check all your scripts into source control bar the one with the password, and so do simple production deployments and devops-stuff.

As an added convenience, you can also store configuration scripts on a per-client-id basis, too. This means that common connection settings for a client can be stored, but different runtime invocations catered for. Very useful for system administration tasks.

There's quite a lot of things than can be configured this way. If a setting is missing, [bish-bosh] applies a default. For things like QoS, we got for the lowest; for usernames and passwords and wills, we omit them. So it you've got a [MQTT] server that doesn't need passwords (a bit odd, but possible), then you can just not set it. Please note that not set isn't the same thing as empty:-

```bash
bishbosh_connection_write_CONNECT_username=''
# is not the same as
unset bishbosh_connection_write_CONNECT_username
```

### All switches can be set as configuration
Everything you specify as a long-option switch can be specified in configuration. By convention, the naming in configuration matches the switches, eg

```bash
--server test.mosquitto.org
--client-path /var/lib/bish-bosh/client
```
is configured as
```bash
bishbosh_server='test.mosquitto.org'
bishbosh_clientPath='/var/lib/bish-bosh/client'
```
ie, prefix with `bishbosh_`, remove the `--` and for every `-` followed by a letter, remove the `-` and make the letter capitalized.

### But the really interesting scriptable stuff is done with configuration files or scriptlets

#### Being specific about how a is made connection
These settings relate to [MQTT]'s **CONNACK** packet.

| Configuration Setting | Values | Interpreted as if *unset* | Explanation |
| --------------------- | ------ | ----------------------- | ----------- |
| `bishbosh_connection_write_CONNECT_cleanSession` | 0 or 1 \* | 0 (ie persistent) | Clean Session flag |
| `bishbosh_connection_write_CONNECT_willTopic` | Any valid topic name | No will messages |  Will topic |
| `bishbosh_connection_write_CONNECT_willQos` | 0 - 2 inclusive | 0 | Will QoS, invalid if `bishbosh_connection_write_CONNECT_willTopic` is unset |
| `bishbosh_connection_write_CONNECT_willRetain` | 0 or 1 \* | 0 | Will Retain flag, invalid if `bishbosh_connection_write_CONNECT_willTopic` is unset |
| `bishbosh_connection_write_CONNECT_willMessage` | Any valid message, but ASCII NUL is not supported | invalid | Will message, invalid if `bishbosh_connection_write_CONNECT_willTopic` is unset |
| `bishbosh_connection_write_CONNECT_keepAlive` | 0 to 65535 inclusive | 0 | Keep Alive for pings in seconds. A value of 0 disables keep alive handling |
| `bishbosh_clientId` | Any valid UTF-8 string excluding ASCII NUL | invalid | Client id. Empty client ids, and random client ids, are not yet supported. Usually set on the command line with the switch `--client-id CLIENT_ID` |
| `bishbosh_connection_write_CONNECT_username` | Any valid UTF-8 string excluding ASCII NUL. May be empty | No username | Username. May be empty or *unset* (the latter meaning it is not sent) |
| `bishbosh_connection_write_CONNECT_password` | Any sequence of bytes excluding ASCII NUL. May be empty | No password | Password. May be empty or *unset* (the latter meaning it is not sent) |

\* technically, a boolean, which might also be `Y`, `YES`, `Yes`, `yes`, `T`, `TRUE`, `True`, `true`, `ON`, `On`, `on` for 1 and `N`, `NO`, `No`, `no`, `F`, `FALSE`, `False`, `false`, `OFF`, `Off` and `off` for 0, but best as a number.

#### Handling read events
[bish-bosh] supports a number of callbacks, called handlers, whenever something interesting has been read and processed. The default implementations of these just do logging if `--verbose 2` is used.

To override a handler, you just write a shell function definition:-

```bash
bishbosh_connection_handler_PUBLISH()
{
	printf '%s' "Received a message on topic ${topicName} which was ${messageLength} byte(s) long and is in the file ${messageFilePath}" 1>&2
	
	# Run a parser?
	# Write a reply?
	# Move or Hardlink to another location (perhaps an inotify-based process)?
	# Or something else? You could even embed your entire program logic here, if it's shell script
	
	# Make sure we clean up
	rm "${messageFilePath}"
}
```
You need to be careful if using `printf` or `echo` - by default, all data written to standard out goes to the [MQTT] server! BTW, [bish-bosh] handles all the publication, subscription and unscribe acknowledgments. You don't have to do anything apart from have a handler (`bishbosh_connection_handler_PUBLISH`) to read your messages. But if you do:-

| Handler | Control Packet Received | Local Variables in Scope | Notes |
| ------- | --------------- | ------------------------ | ----- |
| `bishbosh_connection_handler_CONNACK` | **CONNACK** | `bishbosh_connection_sessionPresent` | Invalid packets and non-zero **CONNACK** codes are handled for you |
| `bishbosh_connection_handler_SUBACK` | **SUBACK** | `packetIdentifier`, `returnCodeCount`, `$@` which is a list of return codes | Invalid and unexpected packets are handled for you; active sessions are tracked on your behalf |
| `bishbosh_connection_handler_UNSUBACK` | **UNSUBACK** | `packetIdentifier` | Invalid and unexpected packets are handled for you; active sessions are tracked on your behalf |
| `bishbosh_connection_handler_PUBLISH` | **PUBLISH** | `packetIdentifier`, `retain`, `dup`, `qos`, `topicLength`, `topicName`, `messageLength`, `messageFilePath` | Invalid and unexpected packets and duplicates are handled appropriately. Publication acknowledgments (***PUBACK***, ***PUBCOMP***) likewise are handled. The only thing you need to do is `rm "$messageFilePath"` if you want |
| `bishbosh_connection_handler_PUBLISH_again` | **PUBLISH** | `packetIdentifier`, `retain`, `dup`, `qos`, `topicLength`, `topicName`, `messageLength`, `messageFilePath` | Called when a QoS 2 message is redelivered |
| `bishbosh_connection_handler_PUBLISH_again` | **PUBLISH** | `packetIdentifier`, `retain`, `dup`, `qos`, `topicLength`, `topicName`, `messageLength`, `messageFilePath` | Called when a QoS 2 message is redelivered |
| `bishbosh_connection_handler_PUBACK` | ***PUBACK*** |  `packetIdentifier` | Invalid and unexpected packets are handled for you. Acknowledgments likewise. |
| `bishbosh_connection_handler_PUBREC` | ***PUBREC*** |  `packetIdentifier` | Invalid and unexpected packets are handled for you. Acknowledgments likewise. |
| `bishbosh_connection_handler_PUBREL` | **PUBREL** |  `packetIdentifier` | Invalid and unexpected packets are handled for you. |
| `bishbosh_connection_handler_PUBCOMP` | ***PUBCOMP*** |  `packetIdentifier` | Invalid and unexpected packets are handled for you. |
| `bishbosh_connection_handler_PINGRESP` | **PINGRESP** |  | Nothing much to say. |

#### Writing control packets
Inside any of [bish-bosh]'s handlers, you can publish a message, make a subscription request, etc. Indeed, you can do it yourself - anything sent to standard out goes to the server - but it's probably better to use our built in writers. For example once connected (you received **CONNACK** control packet), you might want to subscribe and send some messages:-

```bash
bishbosh_connection_handler_CONNACK()
{
	bishbosh_connection_write_SUBSCRIBE_packetIdentifier=$bishbosh_connection_nextPacketIdentifier
	bishbosh_connection_incrementNextPacketIdentifier
	bishbosh_connection_write_SUBSCRIBE \
		'/topic/1' 0 \
		'/topic/2' 0
    
	bishbosh_connection_write_UNSUBSCRIBE_packetIdentifier=$bishbosh_connection_nextPacketIdentifier
	bishbosh_connection_incrementNextPacketIdentifier
	bishbosh_connection_write_UNSUBSCRIBE \
		'/topic/not/wanted' \
		'/and/also/topic/not/wanted'
	
	# Publish a QoS 0 message from a string
	bishbosh_connection_write_PUBLISH_topicName='a/b'
	bishbosh_connection_write_PUBLISH_message='Message from a string'
	bishbosh_connection_write_PUBLISH
	
	# Publish a duplicate QoS 2 retained message from a file that is to not be deleted (unlinked) after publication
	bishbosh_connection_write_PUBLISH_dup=1
	bishbosh_connection_write_PUBLISH_qos=2
	bishbosh_connection_write_PUBLISH_retain=yes
	bishbosh_connection_write_PUBLISH_messageFilePath="/path/to/message"
	bishbosh_connection_write_PUBLISH_messageUnlinkFile=no
	bishbosh_connection_write_PUBLISH_resetArguments=no
	bishbosh_connection_write_PUBLISH_packetIdentifier=$bishbosh_connection_nextPacketIdentifier
	bishbosh_connection_incrementNextPacketIdentifier
	bishbosh_connection_write_PUBLISH
	
	# Publish again - using bishbosh_connection_write_PUBLISH_resetArguments=no allows reuse of settings
	bishbosh_connection_write_PUBLISH_packetIdentifier=$bishbosh_connection_nextPacketIdentifier
	bishbosh_connection_incrementNextPacketIdentifier
	bishbosh_connection_write_PUBLISH
}
```
_Note: This code is still evolving and the syntax is likely to change._

_*TODO: Document control packet writers of interest*_

### OK, back to switches

#### Informational Settings

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `-v`, `--verbose` | `[LEVEL]` | `bishbosh_verbose` | `0` | Adjusts verbosity of output on standard error (stderr). `LEVEL` is optional; omitting causes a +1 increase in verbosity. May be specified multiple times, although levels greater than `2` have no effect currently. `LEVEL` must be an unsigned integer. |
| `--version` | | | | Version and license information in a GNU-like format on standard error. |
| `-h`, `--help` | | | | A very long help message recapping most of this document's information. |

#### [MQTT] Big Hitters

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `-s`, `--server` | `HOST` | `bishbosh_server` | `localhost` | `HOST` is a DNS-resolved hostname, IPv4 or IPv6 address of an [MQTT] server to connect to. If using Unix domain sockets (see [`--transport`](#source-routing-settings)) it is a file path to a readable Unix domain socket. If using serial devices it a file path to a readable serial device file. |
| `-p`, `--port` | `PORT` | `bishbosh_port` | 1883 for most backends; 8883 if backend is secure | Port your [MQTT] `HOST` is running on, between 1 to 65535, inclusive. Ignored if using Unix domain sockets or serial device files (see [`--transport`](#source-routing-settings)). |
| `-i`, `--client-id` | `ID` | `bishbosh_clientId` | *unset* | [MQTT] ClientId. Essential; we do not support random ids (yet). When specified, it also, in conjunction with `HOST` and `PORT`, is used to find a folder containing state and scripts for the client id `ID`, to the server `HOST`, on the port `PORT`. |

#### [Backends](#status-of-supported-backends)
A backend is the strategy [bish-bosh] uses to connect to a [MQTT] server. It incorporates the encryption capabilities, foibles, and gotchas of the necessary binary that provides a socket connection. Some backends are actually 'meta' backends that use feature detection to work. [bish-bosh] ships with a large number of [backends](#status-of-supported-backends) to accommodate the varying state of different operating systems, package managers and Linux distributions. In particular, the situation around 'netcat' is particularly bad, with a large number of variants of a popular program.

By default, [bish-bosh] has a list of [backends](#status-of-supported-backends) in preferred order, and tries to choose the first that looks like it will work. Of course, given the vagaries of your system, it might not get that right, so you might want to override it. Not all backends support all features; in particular, unix domain sockets, proxies and serial devices vary: this [list of backends](#status-of-supported-backends) gives more information.

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `-b`, `--backends` | `A,B,...` | `bishbosh_backends` | `ncat,nc6,nc,bash,socat,tcpclient` | [Backends](#status-of-supported-backends) are specified in preference order, comma-separated, with no spaces. To specify just one backend, just give its name, eg `ncat`. |

#### Configuration Tweaks
Ordinarily, you should not need to change any of these settings.

The `--client-path` controls where [bish-bosh] looks for script information for a particular client. When [bish-bosh] is installed, it typically defaults to `/var/lib/bish-bosh/client`.
The `--session-path` controls where [bish-bosh] looks for Clean Session = 0 information for a particular client. When [bish-bosh] is installed, it typically defaults to `/var/spool/bish-bosh/session`.
The `--lock-path` controls where [bish-bosh] tries to create a lock for a particular client. When [bish-bosh] is installed, it typically defaults to `/var/lib/bish-bosh/lock`, which is not the [Linux FHS] default of `/var/lock` (but is used because that works out of the box on Mac OS X).

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `-c`, `--client-path` | `PATH` | `bishbosh_clientPath` | *See help output* | `PATH` to a location to configuration - scriptlets for a client-id on a per-server, per-port, per-client-id basis. See [Configuration Locations](#configuration-locations) |
| `-t`, `--session-path` | `PATH` | `bishbosh_sessionPath` | *See help output* | `PATH` to a location to store session data for clients connecting with Clean Session = 0 |
| `-l`, `--lock-path` | `PATH` | `bishbosh_lockPath` | *See help output* | `PATH` to a location to screate a Mutex lock so only one instance connects per-server, per-port, per-client-id at a time. |
| `--read-latency` | `MSECS` | `bishbosh_readLatency` | *See help output* | `MSECS` is a value in milliseconds between 0 and 1000 inclusive to tweak blocking read timeouts. blocking read timeouts are experimental and may not work properly in your shell. The value `0` may be interpreted differently by different shells and should be used with caution. |
| `--lock-latency` | `MSECS` | `bishbosh_lockLatency` | *See help output* | `MSECS` is a value in milliseconds between 0 and 1000 inclusive to tweak lock acquisitions. Locking is currently done using `mkdir`, which is believed to be an atomic operation on most common filesystems. |

#### Source-Routing Settings
If you have a box with multiple NICs or IP addresses, broken IPv4 / IPv6 networking (or DNS resolution) or strange firewall policies that block certain source ports, you can control those as follows:-

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `--transport` | `TRANSPT` | `bishbosh_transport` | `inet` | Use a particular socket transport `TRANSPT`. `TRANSPT` may be one of `inet`, `inet4`, `inet6`, `unix` or `serial`. Using `inet` allows the backend to select either a IPv4 or IPv6 connection as appropriate after DNS resolution. `inet4` forces an IPv4 connection; `inet6` likewise forces an IPv6 connection. `unix` uses a Unix domain socket connection. `serial` opens a serial character device file. |
| `--source-address` | `S` | `bishbosh_sourceAddress` | *unset* | Connect using the NIC with the source address `S`. Results in packets being sent from this address. `S` may be a host name resolved using DNS, or an IPv4 or IPv6 address. If you disable DNS resolution of [MQTT] server names, it's likely that a backend will do likewise for `HOST`. If `S` is set to `''` (the empty string), then it is treated as if *unset*. This is to allow local users to override global configuration. Ignored if `TRANSPT` is `unix` or `serial`. |
| `--source-port` | `PORT` | `bishbosh_sourcePort` | *unset* | Connect using the source port `PORT`. If `TRANSPT` is `unix` then this setting is invalid. Results in packets being sent from this port. If unset, then a random source port is chosen. If `PORT` is set to `''` (the empty string), then it is treated as if *unset*. This is to allow local users to override global configuration. Ignored if `TRANSPT` is `unix` or `serial`. |

#### Proxy Settings
Personally, I find proxies extremely irritating, and of very limited benefit. But many organizations still use them, if simply because once they go in, they tend to stay in - they appeal to the control freak in all of us, I suppose. [bish-bosh] does its best to support SOCKS and HTTP proxies, but we're reliant on the rather limited support of backends. Many don't support them, not least because most FOSS is produced by developers who wouldn't use them - they're individuals, not power-mad network admins.

When using a proxy, you won't be able to use Unix domain sockets ([`--transport unix`](#source-routing-settings)) or serial devices ([`--transport serial`](#source-routing-settings)). Not every backend supports using a proxy (there's a [compatibility table](#status-of-supported-backends)). And those that do don't support every option:-

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `--proxy-kind` | `KIND` | `bishbosh_proxyKind` | *unset* | Use a particular `KIND` of proxy. `KIND` is one of `SOCKS4`, `SOCKS5`, `HTTP` or `none`. Using `none` disables the proxy; this is for when a global configuration has been set for a machine but a local user needs to run without it. |
| `-proxy-server` | `HOST` | `bishbosh_proxyServer` | *unset* | Connect to a proxy server on a given `HOST`, which may be a name, an IPv4 or IPv6 address (in the case of the latter, you may need to surround it in `[]`, eg `[::1]`; backends vary and do not document IPv6 proxy address handling). If you disable DNS resolution of [MQTT] server names, it's likely that a backend will do likewise for `HOST`. |
| `--proxy-port` | `PORT` | `bishbosh_proxyPort` | 1080 for `KIND` of `SOCKS4` or `SOCKS5`. 3128 for `HTTP`. unset for `none`. | Port the proxy server `HOST` is running on. |
| `--proxy-username` | `UN` | `bishbosh_proxyUsername` | *unset* | Username `UN` to use. Please note that passing this as a switch is insecure. |
| `--proxy-password` | `PWD` | `bishbosh_proxyPassword` | *unset* | Password `PWD` to use. Please note that passing this as a switch is insecure. Rarely supported. |

_Note: Not running proxies myself, I can't test many of these settings combinations._

## File Locations

### Configuration Locations
Anything you can do with a command line switch, you can do as configuration. But configuration can also be used with scripts. Indeed, the configuration syntax is simply shell script. Configuration files _should not_ be executable. This means that if you _really_ want to, you can override just about any feature or behaviour of [bish-bosh] - although that's not explicitly supported. Configuration can be in any number of locations. Configuration may be a single file, or a folder of files; in the latter case, every file in the folder is parsed in 'shell glob-expansion order' (typically ASCII sort order of file names). Locations are searched in order as follows:-

1. Global (Per-machine)
  1. The file `INSTALL_PREFIX/etc/bish-bosh/rc`
  2. Any files in the folder `INSTALL_PREFIX/etc/bish-bosh/rc.d`
2. Per User, where `HOME` is your home folder path\*
  1. The file `HOME/.bish-bosh/rc`
  2. Any files in the folder `HOME/.bish-bosh/rc.d`
3. Per Environment
  1. The file in the environment variable `bishbosh_RC` (if the environment variable is set and the path is readable)
  2. Any files in the folder in the environment variable `bishbosh_RC_D` (if the environment variable is set and the path is searchable)
4. In `SCRIPTLETS`
  * Scriptlets are parsed in order they are found on the command line (`bish-bosh -- [SCRIPTLETS]...`)
5. Under the configuration setting `bishbosh_clientPath` or switch [`--client-path`](#configuration-tweaks)
  1. The file `servers/${bishbosh_server}/rc` where `bishbosh_server` is a configuration setting or the switch [`--server`](#mqtt-big-hitters)†
  2. Any files in the folder `servers/${bishbosh_server}/rc.d`†
  3. The file `servers/${bishbosh_server}/ports/${bishbosh_port}/rc` where `bishbosh_port` is a configuration setting or the switch [`--port`](#mqtt-big-hitters)‡
  4. Any files in the folder `servers/${bishbosh_server}/port/${bishbosh_port}/rc.d`‡
  5. The file `servers/${bishbosh_server}/ports/${bishbosh_port}/client-ids/${bishbosh_clientId}/rc` where `bishbosh_clientId` is a configuration setting or the switch [`--client-id`](#mqtt-big-hitters)
  6. Any files in the folder `servers/${bishbosh_server}/ports/${bishbosh_port}/client-ids/${bishbosh_clientId}/rc.d` 

\* An installation as a daemon using a service account would normally set `HOME` to something like `/var/lib/bishbosh`.

† it is possible for a configuration file here to set `bishbosh_port` (or even `bishbost_clientId`), so influencing the search in 3 - 6.

‡ It is possible for a configuration file here to set `bishbost_clientId`, so influencing the search in 5 and 6.

Nothing stops any of these paths, or files in them, being symlinks. This can be exploited to symlink together, say, port numbers 1883 and 8883, or client ids that share usernames and passwords, etc.

## Dependencies
[bish-bosh] tries to use as few dependencies as possible, but, since this is shell script, that's not always possible. It's compounded by the need to support the difference between major shells, too. It also does its best to work around differences in common binaries, by using feature detection, and where it can't do any better, by attempting to install using your package manager.

### Required Dependencies
All of these should be present even on the most minimal system. Usage is restricted to those flags known to work across Mac OS X, GNU, BusyBox and Toybox.

* `mkdir`
* `mkfifo`
* `mktemp`
* `touch`
* `mv`
* `rm`
* `rmdir`
* `tr`
* `cat`
* `kill`
* `sleep`
* `uname`
* `sed`
* `grep`

If cloning from [GitHub], then you'll also need to make sure you have `git`.

### Either Or Dependencies (one is required)
These are listed in preference order. Ordinarily, [bish-bosh] uses the PATH and feature detection to try to find an optimum dependency. Making some choices, however, influences others (eg `hexdump` and `od` preferences change when `stdbuf` is discovered, to try to use GNU `od`). Some choices are sub-optimal, and may cause operational irritation (mostly, bishbosh responds far more slowly to signals and socket disconnections).

* Binary to Hexadecimal conversion
  * `hexdump`, BSD-derived (part of the `bsdmainutils` packages in Debian/Ubuntu; usually installed by default)
  * `hexdump`, in BusyBox
  * `hexdump`, in [Toybox]
  * `od`, from GNU `coreutils` package
  * `od`, in BusyBox
  * `od`, in [Toybox]
  * `od`, BSD-derived
* Turning off buffering of hexadecimal conversion
  * `stdbuf`, from the GNU `coreutils` package
  * `stdbuf`, FreeBSD
  * `unbuffer`, from the expect package (known as `expect-dev` on Debian/Ubuntu)
  * `dd`, any POSIX-compliant version.
* Network Connections (can be configured with the `--backends` option to use a different preference order)
  * `ncat`, part of the `nmap` package (available as `nmap` on Debian/Ubuntu and Mac OS X + Homebrew)
  * `nc6`, a predecessor of `ncat` (available as `nc6` on Debian/Ubuntu and Mac OS X + Homebrew)
  * `nc`, Debian Traditional variant (available as the `netcat-traditional` package on Debian/Ubuntu)
  * `nc`, Debian OpenBSD variant (available as the `netcat-openbsd` package on Debian/Ubuntu; usually installed by default)
  * `nc`, Mac OS X
  * `nc`, GNU (last known version 0.7.1 from 2004 tested)
  * `nc`, BusyBox
  * `nc`, Toybox
  * `bash` (if compiled with socket support; this is true for Mac OS X Snow Leopard+, Mac OS X + Homebrew, RHEL 6+, Centos 6+, Debian 6+, and Ubuntu 10.04 LTS +)
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


### A word on [GNU Bash] versions
Unfortunately, there are a lot of [GNU Bash] versions that are still in common use. Versions 3 and 4 of Bash differ in their support of key features (such as associative arrays). Even then, Bash 4.1 is arguably not particularly useful with associative arrays, though, as its declare syntax lacks the `-g` global setting. [bish-bosh] tries to maintain compatibility with `bash` as at version 3.1/3.2, even though it's obsolescent, because it occurs on two common platforms. A quick guide to common bash version occurrence is below.

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

#### Temporary Files
There must be a writable temporary folder (eg `/tmp`; we use whatever `mktemp` does), ideally mounted on an in-memory file system (eg tmpfs). Every client connection will create a very small amount of data in the temporary structure (mostly FIFOs and folders). Additionally, clients connecting with Clean Session = 1 will store all their data inside temporary folders; if messages are large, then this will consume more data.

#### Devices
* `/dev/null` must be present and permission available for writing to (we do not read from it).
* one of `/dev/urandom` or `/dev/random` may be required if generating random ids (only used if `openssl` is not available)

#### `/var`
We use a `/var` folder underneath where we're installed. If you've just cloned [bish-bosh] from [GitHub], then this is _within_ the clone.
* `/var/lib/bish-bosh/client` must be searchable and writable for the user running `bish-bosh`. This `PATH` be changed with the `--client-path PATH` option or `bishbosh_clientPath='PATH'` [configuration setting](#configuration-tweaks).
* `/var/spool/bish-bosh/session` must be searchable and writable for the user running `bish-bosh`. This `PATH` be changed with the `--session-path PATH` option or `bishbosh_sessionPath='PATH'` [configuration setting](#configuration-tweaks).
* `/var/run/bish-bosh/lock` must be searchable and writable for the user running `bish-bosh`. This `PATH` be changed with the `--lock-path PATH` option or `bishbosh_lockPath='PATH'` [configuration setting](#configuration-tweaks).

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
* `git`, if cloning from [GitHub]

In a terminal window running bash or dash, do:-

```bash
sudo apt-get update
sudo apt-get install bash coreutils sed grep bsdmainutils libc-bin bash nc-traditional git
cd "$HOME"
git clone https://github.com/raphaelcohn/bish-bosh.git
git submodule update --init --recursive
cd -
```

#### For BusyBox Embedded Use (as of version 1.22.1)
* BusyBox configured to use as builtins the list of required dependencies (above) and the following
  * `ash` ([GNU Bash]-like features aren't required)
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
  * `git`, if cloning from [GitHub]

In a terminal window running bash, do:-
```bash
brew update
brew install bash coreutils gnu-sed grep git
```

### Minimal Configurations

#### For Debian 7, Ubuntu 12.04 LTS and 14.04 LTS
As for the optimum configuration, but substituting `dash` for `bash` and `nc-openbsd` for `nc-traditional`. All of the dependencies should already be installed, but if not, in a terminal window do:-

```bash
sudo apt-get update
sudo apt-get install dash coreutils sed grep bsdmainutils libc-bin bash nc-openbsd git
cd "$HOME"
git clone https://github.com/raphaelcohn/bish-bosh.git
git submodule update --init --recursive
cd -
```

#### For BusyBox Embedded Use (as of version 1.22.1)
* BusyBox configured to use as builtins the list of required dependencies (above) and the following
  * `ash` ([GNU Bash]-like features aren't required)
  * `hexdump`
  * `dd`

#### For Mac OS X
No installation should be required.

#### For [Toybox] Embedded Use (as of 0.5.0)
* BusyBox configured to use as builtins the list of required dependencies (above) and the following
  * `hexdump`
  * `dd`
* `dash` shell

## Supported Shells
[bish-bosh] tries very hard to make sure it works under any POSIX-compliant shell. However, in practice, that's quite hard to do; many features on the periphery of POSIX compliance, are subtly different (eg signal handling during read). That can lead to a matrix of pain. We constrain the list to widely-used shells common in the sorts of places you'd want to use [bish-bosh]: system administration, one-off scripting, boot-time and embedded devices with no compiler toolchain. Consequently, we test against:-

* The [Almquist]-derived shells, specifically
  * [DASH]
  * [BusyBox]'s ash
* [GNU Bash]

All of these shells support dynamically-scoped `local` variables, something we make extensive use of. Some of them also support read timeouts, which is very useful for making [bish-bosh] responsive.

### Zsh and KornShell
[bish-bosh] is not actively tested under [zsh] although it should work once the inevitable few bugs are fixed. [zsh] is a nice interactive shell, and good for scripting, too. In particular, it is the only shell where it's possible for the `read` builtin to read data containing Unicode `\u0000` (ACSCII `NUL` as was), and is also trully non-blocking.

We try hard to maintain some compatibility with KornShell ksh88 derivatives; [bish-bosh] may work under [mksh] or [pdksh], although the latter hasn't been actively updated since 1999. At this time, [ksh93] is known not to work. We have no access to [ksh88] so can't support it.

### Unsupported Shells
The following shells are untested and unsupported:-

* [oksh], a Linux derivative of OpenBSD's ksh shell
* [yash]
* [ksh88]

## Status of Supported Backends

| Backend | Filename | Variant | Connectivity | Status | [`--transport inet4`](#source-routing-settings) | [`--transport inet6`](#source-routing-settings) | [`--transport unix`](#source-routing-settings) | [`--transport serial`](#source-routing-settings) | [Proxy](#proxy-settings)  | [`--source-server HOST`](#source-routing-settings) | [`--source-port PORT`](#source-routing-settings) |
| ------- | -------- | ------- | ------------ | ------ | ----------------------------------------------- | ----------------------------------------------- | ---------------------------------------------- | ------------------------------------------------ | ------------------------- | -------------------------------------------------- | ------------------------------------------------ |
| **nc** | 'Meta' backend | Any **nc\*** backend | MQTT | Fully functional* | Yes† | Yes† | Yes† | Yes† | Yes† | Yes† | Yes† |
| **ncMacOSX** | `nc` | Mac OS X | MQTT | Fully functional | Yes | Yes | Yes | No | SOCKS4, SOCKS5 and HTTP. No usernames or passwords. | Yes | Yes |
| **ncGNU** | `nc` | [GNU](http://netcat.sourceforge.net/) | MQTT | Barely Implemented | Yes | Yes | Yes | No | No | Yes | Yes |
| **ncDebianTraditional** | `nc.traditional` | [Debian Traditional](https://packages.debian.org/wheezy/netcat-traditional) / Hobbit | MQTT | Barely Implemented | Yes | Yes | No | No | No | Yes | Yes |
| **ncDebianOpenBSD** | `nc.openbsd` | [Debian OpenBSD](https://packages.debian.org/wheezy/netcat-openbsd) | MQTT | Barely Implemented | Yes | Yes | Yes | No | `SOCKS4`, `SOCKS5` and `HTTP`. Usernames only for `HTTP`. | Yes | Yes |
| **ncBusyBox** | `nc` / `busybox nc` | [BusyBox] | MQTT | Barely Implemented | No | No | No | Yes | No | Yes | Yes |
| **ncToybox** | `nc` / `toybox nc` / `toybox-$(uname)` /  | [Toybox] | MQTT | Barely Implemented | No | No | No | Yes | No | No | Yes |
| **nc6** | `nc6` | [netcat6](http://www.deepspace6.net/projects/netcat6.html) | MQTT | Barely Implemented | Yes | Yes | No | No | No | Yes | Yes |
| **ncat** | `ncat`| [Nmap ncat](http://nmap.org/ncat/) | MQTT / MQTTS | Barely Implemented | Yes | Yes | Yes | No | `SOCKS4`, `SOCKS5` and `HTTP`. Usernames and passwords supported for `HTTP`, usernames only for SOCKS. | Yes | Yes |
| **socat** | `socat` | [socat](http://www.dest-unreach.org/socat/) | MQTT / MQTTS | Barely Implemented | Yes | Yes | Yes | Yes | `SOCKS4` and `HTTP`. Usernames are supported. | ? | ? |
| **tcpclient** | `tcpclient` | [ucspi-tcp](http://cr.yp.to/ucspi-tcp.html) | MQTT | Barely Implemented | Yes | Yes | No | No | No | Yes | Yes |
| **bash** | `bash` | [GNU Bash] | MQTT | Barely Implemented | No | No | No | ? | No | No | No |

\* Refers to the meta backend itself. A detected backend may not be.
† Yes, if the detected variant of the backend does.

## Limitations

### suid / sgid
bish-bosh explicitly tries to detect if run with suid or sgid set, and will exit as soon as possible with an error. It is madness to run shell scripts with such settings.

### Specification Violations
* Apart from [zsh], no shell can either have variables with Unicode NUL (aka ASCII NUL, 0x00) in them, or read them directly. [zsh] is not supported at this time. Consequently,
  * Will messages can not have ASCII NUL in them, although a mechanism to load them from disk may be added
  * Passwords likewise are so constrained (again, loading directly from disk may be added)
* It is not possible to support Keep Alives other than 0 on pure POSIX shells such as `dash`, as they lack read timeouts and the pseudo-environment variable `SECONDS` (a workaround with `date` is painful to consider)
* Shell builtins and most common tools do not support parsing lines delimited with anything other than `\n` (eg `sed`). Whilst some tooling (eg GNU coreutils, [GNU Bash]) can handle `\0` terminated lines, support is not consistent enough. Consequently,
  * Topic names can not contain `\n`.
  * Topic filters can not contain `\n`.
* Since client-ids are used as part of file system paths, they may not be empty even when `bishbosh_connection_write_CONNECT_cleanSession` is 0. This might be fixed in a future version.

### Broken but Fixable
* Keep Alive handling does not correctly support values other than 0, and *PINGREQ* packets are not sent (and **PINGRESP** packets are discarded)
* Unsubscribe handling is broken
* Connection tear down is very brittle, and state can be easily corrupted
* State transitions are nothing like as close to atomic as they could be
* SIGINT / SIGTERM signal handling for read
* Non-blocking reads should cause re-evaluation of connection status

### Useful to do
* Publish messages from a handler that happens before / after read
* Turning off DNS resolution
* supporting inactivity timers
* [MQTT]S using openssl, socat, gnutls, ncat and others
* [MQTT] over SSH
* [MQTT] over WebSockets
* [MQTT] over cryptcat
* Investigate suckless tools
* Investigate supporting empty client ids for clean session = 1
* Investigate proxy support, eg corkscrew
* Investigate [Debian uscpi-tcp-ipv6](https://packages.debian.org/wheezy/ucspi-tcp-ipv6)

[bish-bosh]: https://github.com/raphaelcohn/bish-bosh  "bish-bosh on GitHub"
[shellfire]: https://github.com/shellfire-dev  "shellfire on GitHub"
[GitHub]: https://github.com/ "GitHub Homepage"
[MQTT]: http://mqtt.org/ "MQTT.org"
[DASH]: http://gondor.apana.org.au/~herbert/dash/ "DASH Shell"
[GNU Bash]: https://www.gnu.org/software/bash/bash.html "GNU Bash"
[BusyBox]: http://www.busybox.net/downloads/BusyBox.html "BusyBox"
[Toybox]: http://www.landley.net/toybox/ "Toybox"
[zsh]: http://www.zsh.org/ "zsh"
[oksh]: http://www.connochaetos.org/oksh/ "oksh"
[yash]: http://sourceforge.jp/projects/yash/ "yash"
[ksh93]: http://www.kornshell.org/ "ksh93"
[mksh]: https://www.mirbsd.org/mksh.htm "Mir KornShell"
[pdksh]: http://www.cs.mun.ca/~michael/pdksh/ "Public Domain KornShell"
[ksh88]: http://www.kornshell.com "ksh88 at kornshell.com"
[Almquist]: http://www.in-ulm.de/~mascheck/various/ash/ "Almquist shell"
[Linux FHS]: http://refspecs.linuxfoundation.org/fhs.shtml "Linux File Hierarchy Standard"
