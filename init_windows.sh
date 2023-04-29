#!/bin/sh

export TZ="Europe/Warsaw"
export DEBIAN_FRONTEND=noninteractive

apt update > /dev/null
apt install --yes markdown > /dev/null
cd /source

echo '<!DOCTYPE html>' > index.html
echo '<html lang="en-US">' >> index.html
cat docs/head.html >> index.html

echo '<body>' >> index.html
markdown README.md >> index.html
echo '</body>' >> index.html
echo '</html>' >> index.html

apt install --yes rust cargo git apt-utils build-essential curl tar wget xvfb > /dev/null

Xvfb -ac :0 -screen 0 1280x1024x24 &
sleep 5

rustup target add x86_64-pc-windows-gnu
cargo build --release --target x86_64-pc-windows-gnu
mv target/release/rddos.exe .
rm -rf target

chmod +x rddos.exe

sha256sum rddos.exe > sha256sum.txt

mkdir -pv /runner/page/
cp -rv /source/* /runner/page/
