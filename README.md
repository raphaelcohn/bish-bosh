# [bish-bosh]
[bish-bosh] is a MIT-licensed shell script client for [MQTT 3.1.1](http://www.oasis-open.org/committees/mqtt/) that runs *without installation* on any POSIX system on any POSIX shell: Linux, Mac OS X, Cygwin, AIX, FreeBSD, OpenBSD and NetBSD are all known to work, as are the [DASH], [GNU Bash] and [BusyBox] shells. *There are usually no dependencies at all if you're using [BusyBox]*. For everything else, it's a *very* minimal set of helper programs that even the most basic of POSIX-compatible systems should have. Installation can be `cp bish-bosh /path/to`. It'll run on your router, high-end server, your smart phone, laptop or even an unlocked BT fibre modem.

## A Command Interpreter for Scripting [MQTT] sessions

You can give [bish-bosh] any number of scripts to run a [MQTT] session. And, if it's on your `PATH`, these can even become [MQTT] driven programs, eg:-

```bash
#!/usr/bin/env bish-bosh
bishbosh_server='test.mosquitto.org'
bishbosh_clientId='my-client-id'

# We've got a message
bishbosh_connection_handler_PUBLISH()
{
	# bish-bosh handles QoS 1 and 2 for us
	
	# bish-bosh wires stdout to be data to send, so we need to redirect to stderr
	printf '%s' "Received a message on topic ${topicName} which was ${messageLength} byte(s) long and is in the file ${messageFilePath}" 1>&2
	
	# clean up
	rm "${messageFilePath}"
}
```

Making the above snippet executable (`chmod +x SCRIPT`) creates a fully-fledged [MQTT] driven program.

## What's it good for?

***For scripting [MQTT]!***

* One-off testing
* Administrators clearing out queues
* Simple message driven apps that can use the Unix/Linux ecosystem and philosphy
* Handy for small embedded systems without a compiler toolchain
* Useful for CI environments,
* Or where installing most of Python isn't an option.
* Minimal Linux distributions
* Anything where time-to-market matters and message volumes aren't stratospheric

If there's interest, then I could build [bish-bosh] into a [MQTT] broker… That would be quite a win for devops automation, where bootstrapping a set up is quite a chore. If you need to handle XML or JSON messages in your scripts, check out [shellfire]. [bish-bosh] is itself a [shellfire] application.

## Download and Quick Start
Download the [executable](https://github.com/raphaelcohn/bish-bosh/releases/download/release_2015.0119.1445-1/bish-bosh_2015.0119.1445-1_all) from the [latest release](https://github.com/raphaelcohn/bish-bosh/releases/tag/release_2015.0119.1445-1), or simply clone from [GitHub] into your home folder by typing:-

```bash
cd ~
git clone 'https://github.com/raphaelcohn/bish-bosh.git'
(cd bish-bosh; git submodule update --init --recursive)
cd -
```

This will create a folder [bish-bosh] inside your home folder. [bish-bosh] can then be used straightaway, eg

```bash
cd ~/bish-bosh
./bish-bosh --client-id 12 --verbose 2
```

where `12` is an example of a client id you'd like to use. bosh-bosh will attempt to find its dependencies on the `PATH`, choose an optimum configuration and connect to a [MQTT] server (by default, `test.mosquitto.org`). This may appear to do very little until you press `CTRL-C`. That's because we haven't given [bish-bosh] anything to do apart from `CONNECT` and `DISCONNECT`. Why not create this file at `/tmp/bish-bosh.example` and see what happens:-

```bash
cat >/tmp/bish-bosh.example <<EOF
bishbosh_clientId=12

bishbosh_connection_handler_CONNACK()
{
    # Set up some subscriptions... another implementation could read from a standard file
    bishbosh_subscribe \
        '/topic/qos/0' 0 \
        '/topic/qos/1' 1 \
        '/topic/qos/3' 1

    bishbosh_unsubscribe \
        '/topic/not/wanted' \
        '/and/also/topic/not/wanted'

    # Publish a QoS 0 message
    # On topic a/b
    # Unretained
    # With value 'X'
    bishbosh_publishText 0 'a/b' no 'X'
}

bishbosh_connection_handler_PUBLISH()
{
    echo "Message received: retain=$retain, QoS=$QoS, dup=$dup, topicLength=$topicLength, topicName=$topicName, messageLength=$messageLength, messageFilePath=$messageFilePath"
}

bishbosh_connection_handler_noControlPacketsRead()
{
    # This event happens every few milliseconds - use this to publish some messages, change subscriptions or reload our configuration. Perhaps we could monitor a folder path?
    # bishbosh_publishText 0 'nowt' no 'hello world'
	echo 'No Control Packages Read' 1>&2
}
EOF
```

And run it with `./bish-bosh --verbose 2 -- /tmp/bish-bosh.example`.

Of course, this might not work on your setup, and so you might need to install some [dependencies](#dependencies) or change your [backend](#backends).

### Getting it from [Homebrew](http://brew.sh/) for Mac OS X
Hopefully in the next few weeks [bish-bosh] will be available as a [Homebrew](http://brew.sh/) recipe, so you should be able to do

```
brew install bish-bosh
```

### Installing into your `PATH` and Packaging
You might want to install [bish-bosh] in your `PATH`, or package it. [bish-bosh] as checked into [GitHub] _isn't standalone_: it needs to be _fattened_ using [shellfire]. If you want a ready-to-use release, check out [releases](https://github.com/raphaelcohn/bish-bosh/releases). Once in your `PATH`, you can write scripts with `#!/usr/bin/env bish-bosh` as the first line and have standalone bespoke MQTT clients - that can do anything. See [this for an example](#but-the-really-interesting-scriptable-stuff-is-done-with-configuration-files-or-scriptlets).

## Switches and Configuring
[bish-bosh] has a lot of switches! Most of them you'll hopefully never use: they're to deal with situations where network access isn't straightforward. Perhaps you've got multiple NICs or IP addresses, or a proxy is blocking you from connecting directly. And [all of the switches](#ok-back-to-switches) have sensible defaults. All of [bish-bosh]'s switches can be set using configuration (eg in `/etc`), or even in the scripts you run; the choice is yours. However, the basic invocation is very simple:-

```bash
bish-bosh --server 'SERVER' --client-id 'CLIENT_ID'

# or, if you prefer short options

bish-bosh -s 'SERVER' -c 'CLIENT_ID'
```

If you don't specify `SERVER`, it defaults to `test.mosquitto.org`. `CLIENT_ID` is a [MQTT] client id. (We have partial support for random client ids, so eventually you'll not even need to specify this).

If your [MQTT] server isn't running on port `1883`, you can specify it:-

```bash
bish-bosh --server 'SERVER' --client-id 'CLIENT_ID' --port 'PORT'

# or, if you prefer short options

bish-bosh -s 'SERVER' -c 'CLIENT_ID' -p 'PORT'
```

where `PORT` is a port between 1 and 65535.

### Hang on a minute, where do I put the [MQTT] username / password / other connect stuff?
Well, it's quite straightforward. Rather than use _even more_ switches (and place sensitive data in the command line where any user with `ps` can see it), you can specify configuration scripts. For example, we could have the script snippet:-

```bash
bishbosh_connect_username='raphcohn'
bishbosh_connect_password='whatever you like'
```

saved as `script.bishbosh` and use it as

```bash
bish-bosh --server 'SERVER' --client-id 'CLIENT_ID' -- 'script.bishbosh'
```

The `--` isn't strictly necessary, but it's good practice - just in case you name something `--silly-file-name`, it stops [bish-bosh] getting confused.

Of course, you can have more than one script, eg

```bash
bish-bosh --server 'SERVER' --client-id 'CLIENT_ID' -- 'script.bishbosh' 'another-script.bishbosh'
```

So you could keep sensitive data (eg a password) in one file, and everything else in another - a good approach which would let you check all your scripts into source control bar the one with the password, and so do simple production deployments and devops-stuff.

As an added convenience, you can also store configuration scripts on a per-client-id basis, too. This means that common connection settings for a client can be stored, but different runtime invocations catered for. Very useful for system administration tasks.

There's quite a lot of things than can be configured this way. If a setting is missing, [bish-bosh] applies a default. For things like QoS, we apply for the lowest; for usernames and passwords and wills, we omit them. So if you've got a [MQTT] server that doesn't need passwords (a bit odd, but possible), then you can just not set it. Please note that not set isn't the same thing as empty:-

```bash
bishbosh_connect_username=''
# is not the same as
unset bishbosh_connect_username
```

### All switches can be set as configuration
Everything you specify as a long-option switch can be specified in configuration. By convention, the naming in configuration matches the switches, eg

```bash
--server 'test.mosquitto.org'
--client-path '/var/lib/bish-bosh/client'
```
is configured as
```bash
bishbosh_server='test.mosquitto.org'
bishbosh_clientPath='/var/lib/bish-bosh/client'
```
ie, prefix with `bishbosh_`, remove the `--` and for every `-` followed by a letter, remove the `-` and make the letter capitalized.

### But the really interesting scriptable stuff is done with configuration files or scriptlets

For example, this scriptlet shows a skeleton persistent client which does quite a lot (including retransmission) - with very little code:-

```bash
#!/usr/bin/env bish-bosh
bishbosh_server=test.mosquitto.org
# load your configuration if you need to, eg bishbosh_clientId="$(</path/to/client-id)" or use '.' (source)
bishbosh_clientId=<some-client-id>

bishbosh_connect_cleanSession=0
bishbosh_connect_willTopic='some/will/topic'
bishbosh_connect_willMessageFilePath=/path/to/will/message
bishbosh_connect_willQoS=1
bishbosh_connect_willRetain=1
# 5 second ping
bishbosh_connect_keepAlive=5
bishbosh_connect_username=<some-user-name>
bishbosh_connect_passwordFilePath=/path/to/password/kept/securely

bishbosh_connection_handler_CONNACK()
{
	# Set up some subscriptions... another implementation could read from a standard file
	bishbosh_subscribe \
		'/topic/qos/0' 0 \
		'/topic/qos/1' 1 \
		'/topic/qos/3' 1
	
	bishbosh_unsubscribe \
		'/topic/not/wanted' \
		'/and/also/topic/not/wanted'
	
	# Publish a QoS 0 message
	# On topic a/b
	# Unretained
	# With value 'X'
	bishbosh_publishText 0 'a/b' no 'X'
	
	# Publish a QoS 1 message
	# bish-bosh handles the QoS for us
	# On topic a/b
	# Unretained
	# Using the contents of file '/path/to/message'
	bishbosh_publishFile 1 'a/b' no '/path/to/message'
	
	# Publish a QoS 2 message
	# bish-bosh handles the QoS for us
	# and will retransmit on re-connect
	# On topic a/b
	# Retained
	# Using the contents of file '/path/to/message/to/remove/after/send'
	# Then remove '/path/to/message/to/remove/after/send' after send (QoS 2 takes a copy)
	bishbosh_publishFileAndRemove 2 'a/b' yes '/path/to/message/to/remove/after/send'
}

bishbosh_connection_handler_PUBLISH()
{
	echo "Message received: retain=$retain, QoS=$QoS, dup=$dup, topicLength=$topicLength, topicName=$topicName, messageLength=$messageLength, messageFilePath=$messageFilePath"
}

bishbosh_connection_handler_noControlPacketsRead()
{
	# Down time - use this to publish some messages, change subscriptions or reload our configuration. Perhaps we could monitor a folder path?
	# Note: bish-bosh silently handles any PING packets on our behalf
	bishbosh_publishText 0 'nowt' no 'hello world'
}
```

It's easy to see how that could be modified to generate a will message or get a password by a secure means, monitor a folder or add sophisticated subscription tracking to build up a picture of current state.

#### Being specific about how a is made connection
These settings relate to [MQTT]'s **CONNECT** packet.

| Configuration Setting | Values | Interpreted as if *unset* | Explanation |
| --------------------- | ------ | ----------------------- | ----------- |
| `bishbosh_connect_cleanSession` | 0 or 1 \* | 1 (ie non-persistent) | Clean Session flag |
| `bishbosh_connect_willTopic` | Any valid topic name | No will messages |  Will topic |
| `bishbosh_connect_willQoS` | 0 - 2 inclusive | 0 | Will QoS, invalid if `bishbosh_connect_willTopic` is unset |
| `bishbosh_connect_willRetain` | 0 or 1 \* | 0 | Will Retain flag, invalid if `bishbosh_connect_willTopic` is unset |
| `bishbosh_connect_willMessage` | Any valid message, but Unicode `U+0000` is not supported.† | invalid | Will message, invalid if `bishbosh_connect_willTopic` is unset |
| `bishbosh_connect_willMessageFilePath` | A path to a valid message | invalid | Will message, invalid if `bishbosh_connect_willTopic` is unset or `bishbosh_connect_willMessage` is set. Must be a regular file (reading from a FIFO, etc, is unsupported), as we need to know the size in advance. Useful if a message might contain Unicode `U+0000`.† |
| `bishbosh_connect_keepAlive` | 0 to 65535 inclusive | 0 | Keep Alive for pings in seconds. A value of 0 disables keep alive handling |
| `bishbosh_clientId` | Any valid UTF-8 string excluding Unicode `U+0000` | invalid | Client id. Empty client ids, and random client ids, are not yet supported. Usually set on the command line with the switch `--client-id CLIENT_ID` |
| `bishbosh_connect_username` | Any valid UTF-8 string excluding Unicode `U+0000`. May be empty | No username | Username. May be empty or *unset* (the latter meaning it is not sent) |
| `bishbosh_connect_password` | Any sequence of bytes excluding Unicode `U+0000`. May be empty | No password | Password. May be empty or *unset* (the latter meaning it is not sent) |
| `bishbosh_connect_passwordFilePath` | A path to a valid file. May be empty. | No password | Password, invalid if `bishbosh_connect_password` is set. Must be a regular file (reading from a FIFO, etc, is unsupported), as we need to know the size in advance. Useful if a password might contain Unicode `U+0000`†, or you want to able to check in configuration to source control or change passwords in production. |

_\* Technically, a boolean, which might also be `Y`, `YES`, `Yes`, `yes`, `T`, `TRUE`, `True`, `true`, `ON`, `On`, `on` for 1 and `N`, `NO`, `No`, `no`, `F`, `FALSE`, `False`, `false`, `OFF`, `Off` and `off` for 0, but best as a number._

_† Apart from [zsh], no shell can either have variables with Unicode `U+0000` (ACSCII `NUL` as was) in them, or read them directly._

#### Publishing
Messages can be published using one of three functions:-
* `bishbosh_publishText`, to send messages as text (ie shell strings, which, apart from [zsh], can't contain Unicode `U+0000`);
* `bishbosh_publishFile`, to send messages from a file (so they can contain Unicode `U+0000`);
* `bishbosh_publishFileAndRemove`, which is the same as `bishbosh_publishFile`, but removes the message after it has been sent (of course, any copies neededfor QoS 1 / 2 handling are preserved).

Any unacknowledged **PUBLISH** packets (and **PUBREL** packets) are resent by [bish-bosh] on start-up once **CONNACK** is received.

##### `bishbosh_publishText`
|Position|Purpose|Valid Values|
|--------|-------|------------|
|1|QoS level| `0` to `2` inclusive|
|2|Topic name|Any valid topic name, although `\n` is currently rejected in topics (see [Specification Violations](#specification-violations))|
|3|Retain Flag as a Boolean|`yes` or `no`|
|4|Message text|Any message text. May be empty or omitted (interpreted as empty)|

For example

```bash
bishbosh_publishText 0 'a/b' no 'My message'
```

publishes a message with the text `My message` at QoS `0`, to the topic named `a/b` with RETAIN off (ie not retained).

##### `bishbosh_publishFile`
|Position|Purpose|Valid Values|
|--------|-------|------------|
|1|QoS level| `0` to `2` inclusive|
|2|Topic name|Any valid topic name, although `\n` is currently rejected in topics (see [Specification Violations](#specification-violations))|
|3|Retain Flag as a Boolean|`yes` or `no`|
|4|File path|Any valid file path. Must be readable. Can be empty.|

For example

```bash
bishbosh_publishFile 1 'a/b' no '/path/to/message'
```

publishes a message with the contents of the file `/path/to/message/` at QoS `1`, to the topic named `a/b` with RETAIN off (ie not retained).

##### `bishbosh_publishFileAndRemove`
|Position|Purpose|Valid Values|
|--------|-------|------------|
|1|QoS level| `0` to `2` inclusive|
|2|Topic name|Any valid topic name, although `\n` is currently rejected in topics (see [Specification Violations](#specification-violations))|
|3|Retain Flag as a Boolean|`yes` or `no`|
|4|File path|Any valid file path. Must be readable. Can be empty. Must be writable so we can delete it.|

For example

```bash
bishbosh_publishFileAndRemove 2 'a/b' yes '/path/to/message/to/remove/after/send'
```

publishes a message with the contents of the file `/path/to/message/to/remove/after/send` at QoS `2`, to the topic named `a/b` with RETAIN on (ie retained). When it is sent, it then removes the file `/path/to/message/to/remove/after/send`. An internal copy is kept for QoS handling. For interest, internal copies are made using `mv`, `ln` or `ln -s` wherever possible.

#### Subscribing
Subscriptions are sent using the function `bishbosh_subscribe`. Any unacknowledged **SUBSCRIBE** packets are resent by [bish-bosh] on start-up once **CONNACK** is received.

Subscriptions are given by specifiying pairs of variable arguments as `topicFilter` - `topicQos`. At least one pair must be supplied. For example

```bash
bishbosh_subscribe \
'/topic/qos/0' 0 \
'/topic/qos/1' 1 \
'/topic/qos/3' 1
```

subcribes to:-

* a `topicFilter` of `/topic/qos/0` with a requested `topicQos` of `0`, and
* a `topicFilter` of `/topic/qos/1` with a requested `topicQos` of `1`, and
* a `topicFilter` of `/topic/qos/2` with a requested `topicQos` of `2`

#### Unsubscribing
Unsubscriptions are sent using the function `bishbosh_unsubscribe`. Any unacknowledged **UNSUBSCRIBE** packets are resent by [bish-bosh] on start-up once **CONNACK** is received.

Unsubscriptions are given by specifiying variable arguments of `topicFilter`. At least one `topicFilter` must be supplied. For example

```bash
bishbosh_unsubscribe \
'/topic/not/wanted' \
'/and/also/topic/not/wanted'
```

unsubscribes from:-

* a `topicFilter` of `/topic/not/wanted`, and
* a `topicFilter` of `/and/also/topic/not/wanted`

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
| ------- | --------------- | -------------------------------- | ----- |
| `bishbosh_connection_handler_CONNACK` | **CONNACK** | `bishbosh_connection_sessionPresent` | Invalid packets and non-zero **CONNACK** codes are handled for you |
| `bishbosh_connection_handler_SUBACK` | **SUBACK** | `packetIdentifier`, `returnCodeCount`, `$@` which is a list of return codes | Invalid and unexpected packets are handled for you; active sessions are tracked on your behalf |
| `bishbosh_connection_handler_UNSUBACK` | **UNSUBACK** | `packetIdentifier` | Invalid and unexpected packets are handled for you; active sessions are tracked on your behalf |
| `bishbosh_connection_handler_PUBLISH` | **PUBLISH** | `packetIdentifier`, `retain`, `dup`, `QoS`, `topicLength`, `topicName`, `messageLength`, `messageFilePath` | Invalid and unexpected packets and duplicates are handled appropriately. Publication acknowledgments (***PUBACK***, ***PUBCOMP***) likewise are handled. The only thing you need to do is `rm "$messageFilePath"` if you want |
| `bishbosh_connection_handler_PUBLISH_again` | **PUBLISH** | `packetIdentifier`, `retain`, `dup`, `QoS`, `topicLength`, `topicName`, `messageLength`, `messageFilePath` | Called when a QoS 2 message is redelivered |
| `bishbosh_connection_handler_PUBACK` | ***PUBACK*** |  `packetIdentifier` | Invalid and unexpected packets are handled for you. Acknowledgments likewise. |
| `bishbosh_connection_handler_PUBREC` | ***PUBREC*** |  `packetIdentifier` | Invalid and unexpected packets are handled for you. Acknowledgments likewise. |
| `bishbosh_connection_handler_PUBREL` | **PUBREL** |  `packetIdentifier` | Invalid and unexpected packets are handled for you. |
| `bishbosh_connection_handler_PUBCOMP` | ***PUBCOMP*** |  `packetIdentifier` | Invalid and unexpected packets are handled for you. |
| `bishbosh_connection_handler_PINGRESP` | **PINGRESP** |  | Nothing much to say. |
| `bishbosh_connection_handler_noControlPacketsRead` | *none* | Occurs when a read for a control packet timed out. |

* Tip: To find the current list of arguments a handler has access to, run [bish-bosh] with `--verbose 3`.

#### Writing control packets
Inside any of [bish-bosh]'s handlers, you can publish a message, make a subscription request, etc. Indeed, you can do it yourself - anything sent to standard out goes to the server - but it's probably better to use our built in writers. For example once connected (you received **CONNACK** control packet), you might want to subscribe:-

```bash
bishbosh_connection_handler_CONNACK()
{
	bishbosh_connection_write_SUBSCRIBE \
		'/topic/qos/0' 0 \
		'/topic/qos/1' 1 \
		'/topic/qos/3' 1
    
	bishbosh_connection_write_UNSUBSCRIBE \
		'/topic/not/wanted' \
		'/and/also/topic/not/wanted'
}
```

### OK, back to switches

#### Informational Settings

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `-v`, `--verbose` | `[LEVEL]` | `bishbosh_verbose` | `0` | Adjusts verbosity of output on standard error (stderr). `LEVEL` is optional; omitting causes a +1 increase in verbosity. May be specified multiple times, although levels greater than `2` have no effect currently. `LEVEL` must be an unsigned integer. |
|`-q`, `--quiet`| | | | Specify (optionally more than once) to reduce verbosity by a step of `1` |
| `--version` | | | | Version and license information in a GNU-like format on standard error. |
| `-h`, `--help` | | | | A very long help message recapping most of this document's information. |

#### [MQTT] Big Hitters

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `-t`, `--tunnel` | `TUNNEL` | `bishbosh_tunnel` | `none` | The tunnel `TUNNEL` controls how a MQTT connection is made. Ordinarily, it's just `none`: MQTT. Values are `none`, `tls` and `cryptcat`. Changing this setting changes how the [backends](#backends) are chosen. Most backends support only `none`; some also support `tls`, and some only `tls`. In the future, if there's demand, support can also be added for `SSH`, `telnet`, `WebSockets` and `WebSocketsSecure`. This is not the same thing as [proxying](#proxy-settings). Additional [tunnel settings](#tunnel-settings) may be required. |
| `-s`, `--server` | `HOST` | `bishbosh_server` | `test.mosquitto.org` | `HOST` is a DNS-resolved hostname, IPv4 or IPv6 address of an [MQTT] server to connect to. If using Unix domain sockets (see [`--transport`](#source-routing-settings)) it is a file path to a readable Unix domain socket. If using serial devices it a file path to a readable serial device file. |
| `-p`, `--port` | `PORT` | `bishbosh_port` | By `TUNNEL`: 1883 for `none`, `cryptcat`. 8883 for `tls`. | Port your [MQTT] `HOST` is running on, between 1 to 65535, inclusive. Ignored if using Unix domain sockets or serial device files (see [`--transport`](#source-routing-settings)). |
| `-i`, `--client-id` | `ID` | `bishbosh_clientId` | *unset* | [MQTT] ClientId. When specified, it also, in conjunction with `HOST` and `PORT`, is used to find a folder containing state and scripts for the client id `ID`, to the server `HOST`, on the port `PORT`. If *unset*, and [`bishbosh_connect_cleanSession`](#being-specific-about-how-a-is-made-connection) is 1, then forced to empty (`''`), which MAY NOT work with some MQTT servers. |
| `-r`, `--random-client-id` | | `bishbosh_randomClientId`\* | `0` | When specified, `--client-id` isn't and Clean Session is 1, then a random client-id of 16 bytes, base64-encoded, is used, instead of an empty client id. This should work with most MQTT servers. To be compatible with servers that only use a restricted alphanumeric range, the base64 trailing `=` is discarded. Random client-ids with `+` and `/` are discarded and another client id generated. This alogrithm gives similar, but not quite as random, results as using a Type 4 UUID. |
| `-x`, `--ping-timeout` | `SECS` | `bishbosh_pingTimeout` | `30` | When the client's Keep Alive value is not `0`, this is the 'reasonable time' in `SECS` seconds that the client will wait to receive a **PINGRESP** packet. |
| `-w`, `--connect-timeout` | `SECS` | `bishbosh_connectTimeout` | `30` | This is the time in `SECS` seconds that the client will wait to try to connect to a MQTT server. Not all [backends] honour this setting. Some older versions of netcat interpret it as an idle connection timeout. `0` is infinity. |

_ \* This value is a boolean. Use `0` for false, `1` for true ._

#### [Backends](#status-of-supported-backends)

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `-b`, `--backends` | `A,B,…` | `bishbosh_backends` | `openssl,socat,ncat,nc6,nc,ncDebianOpenBSD,ncFreeBSD,ncOpenBSD,ncMirBSD,ncMacOSX,ncDebianTraditional,ncSolaris,ncGNU,ncToybox,ncBusyBox,devtcp,cryptcat` | [Backends](#status-of-supported-backends) are specified in preference order, comma-separated, with no spaces. To specify just one backend, just give its name, eg `ncat`. The backend `nc` represents all the netcat permutations. |

A backend is the strategy [bish-bosh] uses to connect to a [MQTT] server. It incorporates the encryption capabilities, foibles, and gotchas of the necessary binary that provides a socket connection. Some backends are actually 'meta' backends that use feature detection to work. An example of this is the `nc` backend. [bish-bosh] ships with a large number of [backends](#status-of-supported-backends) to accommodate the varying state of different operating systems, package managers and Linux distributions. In particular, the situation around 'netcat' is particularly bad, with a large number of variants of a popular program.

By default, [bish-bosh] has a list of [backends](#status-of-supported-backends) in preferred order, and tries to choose the first that looks like it will work. Of course, given the vagaries of your system, it might not get that right, so you might want to override it. Not all backends support all features; in particular, unix domain sockets, proxies and serial devices vary: this [list of backends](#status-of-supported-backends) gives more information.

#### Configuration Tweaks

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `-c`, `--client-path` | `PATH` | `bishbosh_clientPath` | *See help output* | `PATH` to a location to configuration - scriptlets for a client-id on a per-server, per-port, per-client-id basis. See [Configuration Locations](#configuration-locations) |
| `-d`, `--session-path` | `PATH` | `bishbosh_sessionPath` | *See help output* | `PATH` to a location to store session data for clients connecting with Clean Session = 0 |
| `-l`, `--lock-path` | `PATH` | `bishbosh_lockPath` | *See help output* | `PATH` to a location to screate a Mutex lock so only one instance connects per-server, per-port, per-client-id at a time. |
| `--filesize-algorithm` | `ALGO` | `bishbosh_filesizeAlgorithm` | `ls` | Specify a more efficient filesize algorithm `ALGO` if you have the `stat` program and know which one it is. Choices are `ls`, `GNUAndBusyBoxStat`, `BSDStat` and `ToyboxStat` (not recommended due to lack of a `-L` switch). |
| `--read-latency` | `MSECS` | `bishbosh_readLatency` | *See help output* | `MSECS` is a value in milliseconds between 0 and 1000 inclusive to tweak blocking read timeouts. blocking read timeouts are experimental and may not work properly in your shell. The value `0` may be interpreted differently by different shells and should be used with caution. |

Ordinarily, you should not need to change any of these settings.

The `--client-path` controls where [bish-bosh] looks for script information for a particular client. When [bish-bosh] is installed, it typically defaults to `/var/lib/bish-bosh/client`.
The `--session-path` controls where [bish-bosh] looks for Clean Session = 0 information for a particular client. When [bish-bosh] is installed, it typically defaults to `/var/spool/bish-bosh/session`.
The `--lock-path` controls where [bish-bosh] tries to create a lock for a particular client. When [bish-bosh] is installed, it typically defaults to `/var/lib/bish-bosh/lock`, which is not the [Linux FHS] default of `/var/lock` (but is used because that works out of the box on Mac OS X).

#### Source-Routing Settings

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `--transport` | `TRANSPT` | `bishbosh_transport` | `inet` | Use a particular socket transport `TRANSPT`. `TRANSPT` may be one of `inet`, `inet4`, `inet6`, `unix` or `serial`. Using `inet` allows the backend to select either a IPv4 or IPv6 connection as appropriate after DNS resolution. `inet4` forces an IPv4 connection; `inet6` likewise forces an IPv6 connection. `unix` uses a Unix domain socket connection. `serial` opens a serial character device file. |
| `--source-address` | `S` | `bishbosh_sourceAddress` | *unset* | Connect using the NIC with the source address `S`. Results in packets being sent from this address. `S` may be a host name resolved using DNS, or an IPv4 or IPv6 address. If you disable DNS resolution of [MQTT] server names, it's likely that a backend will do likewise for `HOST`. If `S` is set to `''` (the empty string), then it is treated as if *unset*. This is to allow local users to override global configuration. Ignored if `TRANSPT` is `unix` or `serial`. |
| `--source-port` | `PORT` | `bishbosh_sourcePort` | *unset* | Connect using the source port `PORT`. If `TRANSPT` is `unix` then this setting is invalid. Results in packets being sent from this port. If unset, then a random source port is chosen. If `PORT` is set to `''` (the empty string), then it is treated as if *unset*. This is to allow local users to override global configuration. Ignored if `TRANSPT` is `unix` or `serial`. |

If you have a box with multiple NICs or IP addresses, broken IPv4 / IPv6 networking (or DNS resolution) or strange firewall policies that block certain source ports, you can control those as follows:-

#### Proxy Settings\*

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `--proxy-kind` | `KIND` | `bishbosh_proxyKind` | *unset* | Use a particular `KIND` of proxy. `KIND` is one of `SOCKS4`, `SOCKS4a`, `SOCKS5`, `HTTP` or `none`. Using `none` disables the proxy; this is for when a global configuration has been set for a machine but a local user needs to run without it. Most backends do not support `SOCKS4a`. When using the `SOCKS4` protocol, `HOST` (below) must be a numeric address. `SOCKS4` and `SOCKS4a` do not support IPv6. |
| `-proxy-server` | `HOST` | `bishbosh_proxyServer` | *unset* | Connect to a proxy server on a given `HOST`, which may be a name, an IPv4 or IPv6 address (in the case of the latter, you may need to surround it in `[]`, eg `[::1]`; backends vary and do not document IPv6 proxy address handling). If you disable DNS resolution of [MQTT] server names, it's likely that a backend will do likewise for `HOST`. |
| `--proxy-port` | `PORT` | `bishbosh_proxyPort` | 1080 for `KIND` of `SOCKS4`, `SOCKS4a` or `SOCKS5`. 3128 for `HTTP`. *unset* for `none`. | Port the proxy server `HOST` is running on. |
| `--proxy-username` | `UN` | `bishbosh_proxyUsername` | *unset* | Username `UN` to use. Please note that passing this as a switch is insecure. |
| `--proxy-password` | `PWD` | `bishbosh_proxyPassword` | *unset* | Password `PWD` to use. Please note that passing this as a switch is insecure. Rarely supported. |

Personally, I find proxies extremely irritating, and of very limited benefit (especially in these days of deep packet inspection abuse). But many organizations still use them, if simply because once they go in, they tend to stay in - they appeal to the control freak in all of us, I suppose. [bish-bosh] does its best to support SOCKS and HTTP proxies, but we're reliant on the rather limited support of backends.

When using a proxy, you won't be able to use Unix domain sockets ([`--transport unix`](#source-routing-settings)) or serial devices ([`--transport serial`](#source-routing-settings)). Not every backend supports using a proxy; even those that do don't support every option above (there's a [compatibility table](#status-of-supported-backends)).

_\* Not running proxies myself, I can't test many of these settings combinations._

##### Alternative
It may be possible to hook proxy support into several of the backends using [proxychains-ng](https://github.com/rofl0r/proxychains-ng). If you have an use case for this, please get in touch.

#### Tunnel Settings

##### `tls` tunnel settings

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `--tunnel-tls-ca-file` | `FILE` | `bishbosh_tunnelTlsCaPath` | *unset* | A PEM-encoded file `FILE` which contains a Certificate Authority certificate chain. Do not specify this if `--tunnel-tls-ca-path` is specified. Most backends have a default location for this or `--tunnel-tls-ca-file`. |
| `--tunnel-tls-ca-path` | `PATH` | `bishbosh_tunnelTlsCaPath` | *unset* | A folder `PATH` which contains PEM-encoded Certificate Authority certificates with OpenSSL-compatible hashes. Do not specify this if `--tunnel-tls-ca-file` is specified. Most backends have a default location for this or `--tunnel-tls-ca-path`. |
| `--tunnel-tls-certificate` | `FILE` | `bishbosh_tunnelTlsCertificate` | *unset* | A PEM-encoded\* file `FILE` which a certificate to authenticate the client with. Not normally required. If specified, then `--tunnel-tls-key` must also be specified. |
| `--tunnel-tls-key` | `FILE` | `bishbosh_tunnelTlsKey` | *unset* | A PEM-encoded file\* `FILE` which contains a private key to authenticate the client with. Not normally required. If specified, then `--tunnel-tls-certificate` must also be specified. |
| `--tunnel-tls-use-der` | `BOOL` | `bishbosh_tunnelTlsUseDer` | off | Modifies `--tunnel-tls-certificate` and `--tunnel-tls-key` to expect DER-encoded files. |
| `--tunnel-tls-verify` | `BOOL` | `bishbosh_tunnelTlsCiphers` | on | A boolean `BOOL` used to enable or disable verification of the MQTT server's X.509 certificate chain. Revocation checks (CRL, OCSP) are not performed by most backends. Some backends (eg `openssl`) do not fail on verification failure. |
| `--tunnel-tls-ciphers` | `STR` | `bishbosh_tunnelTlsCiphers` | *unset* | A backend specific string `STR`. Nearly all backends use openssl syntax (`man 5 ciphers` and `openssl ciphers`), except for `gnutls`, which calls this a 'Priority string' (`info gnutls`, then find section 6.10, and `gnutls-cli --list`). |

_\* Can be DER-encoded when `--tunnel-tls-use-der` is `on` . The `socat` and `ncat` backends only support PEM. _

There are a number of limitations at this time:-
* It is not possible to control TLS versions (although the `openssl` backend has `SSLv2` and `SSLv3` disabled)
* Diffie-Hellman bits can't be controlled
* Cipher strings are not normalised to either `openssl` or `gnutls` (although it might be better to use the latter)
* Compression is disabled wherever possible
* Automatic conversion of DER files to PEM for those backends that lack DER support (requires [OpenSSL] or GnuTLS, so seems rather moot)
* Not all backends can support [OpenSSL]-style folders of Certificate Authorities
* OCSP is turned on wherever possible
* CRL files are not used
* SRP and PSK are not supported

In many ways, this list of exclusions typifies the problems of TLS - too many choices, too many options and too many ways of implementing them.

If you need support for any of these features, please contact me - it may be possible to modify [bish-bosh] to accommodate specific needs.

###### [stunnel] Alternative
As an alternative to using `tls` tunnel, one can use a `none` tunnel but connect to, say, [stunnel] running on `localhost` with a `stunnel.conf` such as

    ;stunnel.conf
	
	[mqtts]
	accept = 1883
	connect = ${bishbosh_server}:${bishbosh_port}
	foreground = no
	CApath = ${bishbosh_tunnelTlsCaPath}
	;Or
	;CAfile = ${bishbosh_tunnelTlsCaFile}
	cert = ${bishbosh_tunnelTlsCertificate}
	key = ${bishbosh_tunnelTlsKey}
	TIMEOUTconnect = ${bishbosh_connectTimeout}
	verify = ${bishbosh_verify}

where `${bishbosh_XXX}` relates to a [bish-bosh] configuration setting.

See `man 8 stunnel` for more details. From experience, it can be a bit troublesome to get configured and made to start reliably. It doesn't like configuration values with spaces in.

##### `cryptcat` tunnel settings

| Switch | Value | Configuration Setting | Default | Purpose |
| ------ | ----- | --------------------- | ------- | ------- |
| `--tunnel-cryptcat-password` | `PWD` | `bishbosh_tunnelCryptcatPassword` | *unset* | Should ideally be set using configuration, as it's insecure to set on the command line. However, `cryptcat` itself exposes the password on the command-line… |

## Exit Codes
[bish-bosh] tries to follow the BSD exit code conventions. A non-zero exit code is indicative of failure. Typical codes are:-

| Code | Meaning | Common Causes |
| ---- | ------- | ------------- |
| 78   | Configuration issue | Configuration omitted, contradictory or incorrectly specified |
| 77   | Permission Denied | Run with setuid / setgid bits set. **CONNACK** had a connection return code of 4 or 5 |
| 76   | Protocol | An invalid control packet code, remaining length or control packet was read or decoded |
| 75   | Temporary Failure | Another process has locked our client-id. We could not establish a socket connection to the MQTT server |
| 74   | I/O Error | We couldn't unlink (delete) a message file |
| 73   | Can't create | We couldn't create a temporary file or folder |
| 72   | Missing File | We tried very hard, but even a fallback dependency was missing |
| 71   |  | Not used |
| 70   | Internal Error | Something went wrong with [bish-bosh]; an assumption was violated |
| 69   | Unavailable |  Ping timed out. **CONNACK** had a connection return code of 1 or 3 |
| 68   | Unknown Host | Not used presently |
| 67   | Unknown User | **CONNACK** had a connection return code of 2 |
| 66   |  | Not used |
| 65   | Data Error | Corrupt or unexpected data found in stored session state. |
| 64   | Incorrect command line | Command line switches omitted, contradictory or incorrectly specified |
| 2    |  | A shell builtin misbehaved |
| 1    |  | Something went wrong we didn't expect or couldn't intercept |
| 0    |  | Successful operation; connection disconnected cleanly |

## File Locations

### Configuration Locations
Anything you can do with a command line switch, you can do as configuration. But configuration can also be used with scripts. Indeed, the configuration syntax is simply shell script. Configuration files _should not_ be executable. This means that if you _really_ want to, you can override just about any feature or behaviour of [bish-bosh] - although that's not explicitly supported. Configuration can be in any number of locations. Configuration may be a single file, or a folder of files; in the latter case, every file in the folder is parsed in 'shell glob-expansion order' (typically ASCII sort order of file names). Locations are searched in order as follows:-

1. Global (Per-machine)
  1. The file `INSTALL_PREFIX/etc/bish-bosh/rc` where `INSTALL_PREFIX` is where [bish-bosh] has been installed.
  2. Any files in the folder `INSTALL_PREFIX/etc/bish-bosh/rc.d`
2. Per User, where `HOME` is your home folder path\*
  1. The file `HOME/.bish-bosh/rc`
  2. Any files in the folder `HOME/.bish-bosh/rc.d`
3. Per Environment
  1. The file in the environment variable `bishbosh_RC` (if the environment variable is set and the path is readable)
  2. Any files in the folder in the environment variable `bishbosh_RC_D` (if the environment variable is set and the path is searchable)
4. In `SCRIPTLETS`
  * Scriptlets are parsed in order they are found on the command line (`bish-bosh -- [SCRIPTLETS]…`)
5. Under the configuration setting `bishbosh_clientPath` or switch [`--client-path`](#configuration-tweaks)
  1. The file `servers/${bishbosh_server}/rc` where `bishbosh_server` is a configuration setting or the switch [`--server`](#mqtt-big-hitters)†
  2. Any files in the folder `servers/${bishbosh_server}/rc.d`†
  3. The file `servers/${bishbosh_server}/ports/${bishbosh_port}/rc` where `bishbosh_port` is a configuration setting or the switch [`--port`](#mqtt-big-hitters)‡
  4. Any files in the folder `servers/${bishbosh_server}/port/${bishbosh_port}/rc.d`‡
  5. The file `servers/${bishbosh_server}/ports/${bishbosh_port}/client-ids/_${bishbosh_clientId}/rc` where `bishbosh_clientId` is a configuration setting or the switch [`--client-id`](#mqtt-big-hitters)§
  6. Any files in the folder `servers/${bishbosh_server}/ports/${bishbosh_port}/client-ids/_${bishbosh_clientId}/rc.d`§

Nothing stops any of these paths, or files in them, being symlinks. This can be exploited to symlink together, say, port numbers 1883 and 8883, or client ids that share usernames and passwords, etc.

_\* An installation as a daemon using a service account would normally set `HOME` to something like `/var/lib/bishbosh`._

_† it is possible for a configuration file here to set `bishbosh_port` (or even `bishbost_clientId`), so influencing the search in 3 - 6._

_‡ It is possible for a configuration file here to set `bishbosh_clientId`, so influencing the search in 5 and 6._

_§ Note the leading `_` before `${bishbosh_clientId}`. This is to accommodate Client Ids that are empty or start with `.` or `..`._

### `/var`
We use a `/var` folder underneath where we're installed. If you've just cloned [bish-bosh] from [GitHub], then this is _within_ the clone.
* `/var/lib/bish-bosh/client` must be searchable for the user running `bish-bosh`. This `PATH` be changed with the [`--client-path PATH`](#configuration-tweaks) option or [`bishbosh_clientPath='PATH'`](#configuration-tweaks) configuration setting. Ordinarily, it needs to be writable _unless_ you've created the entire servers, ports and client-ids structure in advance.
* `/var/spool/bish-bosh/session` must be searchable and writable for the user running `bish-bosh`. This `PATH` be changed with the [`--session-path PATH`](#configuration-tweaks) option or [`bishbosh_sessionPath='PATH'`](#configuration-tweaks) configuration setting.
* `/var/run/bish-bosh/lock` must be searchable and writable for the user running `bish-bosh`. This `PATH` be changed with the [`--lock-path PATH`](#configuration-tweaks) option or [`bishbosh_lockPath='PATH'`](#configuration-tweaks) configuration setting. You may want to change this location to `/var/lock` on Linux, or mount this path with a temporary file system.

### `/etc`
We use a `/etc` folder underneath where we're installed. If you've just cloned [bish-bosh] from [GitHub], then this is _within_ the clone.
* `/etc/bish-bosh/paths.d` is optional, but must be a readable and searchable folder if present.
* `/etc/bish-bosh/rc.d` is optional, but must be a readable and searchable folder if present.
* `/etc/bish-bosh/rc` is optional, but must be readable, non-empty file if present.

### `/tmp`: Temporary Files
* There must be a writable temporary folder (eg `/tmp`; we use whatever `mktemp` does), ideally mounted on an in-memory file system (eg tmpfs).
* Every client connection will create a very small amount of data in the temporary structure (mostly FIFOs and folders).
* Additionally, clients connecting with Clean Session = 1 will store all their data inside temporary folders; if messages are large, then this will consume more data.
* If so desired, other paths below can be symlinked to temporary folders.

### `/dev`: Devices
* `/dev/null` must be present and permission available for reading and writing to.
* one of `/dev/urandom` or `/dev/random` may be required if generating random ids (only used if `openssl` or `gnupg` is not available)
* If using serial devices with [`--transport serial`](#source-routing-settings) then the character device file `DEVICE` you specify to [`--server DEVICE`](#mqtt-big-hitters) must exist on the file system and be readable/writable.

### Unix domain sockets
* If using unix domain sockets with [`--transport unix`](#source-routing-settings) then the unix domain socket file `SOCKET` you specify to [`--server SOCKET`](#mqtt-big-hitters) must exist on the file system and be readable/writable.

## Dependencies
[bish-bosh] tries to use as few dependencies as possible, but, since this is shell script, that's not always possible. It's compounded by the need to support the difference between major shells, too. It also does its best to work around differences in common binaries, by using feature detection, and where it can't do any better, by attempting to install using your package manager.

### Required Dependencies
All of these should be present even on the most minimal system. Usage is restricted to those flags known to work across Mac OS X, GNU, BusyBox and Toybox. Even the most minimal system is likely to have these:-

* `mkdir`
* `mktemp`
* `mv`
* `rm`
* `rmdir`
* `sleep`
* `ln`

The following are needed if not builtin to your shell (except for `kill`, this would be highly unusual):-

* `[`, any POSIX-compliant version
* `echo`, any version (we do not use this with string escapes)
* `kill`, any POSIX-compliant version.
* `printf`, any POSIX-compliant version
* `pwd`, any POSIX-compliant version
* `true` and `false`

If cloning from [GitHub], then you'll also need to make sure you have `git`.

### Either Or Dependencies (one is required)
These are listed in preference order. Ordinarily, [bish-bosh] uses the `PATH` and feature detection to try to find an optimum dependency. Making some choices, however, influences others (eg `hexdump` and `od` preferences change when `stdbuf` is discovered, to try to use GNU `od`). Some choices are sub-optimal, and may cause operational irritation (mostly, bishbosh responds far more slowly to signals and socket disconnections).

* Various OS workarounds
  * `uname`, if trying to detect Toybox variants;
  * `uname`, to workaround AIX's broken `od` (not needed unless using AIX)
* Detecting which variety of netcat (`nc`) is in use by the meta-backend
  * Option 1
    * `sed`
  * Option 2
    * `head`
    * `grep`
  * Option 3
    * No detection, because the `nc` meta-backend isn't used (frankly, `socat` or `ncat` are much better).
* Publishing messages from files
  * `dd`, any POSIX-compliant version (dd is preferred as it permits larger block sizes)
  * `cat`
  * `tee`
  * `tail` (uses `-c +0`)
  * `head` (uses `-c`, which doesn't work in [Toybox])
  * `tr`
  * Nothing, if you do not need to publish messages from files (eg you are scripting them as shell strings)
    * Please note we can't use `printf '%s' "$(<"$1")"` because it strips trailing newlines and removes U+0000
* Creating FIFOs (named pipes)
* `mkfifo`, any POSIX-compliant version
* `mknod`, most except BSD-derived (GNU coreutils, [BusyBox], [Toybox] and [mksh]'s builtin are known to work)
* Binary to Hexadecimal conversion
  * `hexdump`, BSD-derived (part of the `bsdmainutils` package in Debian/Ubuntu; usually installed by default)
  * `hexdump`, in [BusyBox]
  * `hexdump`, in [Toybox]
  * `god`, from GNU `coreutils` package when installed on Mac OS X with Homebrew
  * `od`, from GNU `coreutils` package
  * `od` in [BusyBox] / [Toybox] / AIX / BSD-derived, with the following used to remove guff from `od`
    * `grep` (to remove trailing lines, and trailing lines with only whitespace)
	* `tr` (to remove extraneous spaces and tabs)
* Turning off buffering of hexadecimal conversion
  * `gstdbuf`, from GNU `coreutils` package when installed on Mac OS X with Homebrew
  * `stdbuf`, from the GNU `coreutils` package
  * `stdbuf`, FreeBSD
  * `unbuffer`, from the expect package (known as `expect-dev` on Debian/Ubuntu)
    * Does not seem to work properly on Mac OS X
  * `dd`, any POSIX-compliant version
* Unencrypted Network Connections (can be configured with the `--backends` option to use a different preference order)
  * `ncat`, part of the `nmap` package (available as `nmap` on Debian/Ubuntu and Mac OS X + Homebrew)
  * `socat` (not the beta version 2.0)
  * `nc6`, a predecessor of `ncat` (available as `nc6` on Debian/Ubuntu and Mac OS X + Homebrew)
  * `nc`, Debian Traditional variant (available as the `netcat-traditional` package on Debian/Ubuntu)
  * `nc`, Debian OpenBSD variant (available as the `netcat-openbsd` package on Debian/Ubuntu; usually installed by default)
  * `nc`, Mac OS X
  * `nc`, GNU (last known version 0.7.1 from 2004 tested)
  * `nc`, [BusyBox]
  * `nc`, [Toybox]
  * `bash` (if compiled with socket support; this is true for Mac OS X Snow Leopard+, Mac OS X + Homebrew, RHEL 6+, Centos 6+, Debian 6+, and Ubuntu 10.04 LTS +)
  * `ksh` ([ksh93], however [ksh93] doesn't work with other script features at this time)
  * none, if not using plain MQTT connections
* TLS-encrypted backends for MQTTS
  * `ncat`,
  * `socat`,
  * `openssl`, from [LibreSSL](http://www.libressl.org/)
  * `openssl`, from [OpenSSL](https://www.openssl.org/)
  * `gnutls`, from [GnuTLS](http://gnutls.org/)
  * none, if not using MQTTS
* cryptcat-encrypted backends
  * `cryptcat`
  * none, if not using `cryptcat`
* Keep Alives (only required if `bishbosh_connect_keepAlive` is not `0`)
  * `SECONDS` pseudo-environment variable if your shell supports it [GNU Bash], [mksh] and [pdksh] do)
    * Works slightly differently on [ksh93], as it uses 3 decimal places, but still effective
  * `date`, as long as it supports the `+%s` format string (true for GNU `coreutils`, [BusyBox], [Toybox] and Mac OS X)
  * Disabled and Keep Alive forced to 0 (with a warning)
* Validating UTF-8 strings
  * `iconv`, from the [GNU glibc] package
  * `iconv`, BSD-derived
  * `iconv`, from the [GNU libiconv] package
  * Nothing (validation not performed)
    * _Note: It is probably possible to use `bsdconv` instead of `iconv`. Raise an issue if that would be useful to you._
* Validating Topic Filter strings
  * `sed`
  * Nothing (validation not performed)
* Validating for invalid or restricted characters in topic names, topic filters and client ids
  * `tr`
  * Nothing (validation not performed)
* File sizes (controlled with [`--filesize-algorithm`](#configuration-tweaks), as feature detection is near impossible)
  * `ls`, any, used for file sizes (not efficient, but `ls -L -l -n FILE` is portable)
  * `stat`, from the GNU `coreutils` package
  * `stat`, in [BusyBox]
  * `stat`, BSD-derived
  * `stat`, in [Toybox], but does not work with symbolic links (No `-L` option)
* Random client-id generation (only for Clean Session = 1) \*
  * Nothing, if empty client ids are acceptable
  * `openssl`
  * `gpg`
  * `base64` (any version) and `tr`† (required to strip newlines from `base64`; different implementations have different switches for newlines), and one of
    * `dd` with access to either `/dev/urandom` or `/dev/random`
	* The shell's RANDOM psuedo-environment variable: not cryptographically robust
    * `awk` (any POSIX compliant-version): not cryptographically robust
  * Defaults to empty client id with a warning
* Coloured text (only when running in a terminal)
  * `tput` (assumes the `terminfo` database defined by POSIX; `termcap` is obsolete)
  * fallback to ANSI escape sequences, which should work on anything modern
  * Nothing, if not running in a terminal

_\* It may be possible to also use EGD sockets and other programs and sources (eg a TPM or `rng-tools`). Please get in touch if this is interesting to you._
_† It is probably possible to replace `base64` + `tr` with either `od` or `hexdump`. Get in touch if that would be useful to you._

### Optimal Choices
* For efficient reading
  * the use of GNU coreutils' `stdbuf` (or `gstdbuf`) and GNU coreutils' `od` (or `god`)
  * the use of a shell that supports read timeouts (`-t`)

### A word on [GNU Bash] versions
Unfortunately, there are a lot of [GNU Bash] versions that are still in common use. Versions 3 and 4 of Bash differ in their support of key features (such as associative arrays). Even then, Bash 4.1 is arguably not particularly useful with associative arrays, though, as its declare syntax lacks the `-g` global setting. [bish-bosh] tries to maintain compatibility with `bash` as at version 3.1/3.2, even though it's obsolescent, because it occurs on two common platforms. A quick guide to common bash version occurrence is below.

* bash 3.1+
  * Git-Bash
  * MinGW
* bash 3.2
  * Mac OS X
* bash 4.0
  * ChromeOS
* bash 4.1
  * Ubuntu 10.04 LTS
  * RedHat RHEL 6
  * Centos 6
  * Cygwin (as of Sep 2014, although 4.3 is in the works)
  * Solaris 11.2
* bash 4.2
  * Ubuntu 12.04 LTS
* bash 4.3
  * Ubuntu 14.04 LTS
  * Mac OS X + Homebrew

### A word on [suckless]
[bish-bosh] hasn't been tested with them, but should work using [suckless sbase](http://tools.suckless.org/sbase) and [suckless ubase](http://tools.suckless.org/ubase) for dependencies.

## Supported Configurations
The widely varying list of dependencies and preferences can be confusing, so here's a little guidance.

### Tested and works 'out-of-the-box'
* Windows
  * Cygwin 1.7.32
* Linux
  * Ubuntu 14.04
    * Tested on 14.04.1 LTS Server
    * Server install with `sshd` enabled
  * Ubuntu 12.04
    * Tested on 12.04.5 LTS Server
    * Server install with `sshd` enabled
  * Ubuntu 10.04
    * Tested on 10.04.4 LTS Server
    * Server install with `sshd` enabled
  * Debian 7
    * Tested on 7.7.0
  * Debian 6
    * Tested on 6.0.7
  * Centos 7
    * Tested on 7.0
    * From the 'minimal' DVD
  * Centos 6
    * Tested on 6.5
    * From the 'minimal' DVD
  * Centos 5
    * Tested on 5.11
    * From the DVD part 1
  * OpenSUSE 13.1
  * BusyBox on Ubuntu 14.04.1 LTS
    * _Note: BusyBox configurations will work on Debian/Ubuntu, too, and so can be used for boot-time [MQTT] activities._
* BSD-alike
  * Mac OS X 10.8 (Mountain Lion)
    * Unmodified
    * With [Homebrew]
  * FreeBSD 10.0
  * DragonFly BSD 3.8.2
    * You'll need to `pkg install netcat`
  * OpenBSD 5.5
  * MirBSD #10 (2008)
* AIX
  * AIX 7.1
    * Known Issues
      * Signal handling is broken in the AIX default shell; `CTRL-C` will result in unkilled processes
	* You need to install a backend, eg as `su`, install netcat `rpm --install http://www.oss4aix.org/download/RPMS/netcat/netcat-1.10-2.aix5.1.ppc.rpm`
  * AIX 6.1
    * As for AIX 7.1

### Tested and work with minor changes
* BSD-alike
  * NetBSD 6.1.5
    * You'll need to `pkg_add netcat`
    * You may need to modify the first line of `bish-bosh` to `#!/usr/bin/env ksh` (we had problems with `/etc/shrc` interfering)
* Solaris
  * 11.2
    * Solaris' default shell is [`ksh93`], which isn't POSIX compliant
	* Modify the first line of `bish-bosh` to `#!/usr/xpg4/bin/sh`, or,
	* Change your PATH so `/usr/xpg4/bin` comes before `/usr/bin`.
	* Please note the following shells have issues:-
	  * `/usr/gnu/bin/sh`, works ***only*** for the `devtcp` backend
	  * `/usr/bin/bash`, works ***only*** for the `devtcp` backend
    * The following shells do not work at all as they are [`ksh93`]:-
	  * `/usr/bin/sh`
	  * `/usr/bin/ksh`

### Untested, but should work
* Linux
  * RHEL 7 (nearly identical to Centos)
  * RHEL 6.5
  * Chrome OS
* BSD-alike
  * Mac OS X 10.9 (as nothing much has changed underneath)
  * Mac OS X 10.10

### Not Tested Yet
* Unix
  * HP_UX 11i
    * HP's `mktemp` fails, badly. Without HP-UX access, making this work is a non-starter.
  * Solaris 10
  * Minix 3.3.0
* Android 4

### Might Work
These configurations can be made to work if there's enough interest, but are unlikely to be optimal.

* Windows
  * MKS Toolkit
  * Interix
    * No `env`
    * No `bash`, no `nc`, so not obvious what can be used to create a socket
	* We could try to snaffle from Debian-Interix and Gentoo-prefix, but Interix is officially dead

### Can Not Work
These configurations can not work without _a lot_ of re-engineering, and, even then, would be barely functional. That said, if you have an use case to make them work, get in touch. Nothing's impossible. That said, for Windows, why not just use Cygwin?

* Windows
  * Git-Bash 1.9.4
    * Lacks any way of creating FIFOs (`mkfifo` / `mknod`)
	* Lacks any hexadecimal conversion (`od` / `hexdump`)
	* Lacks `dd` for a poor man's buffering
	* Alternatives
	  * Does have `wc`, `head` and `tail`, so it might be possible to have a poor man's FIFOs
	  * Also has `tclsh`
  * MinGW / MSYS (with `msys-base`, `mingw32-base`, `msys-mktemp`, `msys-openssl`)
	* Script stack dumps - no indication why
    * Similar to Git-Bash but does have `od`
  * [GOW](https://github.com/bmatzelle/gow) 0.8
    * `mkfifo` is incapable of creating FIFOs, otherwise this _should_ work.
      * On 0.7 and 0.8, create `C:\Program Files (x86)\Gow\etc` (see [here](https://github.com/bmatzelle/gow/issues/65#issuecomment-16725415))
      * Run `bash` to get a shell (it's 3.1)!
	  * Change `PATH`, eg `PATH=/usr/bin:"$PATH"`
	  * `cp bash.exe sh.exe` (`ln -s` doesn't seem to work, it creates `.lnk` files)
  * [GnuWin32](http://gnuwin32.sourceforge.net/)
    * `mkfifo` is incapable of creating FIFOs, otherwise this _should_ work.
  * [UnxUtils](http://sourceforge.net/projects/unxutils/)
    * `mkfifo` is non-functional
  * DJGPP
    * This uses `bash` 2.04, which is just too old
  * UWIN
    * Uses [`ksh93`].

### Optimised

#### For Debian / Ubuntu
* Install one of `socat` or `nmap`.
* The default shell, `dash`, does not have native read timeouts or `/dev/tcp`. To switch to `bash`, do one of the following:-
  * Change your `PATH`, or
  * Edit the first-line of `bish-bosh` and change `sh` to `bash`, or
  * Change `/bin/sh` to point to `/bin/bash` (not really advisable)

#### For Mac OS X
* [Homebrew package manager](http://brew.sh/), with Homebrew recipes
  * `bash`, for bash 4.3
  * `coreutils`
  * `socat` or `ncat`
  * `git`, if cloning from [GitHub]

#### For BusyBox Embedded Use (as of version 1.22.1)
* BusyBox configured to use as builtins the list of required dependencies (above) and the following
  * `ash` ([GNU Bash]-like features aren't required)
  * `hexdump`
  * `dd`
  * `date`
* From GNU coreutils (because BusyBox doesn't have a builtin for stdbuf)
  * `stdbuf`
  * `od`
* From [GNU glibc] or [GNU libiconv]
  * `iconv`

#### For [Toybox] Embedded Use (as of 0.5.0)
* BusyBox configured to use as builtins the list of required dependencies (above) and the following
  * `hexdump`
  * `dd`
* `dash` shell

## Supported Shells
[bish-bosh] tries very hard to make sure it works under any POSIX-compliant shell. However, in practice, that's quite hard to do; many features on the periphery of POSIX compliance, are subtly different (eg signal handling during read). That can lead to a matrix of pain. We constrain the list to widely-used shells common in the sorts of places you'd want to use [bish-bosh]: system administration, one-off scripting, boot-time and embedded devices with no compiler toolchain. Consequently, we try to support in decreasing priority order:-

* The [Almquist]-derived shells, specifically
  * [DASH]
  * [BusyBox]'s ash
* [GNU Bash]
* The [ksh88]-derived shells
  * [pdksh] final version 5.2.14 of 1999
  * [pdksh] as modified by OpenBSD
  * [mksh]
  * [ksh88] as used in AIX

All of these shells support dynamically-scoped `local` variables, something we make extensive use of. Some of them also support read timeouts, which is very useful for making [bish-bosh] responsive. The [pdksh]-derived shells (including [mksh]) are challenging to support, as they're not in full POSIX compliance.

### Unsupported Shells

#### [zsh]
[bish-bosh] is not actively tested under [zsh] although it should work once the inevitable few bugs are fixed. [zsh] is a nice interactive shell, and good for scripting, too. In particular, it is the only shell where it's possible for the `read` builtin to read data containing Unicode `U+0000` (ACSCII `NUL` as was), and is also trully non-blocking. [bish-bosh] can not take advantage of these features yet, however.

#### [ksh93]
At this time, [ksh93] is known not to work and looks like a lot of work to make work. This means UWIN won't work, either.

#### Others
* [oksh], a Linux derivative of OpenBSD's ksh shell
* [yash]
* The original [ksh88]

## Status of Supported Backends

| Backend | Filename | Variant | Tunnels | Status | [`--transport inet4`](#source-routing-settings) | [`--transport inet6`](#source-routing-settings) | [`--transport unix`](#source-routing-settings) | [`--transport serial`](#source-routing-settings) | [Proxy](#proxy-settings)  | [`--source-server HOST`](#source-routing-settings) | [`--source-port PORT`](#source-routing-settings) |
| ------- | -------- | ------- | ------------ | ------ | ----------------------------------------------- | ----------------------------------------------- | ---------------------------------------------- | ------------------------------------------------ | ------------------------- | -------------------------------------------------- | ------------------------------------------------ |
| **openssl** | `gnutls` | [OpenSSL] / [LibreSSL] | `tls` | Fully functional | No | No | No | No | No | No | No |
| **ncat** | `ncat`| [Nmap ncat](http://nmap.org/ncat/) | `none`, `tls` | Fully functional‡ | Yes | Yes | Yes | No | `SOCKS4`, `SOCKS5` and `HTTP`. Usernames and passwords supported for `HTTP`, usernames only for SOCKS. | Yes | Yes | **nc6** | `nc6` | [netcat6](http://www.deepspace6.net/projects/netcat6.html) | `none` | Fully functional‡ | Yes | Yes | No | No | No | Yes | Yes |
| **socat** | `socat` | [socat](http://www.dest-unreach.org/socat/) | `none`, `tls` | Fully functional | Yes | Yes | Yes | Yes | `SOCKS4`, `SOCKS4a` and `HTTP`. Usernames are supported. | Yes | Yes |
| **nc** | 'Meta' backend | Any **nc\*** backend | `none` | Fully functional* | Yes† | Yes† | Yes† | Yes† | Yes† | Yes† | Yes† |
| **ncFreeBSD** | `nc` | FreeBSD | `none` | Fully functional | Yes | Yes | Yes | No | `SOCKS4`, `SOCKS5` and `HTTP`. Usernames only for `HTTP`. | Yes | Yes |
| **ncOpenBSD** | `nc` | OpenBSD | `none` | Fully functional | Yes | Yes | Yes | No | `SOCKS4`, `SOCKS5` and `HTTP`. Usernames only for `HTTP`. | Yes | Yes |
| **ncMirBSD** | `nc` | Mac OS X | `none` | Fully functional | Yes | Yes | Yes | No | `SOCKS4`, `SOCKS5` and `HTTP`. No usernames or passwords. | Yes | Yes |
| **ncMacOSX** | `nc` | Mac OS X | `none` | Fully functional | Yes | Yes | Yes | No | `SOCKS4`, `SOCKS5` and `HTTP`. No usernames or passwords. | Yes | Yes |
| **ncDebianOpenBSD** | `nc.openbsd` | [Debian OpenBSD](https://packages.debian.org/wheezy/netcat-openbsd) | `none` | Fully functional‡ | Yes | Yes | Yes | No | `SOCKS4`, `SOCKS5` and `HTTP`. Usernames only for `HTTP`. | Yes | Yes |
| **ncDebianTraditional** | `nc.traditional` or `netcat` (on DragonFly BSD, *sic*) | [Debian Traditional](https://packages.debian.org/wheezy/netcat-traditional) / [Hobbit](http://nc110.sourceforge.net/) | `none` | Fully functional | Yes | Yes | No | No | No | Yes | Yes |
| **ncSolaris** | `nc` | Solaris | `none` | Fully functional | Yes | Yes | Yes | No | `SOCKS4`, `SOCKS5` and `HTTP`. Usernames only for `HTTP`. | Yes | Yes |
| **ncGNU** | `nc` | [GNU](http://netcat.sourceforge.net/) | `none` | Fully functional | No | No | No | No | No | Yes | Yes |
| **ncToybox** | `nc` / `toybox nc` / `toybox-$(uname)` /  | [Toybox] | `none` | Fully functional‡ | No | No | No | Yes | No | Yes | Yes |
| **ncBusyBox** | `nc` / `busybox nc` | [BusyBox] | `none` | Fully functional‡ | No | No | No | Yes | No | No | Yes |
| **devtcp** | `bash` / `ksh` | [GNU Bash] / [ksh93] | `none` | Fully functional | No | No | No | ? maybe ? | No | No | No |
| **cryptcat** | `cryptcat` | - | MQTT Encryting variant of netcat, but, because the password is supplied on the command line, insecure. |
| **gnutls** | `gnutls` | [OpenSSL] / [LibreSSL] | `tls` | Broken | No | No | No | No | No | No | No |

_\* Refers to the meta backend itself. A detected backend may not be._

_† Yes, if the detected variant of the backend does._

_‡ Does not respond to 'Ctrl-C'._

Please note that all backends do not respond well to 'Ctrl-C' being sent to a process group, or `SIGINT` (some die early, some never die). It is best to terminate by sending `TERM` to [bish-bosh], eg using `kill`.

### Unimplemented Backends
If you have a particular need to use these approaches to connecting to MQTT servers, raise an issue and I'll consider it. None of them are widely used or offer particularl advantages.

| Backend | Filename | Home Page | Notes |
| ------- | -------- | --------- | ----- |
| **tcpclient** | `tcpclient` | [ucspi-tcp](http://cr.yp.to/ucspi-tcp.html) and [Debian uscpi-tcp-ipv6](https://packages.debian.org/wheezy/ucspi-tcp-ipv6) | Executes a program on connection, which does not suit our model. Does not offer any proxy support. Not widely used. |
| **sbd** | ? | [Homepage Dead, but links still around](http://www.usinglinux.org/net/sbd.html) and [here](http://linux.softpedia.com/get/System/Networking/sbd-14900.shtml) | Also known as 'sbd for linux' and 'Shadowinteger's Backdoor'. [Was here](http://tigerteam.se/dl/sbd/) |
| **pnetcat** | `pnetcat` | [Home](http://stromberg.dnsalias.org/~strombrg/pnetcat.html) | BSD-like licence, but web page infers mis-distribution. Implemented in Python, which whilst interesting, mitigates against the point of [bish-bosh]. |
| **nc.pl** | ? | ? | There are also perl implementations of netcat. Just as for **pnetcat**, it seems a moot choice. |
| **ncSslCapable** | `scnc` | [SSL-capable netcat](http://www.gomor.org/bin/view/GomorOrg/SslNetcat) | Another perl implementation. Might be worth adding if only for the SSL support. |
| **sslio** | `sslio` |  [ipvsd](http://smarden.org/ipsvd/sslio.8.html) | Effectively a wrapper around **tcpclient**. |

## Limitations

### suid / sgid
bish-bosh explicitly tries to detect if run with suid or sgid set, and will exit as soon as possible with an error. It is madness to run shell scripts with such settings.

### Specification Violations

#### Client Ids
* To accommodate empty client ids, and those matching reserved file names (typically `.` and `..`), we prefix client ids in our file paths with `_`.
* We do not permit client ids to exceed 254 bytes. This is because client ids can not exceed the maximum file name size of a file system, and most modern file systems support a maximum size of either 255 bytes or 255 UTF-8 code points (except HFS+).

#### Topic Names and Topic Filters
* Shell builtins and most common tools do not support parsing lines delimited with anything other than `\n` (eg `sed`). Whilst some tooling (eg GNU coreutils, [GNU Bash]) can handle `\0` terminated lines, support is not consistent enough. Consequently:-
  * When sending **PUBLISH** control packets, topic names can not contain `\n`.
  * When sending **SUBSCRIBE** and **UNSUBSCRIBE** control packets, topic filters can not contain `\n` (this may be relaxed in the future, as the underlying code is now `\n` aware).
* However, when receiving **PUBLISH** control packets, `\n` is permitted but won't be correctly encoded if it is the final character in the `topicName` variable (but you can obtain the correct topic in the `topicNameFilePath`).

### Broken but Fixable
* Connection tear down is likely to lead to will messages being sent with some backends due to problems with signal handling.

### Useful to do
* nextPacketIdentifier, set at start, and calculate better
* Turning off DNS resolution
* [MQTT] over SSH
	* As a SOCKS4 or SOCKS5 client (eg using socat)
	* With OpenSSH local port forwarding
* [MQTT] over WebSockets
* More tools
	* reverse shell using GAWK! http://www.gnucitizen.org/blog/reverse-shell-with-bash/#comment-122387
* Need a simple way to send messages from disk on start
* Need to automatically re-subscribe on start
* Need to support connecting more than once (ie connection recycling) so that we can script clean-session resets
* Fattening and Travis

### Ideas
* byobu vs tmux vs screen for multiple viewing (or support all 3 in a complex manner [byobu requires newt])
* newt (whiptail) vs dialog: both in Centos 6.4 default, ? only whiptail in Ubuntu minimal
* auth backends * ldap, ?pam, local users file
* generic SOCKS handling via tsocks or proxychains*ng
* .netrc for proxy password details?
* .curlrc for proxy details?
* .wgetrc for proxy details?
* proxy env variables (originated in wget)
  * typical values are http_proxy=https://USER@PASSWORD:ADDRESS:PORT/
  * would need to parse no_proxy="test.mosquitto.org,127.0.0.1,localaddress,.localdomain.com" and https_proxy, too.

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
[GNU glibc]: https://www.gnu.org/software/libc/ "GNU libc"
[GNU libiconv]: https://www.gnu.org/software/libiconv/ "GNU libiconv"
[stunnel]: https://www.stunnel.org/index.html "stunnel"
[shellfire]: https://github.com/shellfire-dev/shellfire "shellfire home page"
[swaddle]: https://github.com/raphaelcohn/swaddle "swaddle home page"
