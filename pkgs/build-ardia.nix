{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  adwaita-icon-theme,
  gsettings-desktop-schemas,
  gtk3,
  gtk4,
  libX11,
  libXScrnSaver,
  libXcomposite,
  libXcursor,
  libXdamage,
  libXext,
  libXfixes,
  libXi,
  libXrandr,
  libXrender,
  libXtst,
  libdrm,
  libkrb5,
  libuuid,
  libxkbcommon,
  libxshmfence,
  libgbm,
  libxcb,
  nspr,
  nss,
  pango,
  pipewire,
  snappy,
  udev,
  wayland,
  xdg-utils,
  coreutils,
  zlib,
  curl,
  libpulseaudio,
  libGL,
  libva,
}:

{
  pname,
  version,
  hash,
  url,
  commandLineArgs ? "",
}:

let
  deps = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    gtk4
    libdrm
    libX11
    libGL
    libxkbcommon
    libXScrnSaver
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libxshmfence
    libXtst
    libuuid
    libgbm
    libxcb
    nspr
    nss
    pango
    pipewire
    udev
    wayland
    zlib
    snappy
    libkrb5
    libpulseaudio
    libva
    stdenv.cc.cc.lib
  ];

  rpath = lib.makeLibraryPath deps + ":" + lib.makeSearchPathOutput "lib" "lib64" deps;
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    inherit url;
    sha256 = hash;
  };

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = deps ++ [
    # needed for GSETTINGS_SCHEMAS_PATH / XDG_ICON_DIRS
    gsettings-desktop-schemas
    adwaita-icon-theme
  ];

  # Optional libs loaded with dlopen at runtime are covered by LD_LIBRARY_PATH below
  autoPatchelfIgnoreMissingDeps = [ "libQt5*" "libQt6*" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    # This .deb unpacks under ./root/ (root/usr/...), others unpack directly
    base=.
    if [ -d root/usr ] || [ -d root/opt ]; then base=root; fi

    # /usr/bin/ardia (launcher), /usr/lib/ardia (app), /usr/share (desktop entry, icons, polkit)
    if [ -d $base/usr ]; then cp -r $base/usr/. $out/; fi
    if [ -d $base/opt ]; then cp -r $base/opt $out/opt; fi

    # The Nix store cannot hold setuid files; Chromium falls back to user namespaces
    find $out -perm -4000 -exec chmod u-s {} +

    # Point absolute paths in launchers/desktop files at the store
    { grep -rIl -e '/usr/lib/ardia' -e '/usr/bin/ardia' -e '/opt/ardia' $out || true; } \
      | xargs -r sed -i \
          -e "s|/usr/lib/ardia|$out/lib/ardia|g" \
          -e "s|/usr/bin/ardia|$out/bin/ardia|g" \
          -e "s|/opt/ardia|$out/opt/ardia|g"

    # Wayland compositors identify the app through StartupWMClass
    for desktop in $out/share/applications/*.desktop; do
      [ -e "$desktop" ] || continue
      grep -q '^StartupWMClass=' "$desktop" || echo "StartupWMClass=ardia" >> "$desktop"
    done

    # Fail early, and show the layout, if it is not what we expect
    if [ ! -e $out/bin/ardia ]; then
      echo "Error: bin/ardia not found, .deb layout differs. Unpacked tree:"
      find . -maxdepth 5 -not -path './nix-support*' | head -80
      exit 1
    fi

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${rpath}
      --prefix PATH : ${lib.makeBinPath [ xdg-utils coreutils curl ]}
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
      ${lib.optionalString (commandLineArgs != "") ''--add-flags ${lib.escapeShellArg commandLineArgs}''}
    )
  '';

  meta = {
    homepage = "https://ardia.dev";
    description = "Chromium browser with Arc's sidebar and Dia's polish (Linux build)";
    license = lib.licenses.gpl3Only;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "ardia";
  };
}
