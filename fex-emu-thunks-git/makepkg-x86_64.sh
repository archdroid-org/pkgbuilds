#!/bin/bash
# Construct cross compiling packages from upstream ArchLinux
# x86_64 repositories to assist on building fex-emu thunks without having
# to cross compile all the required thunk dependencies.
#
# Usage example: ./makepkg-x86_64.sh mesa
# This will pull most mesa depencies and build packages for them
# with the prefix `x86_64-`, eg: x86_64-libdrm or x86_64-mesa
# the script will also ask you to install for every built package.
#
# I have found that the following packages pull all the needed dependencies
# for fex-emu thunks: mesa, alsa-lib, libxrandr
#
# Knowing the above, the following calls should be enough to re-package
# fex-emu thunk cross-compile dependencies for now:
#
# ./makepkg-x86_64.sh mesa
# ./makepkg-x86_64.sh alsa-lib
# ./makepkg-x86_64.sh libxrandr


if [ "$1" = "" ]; then
  echo "Please enter the package name: "
  read -r pkgname
else
  pkgname="$1"
fi

parent=$2

if [ "$parent" = "" ]; then
  echo "Processing $pkgname..."
else
  echo "Processing $pkgname from parent $parent..."
fi

pkgdesc=$(pacman -Si $pkgname | grep Description | cut -d: -f2 | xargs)
pkgrepo=$(pacman -Si $pkgname | grep Repository | cut -d: -f2 | xargs)
pkgarch=$(pacman -Si $pkgname | grep Architecture | cut -d: -f2 | xargs)
pkgurl=$(pacman -Si $pkgname | grep URL | sed "s@://@///@" | cut -d: -f2 | sed "s@///@://@" | xargs)
pkglicense=$(pacman -Si $pkgname | grep Licenses | cut -d: -f2 | sed 's/^ +//;s/ +$//')
pkgver=$(pacman -Si $pkgname | grep Version | cut -d: -f2 | xargs | sed 's/-[0-9\.]\+$//')
pkgrel=$(pacman -Si $pkgname | grep Version | cut -d: -f2 | xargs | sed 's/.*-\([0-9\.]\+\)$/\1/g')
dependencies=$(pacman -Si $pkgname | grep "Depends On" | cut -d: -f2)

if [ "$pkgarch" == "aarch64" ]; then
  pkgarch=x86_64
fi

for depend in $(echo "$dependencies" | xargs) ; do
  echo "Dependency: $depend"
  depend_clean=$(echo "$depend" | cut -d= -f1)
  depend_clean=$(echo "$depend_clean" | cut -d"<" -f1)
  depend_clean=$(echo "$depend_clean" | cut -d">" -f1)
  if [ "$depend_clean" = "None" ]; then
    break
  fi
  if
    [[
      ( "$depend_clean" != "glibc" )
      &&
      ( "$depend_clean" != "gcc-libs" )
      &&
      ( "$depend_clean" != "binutils" )
      &&
      ( "$depend_clean" != "linux-api-headers" )
      &&
      ( "$depend_clean" != "$parent" )
    ]]
  then
    if pacman -Si $depend_clean > /dev/null ; then
      if [ ! -d "x86_64-$depend_clean" ]; then
        $0 $depend_clean $pkgname
      fi
    elif pacman -Sq $depend_clean > /dev/null ; then
      depend_real_name=$(pacman -Sq $depend_clean | head -n1)
      if [ ! -d "x86_64-$depend_real_name" ]; then
        $0 $depend_real_name $pkgname
      fi
    fi
  fi
  pkgdepends="$pkgdepends x86_64-$depend_clean"
done

pkgbuild="# Maintainer: Automatically Generated
# To package use 'makepkg -d' to skip dependency checking
# and to install the resulting package 'pacman -Udd {package}.pkg.tar.zst'

_arch=x86_64
_target=\$_arch-linux-gnu
_pkgname=$pkgname
_pkgarch=$pkgarch
pkgname=\$_arch-\$_pkgname
pkgver=$pkgver
pkgrel=$pkgrel
pkgdesc=\"$pkgdesc \$_arch target\"
arch=(aarch64)
url='$pkgurl'
license=($pkglicense)
depends=($pkgdepends)
options=(!strip)
source=(\$_pkgname.tar.zst::https://archlinux.org/packages/$pkgrepo/\$_pkgarch/\$_pkgname/download)
sha256sums=('SKIP')

package() {
  mkdir -p \$pkgdir\"/usr/\$_target/sys-root\"
  rm \$srcdir/\$_pkgname.tar.zst
  cp -a \$srcdir/* \$pkgdir\"/usr/\$_target/sys-root/\"
}
"

pkgdir=x86_64-$pkgname

if [ ! -d $pkgdir ]; then
  mkdir $pkgdir
fi

if [ -d $pkgdir ]; then
  echo "$pkgbuild" > $pkgdir/PKGBUILD

  cd $pkgdir
  makepkg -d
  if ! pacman -Qs $pkgdir > /dev/null ; then
    sudo pacman -Udd *.pkg.tar.*
  fi
else
  echo "Error: package is not a directory."
  exit 1
fi
