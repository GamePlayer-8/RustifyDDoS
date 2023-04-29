#!/bin/sh

cp /etc/ssl/certs/ca-certificates.crt /

apk add --no-cache markdown > /dev/null
cd /source

echo '<!DOCTYPE html>' > index.html
echo '<html lang="en-US">' >> index.html
cat docs/head.html >> index.html

echo '<body>' >> index.html
markdown README.md >> index.html
echo '</body>' >> index.html
echo '</html>' >> index.html

apk add --no-cache openssl pkgconfig rustup cargo git linux-headers build-base xvfb appstream tar libc6-compat curl > /dev/null

cp /ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
rm -f /etc/ssl/cert.pem
ln -s /etc/ssl/certs/ca-certificates.crt /etc/ssl/cert.pem

# FIX CERTIFICATES
for X in $(find /usr -name *.pem); do
    rm -f "$X"
    ln -s /etc/ssl/cert.pem "$X"
done

GLIBC_REPO=https://github.com/sgerrand/alpine-pkg-glibc
GLIBC_VERSION=2.30-r0

for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION}; \
    do curl -sSL ${GLIBC_REPO}/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk
done

apk add --allow-untrusted --no-cache -f /tmp/*.apk > /dev/null
/usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib

# FIX CERTIFICATES
for X in $(find /usr -name *.pem); do
    rm -f "$X"
    ln -s /etc/ssl/cert.pem "$X"
done

Xvfb -ac :0 -screen 0 1280x1024x24 &
sleep 5

rustup-init -y
rustup target add x86_64-unknown-linux-musl
cargo build --release --target x86_64-unknown-linux-musl
mv target/release/rddos ./rddos-musl
rm -rf target

strip rddos-musl

chmod +x rddos-musl

wget -q https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/x86_64/apk-tools-static-2.12.10-r1.apk -O installer.apk

cd /
tar -xzf /source/installer.apk
cd /source

rm -f installer.apk
/sbin/apk.static -X https://dl-cdn.alpinelinux.org/alpine/latest-stable/main -U --allow-untrusted -p /source/rddos.AppDir/ --initdb add --no-cache alpine-base busybox libc6-compat

cd rddos.AppDir/
rm -rf etc var home mnt srv proc sys boot opt
cd ..

cp docs/icon.png rddos.AppDir/icon.png

echo '[Desktop Entry]' > rddos.AppDir/rddos.desktop
echo 'Name=rddos' >> rddos.AppDir/rddos.desktop
echo 'Categories=Settings' >> rddos.AppDir/rddos.desktop
echo 'Type=Application' >> rddos.AppDir/rddos.desktop
echo 'Icon=icon' >> rddos.AppDir/rddos.desktop
echo 'Terminal=true' >> rddos.AppDir/rddos.desktop
echo 'Exec=/lib/ld-musl-x86_64.so.1 /usr/bin/rddos' >> rddos.AppDir/rddos.desktop

chmod +x rddos.AppDir/rddos.desktop

echo '#!/bin/sh' > rddos.AppDir/AppRun
echo 'rddos_RUNPATH="$(dirname "$(readlink -f "${0}")")"' >> rddos.AppDir/AppRun
echo 'rddos_EXEC="${rddos_RUNPATH}"/usr/bin/rddos' >> rddos.AppDir/AppRun
echo 'export LD_LIBRARY_PATH="${rddos_RUNPATH}"/lib:"${rddos_RUNPATH}"/lib64:$LD_LIBRARY_PATH' >> rddos.AppDir/AppRun
echo 'export LIBRARY_PATH="${rddos_RUNPATH}"/lib:"${rddos_RUNPATH}"/lib64:"${rddos_RUNPATH}"/usr/lib:"${rddos_RUNPATH}"/usr/lib64:$LIBRARY_PATH' >> rddos.AppDir/AppRun
echo 'export PATH="${rddos_RUNPATH}/usr/bin/:${rddos_RUNPATH}/usr/sbin/:${rddos_RUNPATH}/usr/games/:${rddos_RUNPATH}/bin/:${rddos_RUNPATH}/sbin/${PATH:+:$PATH}"' >> rddos.AppDir/AppRun
echo 'exec "${rddos_RUNPATH}"/lib/ld-musl-x86_64.so.1 "${rddos_EXEC}" "$@"' >> rddos.AppDir/AppRun

chmod +x rddos.AppDir/AppRun

mkdir -p rddos.AppDir/usr/bin
cp rddos-musl rddos.AppDir/usr/bin/rddos
chmod +x rddos.AppDir/usr/bin/rddos

wget -q https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage -O toolkit.AppImage
chmod +x toolkit.AppImage

cd /opt/
/source/toolkit.AppImage --appimage-extract
mv /opt/squashfs-root /opt/appimagetool.AppDir
ln -s /opt/appimagetool.AppDir/AppRun /usr/local/bin/appimagetool
chmod +x /opt/appimagetool.AppDir/AppRun
cd /source

ARCH=x86_64 appimagetool rddos.AppDir/

rm -rf rddos.AppDir
rm -f toolkit.AppImage
rm -rf rddos.egg-info
chmod +x rddos-x86_64.AppImage
mv rddos-x86_64.AppImage rddos-musl-x86_64.AppImage

sha256sum rddos-musl > sha256sum.txt
sha256sum rddos-musl-x86_64.AppImage >> sha256sum.txt

mkdir -pv /runner/page/
cp -rv /source/* /runner/page/