#!/usr/bin/env sh
set -e
set -u

if [ -t 1 ]; then
	printf '%s\n' 'This script will install the apt repository bish-bosh' 'It will change your apt keys, create or replace /etc/apt/sources.list.d/00bish-bosh.sources.list, install apt-transport-https and update apt.' 'Press the [Enter] key to continue.'
	read -r garbage
fi

sudo -p "Password for %p to allow root to update from new sources before installing apt-transport-https: " apt-get --quiet update
sudo -p "Password for %p to allow root to  apt-get install apt-transport-https (missing in Debian default installs)" apt-get install apt-transport-https

temporaryKeyFile="$(mktemp --tmpdir bish-bosh.key.XXXXXXXXX)"
trap 'rm -rf "$temporaryKeyFile"' EXIT HUP INT QUIT TERM
cat >"$temporaryKeyFile" <<EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

mQINBFTEqz0BEAC+u8LEzm+onHfaLHbUydickMVph+pt4I4BEucJK9J74GN10sNZ
2MzKq2EXbdOCwNMrPh7AB066bhQt2uF8J115zmOZPJbboKQfzBSS6oVXUyEzPJRh
CLjsRIbhXWLZdDBE4bB0gNJIBSQoVDXiieVU2tl7nbL1uCzvTWZyfSWLU+yW+No1
yk+7whfi6Tdp9+IfDKF/gghPrxF976SKOrqSvSyJ53jh148cH8CS8Jqo0pd9OOWO
cr9I/IFY0rRiYwreFrGkwfHHt8oawcz38747uizKE3GERQLGCzoFyFdPS/QbantS
ydG3yKtFQXqzpFPa1ImJ4SKRyFDq6vbhnotMXK9Tnfc+66EE15xNM4HQe14i49d2
7up/owOy5Ayfg1Ttm6kSn1WoRxQiXAu5+KzRG0t50q+bN5N9TSNTQY+jipACM44e
pby0UzfD2mH3yMj+41MXUGeib0xuzrfkRGC5T8eO9C7o2K/kkzhkzUKQNWwzo9Tq
6cw3Y2oWdzWxkwizI5OhWnumDE+6z91zZ44knZTjr0Fqh4TB+1xUEz6LM3Bn0RsD
iboS0zvGCIOMX2PGT/PxxKlc9jGRs6MY/aMkxcf5qo6P006W2ETPzfRzKmbZPeuw
WhJJ4a3D3ek0dik+oiogpK2lgpZCUiwvb17kYwRpMYStK00efwKO5V4zewARAQAB
tDxSYXBoYWVsIENvaG4gKExhcHRvcCBTaWduaW5nIEtleSkgPHJhcGhhZWwuY29o
bkBzdG9ybW1xLmNvbT6JAjgEEwECACIFAlTEqz0CGwMGCwkIBwMCBhUIAgkKCwQW
AgMBAh4BAheAAAoJEN/7cMj1uTSKwpcQAKM8wk7gacERghk/lA02TySfVvSdCqQn
3j/qHkIfNOKKOp9yY1Fr6WK6EMLjRNgeiibb73/phG941LVfaLXzFfm0l6y6XpoP
Qj1bd2czeJz1ljOROyUnHnaXqGAn3+WnYmUkNKbHmPukrxcsAv0UF3hfp8pciY8J
W0K7BZ6qSha1+IqmvkrtcpWU0m4hauZvkYhEc8YZB6BgncHFJKfz/co7qOUsimHG
3aw942p617RDCG0U+Pqay4MyZARrg5L/yIVmFmGuZPrv8+OKZ6KIOQsWRPCpb+Go
FeRWCFvYR4KoO3InN7uM9BtVAkXffsdSuA+Fj+ubWF9yr9ocITHZUTHqI5vMDeDI
CusnAS3CwIETvXF1nPwW/zGs1bLW3vGeKE6g3D74XqhfTFjqAjJYeK5Xyw/IxTSD
KMxn2oVMXNR0Q7PD/sGbkYmJpjSZaJ15/VIfJM/L4M7mjA7DLpSz5R374u0e384E
cYsgcvyaQUgUJ8zY7tlmlKCt+32a8FA4cPYbs7QIrDK4LcqgmN/elmTxkUkF5A0y
pdstdy0yXQYngKCairGek3BY3BRygcatFHR9O4UEmHATLIvWRlYzmSraL84wY/tV
zNBZJbR9ReWtmAxlABe5N6BAr7XLx3ACmZ+4IZan8j1U4LoRyFSUd+beMzcUWw2m
DobAXHD09vQn
=D0m4
-----END PGP PUBLIC KEY BLOCK-----
EOF
sudo -p "Password for %p is required to allow root to install repository 'bish-bosh' public key to apt: " apt-key add "$temporaryKeyFile"

echo 'deb https://raphaelcohn.github.io/bish-bosh/download/apt bish-bosh multiverse' | sudo -p "Password for %p is required to allow root to install repository 'bish-bosh' apt sources list to '/etc/apt/sources.list.d/00bish-bosh.sources.list': " tee /etc/apt/sources.list.d/00bish-bosh.list >/dev/null
sudo -p "Password for %p to allow root to update from new sources: " apt-get --quiet update
