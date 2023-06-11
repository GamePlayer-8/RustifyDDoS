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

apt install --yes pkg-config libssl-dev openssl rustc cargo git linux-headers-$(uname -r) build-essential xvfb appstream tar lsb-release apt-utils file > /dev/null

Xvfb -ac :0 -screen 0 1280x1024x24 &
sleep 5

cargo build --release
mv target/release/rddos ./rddos-glibc
rm -rf target

strip rddos-glibc

chmod +x rddos-glibc

mkdir -p rddos.AppDir/var/lib/dpkg
mkdir -p rddos.AppDir/var/cache/apt/archives
apt install --yes debootstrap fakeroot fakechroot
fakechroot fakeroot debootstrap --variant=fakechroot --arch amd64 22.04 /source/rddos.AppDir/ http://archive.ubuntu.com/ubuntu > /dev/null

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
echo 'Exec=/usr/bin/rddos' >> rddos.AppDir/rddos.desktop

chmod +x rddos.AppDir/rddos.desktop

echo '#!/bin/sh' > rddos.AppDir/AppRun
echo 'rddos_RUNPATH="$(dirname "$(readlink -f "${0}")")"' >> rddos.AppDir/AppRun
echo 'rddos_EXEC="${rddos_RUNPATH}"/usr/bin/rddos' >> rddos.AppDir/AppRun
echo 'export LD_LIBRARY_PATH="${rddos_RUNPATH}"/lib:"${rddos_RUNPATH}"/lib64:$LD_LIBRARY_PATH' >> rddos.AppDir/AppRun
echo 'export LIBRARY_PATH="${rddos_RUNPATH}"/lib:"${rddos_RUNPATH}"/lib64:"${rddos_RUNPATH}"/usr/lib:"${rddos_RUNPATH}"/usr/lib64:$LIBRARY_PATH' >> rddos.AppDir/AppRun
echo 'export PATH="${rddos_RUNPATH}/usr/bin/:${rddos_RUNPATH}/usr/sbin/:${rddos_RUNPATH}/usr/games/:${rddos_RUNPATH}/bin/:${rddos_RUNPATH}/sbin/${PATH:+:$PATH}"' >> rddos.AppDir/AppRun
echo 'exec "${rddos_EXEC}" "$@"' >> rddos.AppDir/AppRun

chmod +x rddos.AppDir/AppRun

mkdir -p rddos.AppDir/usr/bin
cp rddos-glibc rddos.AppDir/usr/bin/rddos
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

mv rddos-x86_64.AppImage rddos-glibc-x86_64.AppImage

rm -rf rddos.AppDir
rm -f toolkit.AppImage
rm -rf rddos.egg-info
chmod +x rddos-glibc-x86_64.AppImage

sha256sum rddos-glibc > sha256sum.txt
sha256sum rddos-glibc-x86_64.AppImage >> sha256sum.txt

mkdir -pv /runner/page/
cp -rv /source/* /runner/page/
