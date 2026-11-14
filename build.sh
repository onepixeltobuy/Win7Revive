#!/usr/bin/env bash
# RetroNova - lekki system w stylu Windows 7 / XP (Debian 12 + Xfce) jako obraz .iso
# Uruchom na Debianie/Ubuntu/Mint z internetem:  sudo ./build.sh [amd64|i386] [win7|xp]
set -euo pipefail

ARCH="${1:-amd64}"     # i386 = bardzo stare PC (ale Roblox/Sober nie zadziala, tylko starsze Minecrafty)
THEME="${2:-win7}"     # win7 | xp
NAME="retronova"

[ "$(id -u)" -eq 0 ] || { echo "Uruchom jako root (sudo)."; exit 1; }
apt-get update
apt-get install -y live-build debootstrap debian-archive-keyring squashfs-tools xorriso git

# Ubuntu 25.10+ uzywa Rust-owych narzedzi (uutils), z ktorymi debootstrap/chroot bywa problematyczny.
if [ -f /etc/os-release ] && . /etc/os-release && [ "${ID:-}" = "ubuntu" ] && dpkg -s rust-coreutils >/dev/null 2>&1; then
  echo "UWAGA: wykryto rust-coreutils. Jesli budowa padnie na 'chroot', uruchom:"
  echo "  sudo apt install coreutils-from-gnu   i ponow budowe."
fi

# Ubuntu ma stare live-build 3.0 (buduje tylko Ubuntu) - uzyj nowego z Debiana, uruchamianego ze zrodel
LBSRC=/opt/live-build
if [ ! -f "$LBSRC/frontend/lb" ]; then
  rm -rf "$LBSRC"
  git clone --depth 1 https://salsa.debian.org/live-team/live-build.git "$LBSRC"
fi
export LIVE_BUILD="$LBSRC"
export PATH="$LBSRC/frontend:$PATH"
hash -r
echo "Uzywam live-build: $(lb --version 2>/dev/null || echo '?')"

mkdir -p "$NAME" && cd "$NAME"
lb clean --purge || true

lb config \
  --mode debian \
  --distribution bookworm \
  --architectures "$ARCH" \
  --archive-areas "main contrib non-free non-free-firmware" \
  --binary-images iso-hybrid \
  --debian-installer live \
  --bootappend-live "boot=live components quiet splash noautologin" \
  --iso-application "RetroNova" --iso-volume "RETRONOVA" \
  --apt-recommends false

if [ "$ARCH" = "i386" ]; then
  KERNEL="linux-image-686-pae"
else
  KERNEL="linux-image-amd64"
fi
echo "$KERNEL" > /dev/null

mkdir -p config/package-lists config/hooks/live config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml \
         config/includes.chroot/etc/sysctl.d config/includes.chroot/usr/local/bin config/includes.chroot/etc/skel/.config/autostart \
         config/includes.chroot/etc/skel/Desktop

# ---------- PAKIETY ----------
cat > config/package-lists/retronova.list.chroot <<EOF
$KERNEL
live-boot live-config
xorg lightdm lightdm-gtk-greeter
xfce4-panel xfce4-session xfce4-settings xfdesktop4 xfwm4 xfce4-whiskermenu-plugin
xfce4-pulseaudio-plugin xfce4-notifyd xfce4-terminal thunar thunar-archive-plugin thunar-volman
xfce4-taskmanager xfce4-screenshooter ristretto mousepad
network-manager network-manager-gnome
pulseaudio pavucontrol alsa-utils
firefox-esr
atril abiword gnumeric evince-common
file-roller p7zip-full unzip
fuseiso gnome-disk-utility udisks2 gvfs gvfs-backends xfburn
audacious vlc
mesa-vulkan-drivers mesa-utils libgl1-mesa-dri
openjdk-17-jre
flatpak
zram-tools preload
fonts-noto fonts-open-sans fonts-liberation2
git curl wget ca-certificates plymouth
numlockx xdg-utils
EOF

# ---------- OPTYMALIZACJA ----------
cat > config/includes.chroot/etc/sysctl.d/99-retronova.conf <<'EOF'
vm.swappiness=10
vm.vfs_cache_pressure=50
EOF
mkdir -p config/includes.chroot/etc/default
echo -e 'ALGO=zstd\nPERCENT=50' > config/includes.chroot/etc/default/zramswap

