#!/bin/bash

USER="guido"
GITHUB_ORIGIN="git@github.com:guido2mila/guido.git"

#some configurations
localectl set-keymap it
timedatectl set-timezone Europe/Rome
GTIME=$(cat /etc/default/grub | grep "GRUB_TIMEOUT=")
sed -i "s/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/" /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
sudo_config="$USER ALL=(ALL) NOPASSWD: ALL"
grep -q "$sudo_config" /etc/sudoers
if [ $? -eq 1 ]; then
  echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
systemctl stop firewalld
systemctl disable firewalld

#remove unused packages and update the system
#list for gnome: list_pkg=(cheese gnome-documents evolution firefox gnome-clocks gnome-maps gnome-weather shotwell seahorse gedit)
list_pkg=(firefox xfce4-clipman-plugin abiword libabiword xfce4-about asunder blueman gnome-bluetooth claws-mail fedora-release-notes clipman florence geany gnumeric leafpad orage parole pidgin pragha ristretto xfburn xfdashboard rygel)
for pkg_to_remove in "${list_pkg[@]}"
do
  dnf -y remove $pkg_to_remove
done

#remove some directories
rm -fr /home/guido/.mozilla /home/guido/Music /home/guido/Pictures /home/guido/Public /home/guido/Templates /home/guido/Videos
#rpm to install
dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm http://download.teamviewer.com/download/teamviewer.i686.rpm https://github.com/atom/atom/releases/download/v1.11.1/atom.x86_64.rpm
#update
dnf -y update

#packages to install
list_pkg=(vim gimp thunderbird vlc vagrant git)
for pkg_to_install in "${list_pkg[@]}"
do
  dnf -y install $pkg_to_install
done

#sublime txt
#wget https://download.sublimetext.com/sublime_text_3_build_3126_x64.tar.bz2
#tar xvjf sublime_text_3_build_3126_x64.tar.bz2
#mv sublime_text_3 /opt/sublime_text
#rm -f sublime_text_3_build_3126_x64.tar.bz2
#ln -s /opt/sublime_text/sublime_text /usr/bin/subl

#skype
dnf -y install alsa-lib.i686 fontconfig.i686 freetype.i686 glib2.i686 libSM.i686 libXScrnSaver.i686 libXi.i686 libXrandr.i686 libXrender.i686 libXv.i686 libstdc++.i686 pulseaudio-libs.i686 qt.i686 qt-x11.i686 zlib.i686 qtwebkit.i686
wget --trust-server-names http://www.skype.com/go/getskype-linux-dynamic
mkdir /opt/skype
tar xvf skype-4.3* -C /opt/skype --strip-components=1
rm -fr skype-4.3*
ln -s /opt/skype/skype.desktop /usr/share/applications/skype.desktop
for icon in /opt/skype/icons/*
do
  ressuffix="${icon##*_}"
  res="${ressuffix%%.*}"
  ln -s "$icon" /usr/share/icons/hicolor/"$res"/apps/skype.png
done
gtk-update-icon-cache /usr/share/icons/hicolor
cat << EOF > /usr/bin/skype
#!/bin/sh
export SKYPE_HOME="/opt/skype"
\$SKYPE_HOME/skype --resources=\$SKYPE_HOME \$*
EOF
chmod 755 /usr/bin/skype

#libreoffice
wget http://download.documentfoundation.org/libreoffice/testing/5.4.0/rpm/x86_64/LibreOfficeDev_5.4.0.0.beta1_Linux_x86-64_rpm.tar.gz
tar -xvf LibreOfficeDev_5.4.*
cd LibreOfficeDev_5.4.*
dnf -y install RPMS/*.rpm
rm -fr LibreOfficeDev_5.4.*

#chrome
rpm -qa | grep -q "google-chrome"
if [ $? -eq 1 ]; then
  cat << EOF > /etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome - \$basearch
baseurl=http://dl.google.com/linux/chrome/rpm/stable/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
EOF
  dnf -y install google-chrome-stable
fi

#virtualbox
rpm -qa | grep -q "VirtualBox"
if [ $? -eq 1 ]; then
  cd /etc/yum.repos.d/
  wget http://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo
  dnf -y install binutils gcc make patch libgomp glibc-headers glibc-devel kernel-headers kernel-devel dkms
  dnf -y install VirtualBox-5.1
  /usr/lib/virtualbox/vboxdrv.sh setup
  usermod -a -G vboxusers $USER
fi

exec sudo -i -u $USER /bin/bash - << EOF
cd /home/$USER
if [ ! -d .ssh ]; then
  mkdir .ssh
  chmod 700 .ssh
fi
touch .ssh/known_hosts
cat .ssh/known_hosts | grep -q "github.com"
if [ $? -eq 1 ]; then
  echo "github.com,192.30.253.112 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" >> .ssh/known_hosts
  chmod 644 .ssh/known_hosts
fi
ls .ssh/ | grep -q id_rsa
if [ $? -eq 1 ]; then
  echo "-----BEGIN RSA PRIVATE KEY-----
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
-----END RSA PRIVATE KEY-----" > .ssh/id_rsa
  chmod 600 .ssh/id_rsa
fi

if [ ! -d Documents/.git ]; then
  #git config
  git config --global user.name "guido"
  git config --global user.email "guido2mila@gmail.com"
  git config --global core.editor "vim"
  git config --global merge.tool "vimdiff"
  git config --global color.ui "true"
  git config --global push.default "simple"
  git remote add origin $GITHUB_ORIGIN

  #solo la prima volta per popolare il repository git
  #cd ~/Documents
  #git init
  #mkdir configs
  #mv ~/.bashrc ~/Documents/configs/.bashrc
  #ln -s ~/Documents/configs/.bashrc ~/.bashrc
  #mv ~/.bashrc ~/Documents/configs/.bash_profile
  #ln -s ~/Documents/configs/.bashrc ~/.bash_profile
  #git add .
  #git commit -m "Initial configuration commit"
  #git push -u origin master

  git clone $GITHUB_ORIGIN ~/Documents
  rm -f ~/.bashrc
  ln -s ~/Documents/configs/.bashrc ~/.bashrc
  rm -f ~/.bash_profile
  ln -s ~/Documents/configs/.bashrc ~/.bash_profile
fi
EOF
