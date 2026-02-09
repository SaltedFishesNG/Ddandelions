# https://github.com/NixOS/nixpkgs/issues/209545
{
  pkgs,
  buildFHSEnv,
}:
let
  pname = "crossover";
  version = "25.1.0";

  src = pkgs.fetchurl {
    url = "https://media.codeweavers.com/pub/${pname}/cxlinux/demo/${pname}_${version}-1.deb";
    sha256 = "e9a8fa09506fb53c10a943c890ffbd63c81f6f644a84631dbf8db35a61f37177";
  };

  # Unwrapped derivation
  crossover-dist = pkgs.stdenv.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [ pkgs.dpkg ];

    unpackPhase = "dpkg-deb -x $src .";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/opt
      cp -r opt/cxoffice $out/opt/cxoffice

      # Remove broken/unnecessary symlinks or files
      rm -f $out/opt/cxoffice/lib/nsplugin-linux64.so
      rm -rf $out/opt/cxoffice/doc
      mkdir -p $out/opt/cxoffice/doc

      # Move docs if they exist
      if [ -d usr/share/doc/crossover ]; then
        cp -r usr/share/doc/crossover/* $out/opt/cxoffice/doc
      fi

      # Configure bottle defaults
      sed -i $out/opt/cxoffice/share/crossover/bottle_data/cxbottle.conf \
        -e 's!;;"MenuRoot" = ""!"MenuRoot" = "Windows Games"!' \
        -e 's!;;"MenuStrip" = ""!"MenuStrip" = "1"!'

      # Fix configuration paths
      install -m 644 -D $out/opt/cxoffice/share/crossover/data/cxoffice.conf $out/opt/cxoffice/etc/cxoffice.conf
      sed -i $out/opt/cxoffice/etc/cxoffice.conf \
        -e 's!;;"PrivateShortcutDirs" = ""!"PrivateShortcutDirs" = "''${HOME}/bin:''${CX_ROOT}/bin"!' \
        -e 's!;;"PrivateLinuxNSPluginDirs" = ""!"PrivateLinuxNSPluginDirs" = "''${MOZ_PLUGIN_PATH}"!' \
        -e 's!;;"PrivateLinux64NSPluginDirs" = ""!"PrivateLinux64NSPluginDirs" = "''${MOZ_PLUGIN_PATH}"!' \
        -e 's!;;"ProductPackage" = ""!"ProductPackage" = "Converted from .deb to nix."!'

      # Install license
      install -D -m644 $out/opt/cxoffice/doc/license.txt.gz $out/share/licenses/${pname}/license.txt.gz

      runHook postInstall
    '';

    dontFixup = true;
  };

  # Common packages (32 and 64 bit)
  commonPkgs =
    pkgs: with pkgs; [
      glibc
      libxcrypt
      stdenv.cc.cc.lib
      libunwind
      attr
      bzip2
      brotli
      icu
      alsa-lib
      vulkan-loader
      libjpeg
      libtiff
      libpng12
      libXft
      libXrender
      cups
      dbus
      fontconfig
      freetype
      glib
      gnutls
      gsm
      libexif
      libgphoto2
      libpng
      libpulseaudio
      libxml2
      libxslt
      mpg123
      nssmdns
      ocl-icd
      openal
      openssl
      sane-backends
      v4l-utils
      pcsclite
      systemdLibs
      libxfixes
      libusb1
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-ugly

      # Graphics
      libGL
      libGLU
      libICE
      libSM
      libX11
      libXcomposite
      libXcursor
      libXext
      libXi
      libXinerama
      libXrandr
      libXxf86vm
      libdrm
      mesa

      # Core
      ncurses
      zlib
      lcms2
      tcl
      tk
    ];

  fhsEnv = buildFHSEnv {
    name = "crossover-fhs";

    targetPkgs =
      pkgs:
      (commonPkgs pkgs)
      ++ (commonPkgs pkgs.pkgsi686Linux)
      ++ (with pkgs; [
        crossover-dist

        # Tools needed by crossover python scripts
        (python3.withPackages (ps: [
          ps.pygobject3
          ps.pycairo
        ]))
        vte
        gtk3
        pango
        gdk-pixbuf
        atk
        harfbuzz
        cairo

        # Utilities
        which
        file
        binutils
        gnused
        gnutar
        gzip
        unzip
        perl
        gobject-introspection
        lsb-release
      ]);

    multiPkgs = null;

    profile = ''
      export GI_TYPELIB_PATH="/usr/lib/girepository-1.0:/usr/lib64/girepository-1.0"
    '';

    extraBuildCommands = ''
      mkdir -p etc
      echo 'PRETTY_NAME="NixOS 25.11 (Vicuna)"' > etc/os-release
      echo 'ID=nixos' >> etc/os-release
      echo 'VERSION_ID="25.11"' >> etc/os-release
      echo 'NAME="NixOS"' >> etc/os-release
    '';

    # Run the main executable based on CX_BINARY
    runScript = pkgs.writeScript "crossover-wrapper" ''
      #!/bin/bash
      export LD_LIBRARY_PATH="/usr/lib32:/usr/lib64:$LD_LIBRARY_PATH"
      export CX_ROOT=/opt/cxoffice

      if [[ "$CX_BINARY" == "wineloader" ]]; then
        exec /opt/cxoffice/bin/wineloader "$@"
      elif [[ "$CX_BINARY" == "wineloader64" ]]; then
        exec /opt/cxoffice/bin/wineloader64 "$@"
      elif [[ "$CX_BINARY" == "wineserver32" ]]; then
        exec /opt/cxoffice/bin/wineserver32 "$@"
      elif [[ "$CX_BINARY" == "wineserver64" ]]; then
        exec /opt/cxoffice/bin/wineserver64 "$@"
      else
        exec /opt/cxoffice/bin/crossover "$@"
      fi
    '';
  };

  meta = {
    description = "Run Windows Programs on Linux";
    homepage = "https://www.codeweavers.com/crossover";
    license = pkgs.lib.licenses.unfree;
    platforms = pkgs.lib.platforms.linux;
  };
in
pkgs.runCommand "crossover"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    inherit meta;
    passthru = { inherit fhsEnv; };
  }
  ''
    mkdir -p $out/bin

    makeWrapper ${fhsEnv}/bin/crossover-fhs $out/bin/crossover \
      --set CX_BINARY crossover \
      --argv0 crossover

    makeWrapper ${fhsEnv}/bin/crossover-fhs $out/bin/wine \
      --set CX_BINARY wineloader \
      --argv0 wineloader

    makeWrapper ${fhsEnv}/bin/crossover-fhs $out/bin/wine64 \
      --set CX_BINARY wineloader64 \
      --argv0 wineloader64

    makeWrapper ${fhsEnv}/bin/crossover-fhs $out/bin/wineserver \
      --set CX_BINARY wineserver32 \
      --argv0 wineserver32

    makeWrapper ${fhsEnv}/bin/crossover-fhs $out/bin/wineserver64 \
      --set CX_BINARY wineserver64 \
      --argv0 wineserver64
  ''