# ---------- DOMYŚLNY MOTYW XFCE ----------
if [ "$THEME" = "xp" ]; then GTK="Windows-XP"; WM="Windows-XP"; ICON="Windows-XP"; else GTK="Windows-7"; WM="Windows-7"; ICON="Windows-7"; fi
XF=config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
cat > $XF/xsettings.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="$GTK"/>
    <property name="IconThemeName" type="string" value="$ICON"/>
    <property name="EnableEventSounds" type="bool" value="true"/>
    <property name="SoundThemeName" type="string" value="retronova"/>
  </property>
</channel>
EOF
cat > $XF/xfwm4.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="$WM"/>
    <property name="use_compositing" type="bool" value="false"/>
    <property name="button_layout" type="string" value="O|HMC"/>
  </property>
</channel>
EOF

# Panel na dół + menu Start (jednorazowo przy 1. logowaniu)
cat > config/includes.chroot/usr/local/bin/retronova-firstlogin <<'EOF'
#!/bin/sh
[ -f "$HOME/.retronova_done" ] && exit 0
sleep 3
xfconf-query -c xfce4-panel -p /panels/panel-1/position -n -t string -s "p=8;x=0;y=0" 2>/dev/null
xfconf-query -c xfce4-panel -p /panels/panel-1/length -n -t double -s 100 2>/dev/null
xfconf-query -c xfce4-panel -p /panels/panel-1/size -n -t uint -s 36 2>/dev/null
xfconf-query -c xfce4-panel -p /panels/panel-1/position-locked -n -t bool -s true 2>/dev/null
xfce4-panel -r 2>/dev/null
touch "$HOME/.retronova_done"
EOF
chmod +x config/includes.chroot/usr/local/bin/retronova-firstlogin
cat > config/includes.chroot/etc/skel/.config/autostart/retronova-firstlogin.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=RetroNova first login
Exec=/usr/local/bin/retronova-firstlogin
EOF

# ---------- INSTALATOR GIER (Minecraft + Roblox) ----------
cat > config/includes.chroot/usr/local/bin/retronova-games <<'EOF'
#!/bin/sh
# Wymaga internetu. Instaluje PrismLauncher (Minecraft) i Sober (Roblox).
set -e
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub org.prismlauncher.PrismLauncher
if [ "$(uname -m)" = "x86_64" ]; then
  flatpak install -y flathub org.vinegarhq.Sober
else
  echo "Sober (Roblox) wymaga 64-bitowego systemu - pominieto."
fi
echo
echo "Minecraft: w Prism dodaj mody Sodium + Lithium (Fabric) lub uzyj wersji 1.8.9-1.12 dla slabych PC."
echo "Roblox: uruchom 'Sober' i zaloguj sie."
read -p "Enter aby zamknac..." _
EOF
chmod +x config/includes.chroot/usr/local/bin/retronova-games
cat > config/includes.chroot/etc/skel/Desktop/Zainstaluj-gry.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Zainstaluj Minecraft i Roblox
Exec=xfce4-terminal -e /usr/local/bin/retronova-games
Icon=applications-games
EOF
chmod +x config/includes.chroot/etc/skel/Desktop/Zainstaluj-gry.desktop

# ---------- HOOK: motywy, wyciszenie zbędnych usług ----------
cat > config/hooks/live/0100-retronova.hook.chroot <<EOF
#!/bin/sh
set -e
cd /usr/share/themes
git clone --depth 1 https://github.com/B00merang-Project/Windows-7.git Windows-7 || true
git clone --depth 1 https://github.com/B00merang-Project/Windows-XP.git Windows-XP || true
cd /usr/share/icons
git clone --depth 1 https://github.com/B00merang-Artwork/Windows-7.git Windows-7 || true
git clone --depth 1 https://github.com/B00merang-Artwork/Windows-XP.git Windows-XP || true
# fallback ikon gdyby klon sie nie udal
[ -d /usr/share/icons/$ICON ] || echo "UWAGA: brak ikon $ICON - Xfce uzyje domyslnych"
for s in bluetooth cups-browsed ModemManager avahi-daemon; do systemctl disable \$s 2>/dev/null || true; done
mkdir -p /usr/share/sounds/retronova/stereo
EOF
chmod +x config/hooks/live/0100-retronova.hook.chroot

lb build
echo "Gotowe: $(ls -1 *.iso)"
