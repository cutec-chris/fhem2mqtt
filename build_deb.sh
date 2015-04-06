Program=fhem2mqtt
Archfpc=$1
if [ "x$Archfpc" = "x" ]; then
  Arch=`dpkg --print-architecture`
  Archfpc=$(fpc -h | grep 'Compiler version' | sed 's/.*for \([^ ]\+\)$/\1/')
fi
if [ "x$Arch" = "x" ]; then
  if [ "x$Archfpc" = "xx86_64" ]; then
    Arch=amd64
  fi
  if [ "x$Arch" = "x" ]; then
    Arch=$Archfpc
  fi
fi
sudo -S echo "Arch is $Arch"
echo "Archfpc is $Archfpc"
Year=`date +%y`
Month=`date +%m`
Day=`date +%d`
Date=20$Year$Month$Day
TmpDir=/tmp
BuildDir=$TmpDir/software_build

rm -rf $BuildDir
mkdir -p $BuildDir/usr/share/doc/$Program/
echo "copyright and changelog files..."
cp debian/changelog.Debian $BuildDir/usr/share/doc/$Program/
cp changes.txt $BuildDir/usr/share/doc/$Program/changelog
cp debian/copyright $BuildDir/usr/share/doc/$Program/
gzip --best $BuildDir/usr/share/doc/$Program/changelog
gzip --best $BuildDir/usr/share/doc/$Program/changelog.Debian
chmod 644 $BuildDir/usr/share/doc/$Program/*
echo "creating installation..."
mkdir -p $BuildDir/usr/bin/
echo "copy to builddir..."
cp output/$Archfpc-linux/$Program $BuildDir/usr/bin/$Program
DebSize=$(du -s $BuildDir | cut -f1)
echo "fixing permissions ..."
sudo -S find $BuildDir -type d -print0 | xargs -0 sudo -S chmod 755  # this is needed, don't ask me why
sudo -S find $BuildDir -type f -print0 | xargs -0 sudo -S chmod a+r  # this is needed, don't ask me why
sudo -S chown -hR root:root $BuildDir/usr
echo "creating control file..."
mkdir -p $BuildDir/DEBIAN
cat debian/control | \
  sed -e "s/VERSION/$Date/g" \
      -e "s/ARCH/$Arch/g" \
      -e "s/DEBSIZE/$DebSize/g" \
  > $BuildDir/DEBIAN/control
chmod 755 $BuildDir/DEBIAN
echo "building package..."
sudo -S dpkg-deb --build $BuildDir
cp $TmpDir/software_build.deb output/${Program}_${Date}_${Arch}.deb
echo "cleaning up..."
sudo -S rm -r $BuildDir
