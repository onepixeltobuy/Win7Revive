# RetroNova – lekki system w stylu Windows 7 / XP

Debian 12 + Xfce, motyw Win7 lub XP, ok. 400–600 MB RAM po starcie.

## Budowa (na Debianie/Ubuntu/Mint, z internetem, ok. 20–40 min)
    sudo ./build.sh amd64 win7     # lub: amd64 xp / i386 xp
Wynik: `retronova/live-image-amd64.hybrid.iso` – nagraj na pendrive (Rufus, balenaEtcher, `dd`).

## Co jest w środku
- **Dokumenty:** Thunar, Atril (PDF), AbiWord, Gnumeric, Mousepad
- **.iso:** otwieranie/montowanie obrazów (fuseiso, GNOME Disks), nagrywanie (Xfburn), Thunar + File Roller (7z/zip)
- **Dźwięk:** PulseAudio, pavucontrol, Audacious, VLC
- **Wydajność:** zRAM (zstd), swappiness 10, wyłączone Bluetooth/CUPS/Avahi, kompozycja okien wyłączona, preload
- **Gry:** ikona „Zainstaluj Minecraft i Roblox” na pulpicie (PrismLauncher + Sober)

## Ważne ograniczenia (uczciwie)
- **Roblox** nie ma oficjalnego klienta dla Linuxa. Działa przez nieoficjalny **Sober**: tylko 64-bit,
  potrzebuje GPU z OpenGL/Vulkan i sensownych ~4 GB RAM. Na bardzo starych PC może nie ruszyć.
- **Minecraft Java** działa dobrze: Java 17 jest w systemie. Na słabym sprzęcie użyj Fabric + Sodium + Lithium
  albo wersji 1.8.9–1.12. Na 32-bit (i386) tylko starsze wersje.
- **Dźwięki startowe Windows** są chronione prawem autorskim, więc ich nie dołączono.
  Wrzuć własne/wolne pliki .oga do `/usr/share/sounds/retronova/stereo/`.
- Motywy pochodzą z repozytoriów B00merang-Project/Artwork na GitHubie (pobierane przy budowie);
  jeśli któreś zniknęło, Xfce użyje domyślnego motywu – podmień linki w `build.sh`.
- Pasek zadań „à la Windows” ustawia się przy pierwszym logowaniu; wygląd menu Start dopracujesz
  w Ustawienia → Panel (Whisker Menu).
