{
  stdenv,
  fetchFromGitHub,
  lib,
  fetchPnpmDeps,
  pnpm_10,
  pnpmConfigHook,
  nodejs,
  python3,
  node-gyp,
  libx11,
  xorgproto,
  libxkbfile,
  fontconfig,
  node-gyp-build,
  pkg-config,
  libsecret,
  makeWrapper,
  electron,
  nix-update-script,
  xcbuild,
  cctools,
}:
let
  dist_path = {
    x86_64-linux = "dist/linux-unpacked";
    aarch64-linux = "dist/linux-arm64-unpacked";
    aarch64-darwin = "dist/mac-arm64-unpacked";
  };

  builded_dir = dist_path.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation (finalAttrs: {
  pname = "marktext";
  version = "0.19.1";

  src = fetchFromGitHub {
    owner = "marktext";
    repo = "marktext";
    tag = "v${finalAttrs.version}";
    hash = "sha256-i1CjwRndcDUNpoMUPZ9U2TI/OsSX/WH8zXgEMHy338k=";
  };

  pnpmDeps = fetchPnpmDeps {
    pname = "marktext-monorepo";
    inherit (finalAttrs) version src;
    fetcherVersion = 4;
    hash = "sha256-PNFWviNG77Bfs0R08jCUDVQ/1O/1Q82iLWK+2tYLHg0=";
    pnpm = pnpm_10;
    pnpmInstallFlags = [ "--no-frozen-lockfile" ];
  };

  nativeBuildInputs = [
    pnpmConfigHook
    makeWrapper
    (python3.withPackages (ps: with ps; [ packaging ]))
    pkg-config
    electron
    nodejs
    node-gyp
    node-gyp-build
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    xcbuild
    cctools
  ];

  buildInputs = [
    fontconfig
    xorgproto
    libsecret
    libx11
    libxkbfile
    pnpm_10
  ];

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    DIST_DIR =
      if stdenv.hostPlatform.isAarch64 then "dist/linux-arm64-unpacked" else "dist/linux-unpacked";
  };

  # Patch i18n.ts before building
  postPatch = ''
    # Fix folders location
    substituteInPlace packages/desktop/src/common/i18n.ts \
      --replace-fail \
        "process.resourcesPath, 'static', 'locales'" \
        "__dirname, '..', '..', 'static', 'locales'"
  '';

  buildPhase = ''
    runHook preBuild

    # Need for electron-rebuild
    export npm_config_nodedir=${nodejs}

    # Generate minified locale files
    pnpm run minify-locales

    pnpm run build

    # Rebuild native modules
    pnpm exec electron-rebuild -f --module-dir packages/desktop

    pnpm exec electron-builder \
      --dir \
      --projectDir packages/desktop \
      --config electron-builder.yml \
      -c.electronDist=${electron.dist} \
      -c.electronVersion=${electron.version}

    # Inject static folder into the asar
    pnpm exec asar extract $DIST_DIR/resources/app.asar app-tmp
    cp -a packages/desktop/static app-tmp/static
    pnpm exec asar pack app-tmp $DIST_DIR/resources/app.asar
    rm -rf app-tmp

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/marktext" "$out/bin"

    install -Dm644 packages/desktop/build/linux/marktext.desktop \
      "$out/share/applications/marktext.desktop"

    # Copy the built app
    cp -r ${builded_dir}/. "$out/lib/marktext/"

    makeWrapper ${lib.getExe electron} "$out/bin/marktext" \
      --add-flags "$out/lib/marktext/resources/app.asar" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"

    # Add file icons
    for size in 16 24 32 48 64 128 256 512; do
      iconFile="packages/desktop/build/icons/''${size}x''${size}/marktext.png"
      if [ -f "$iconFile" ]; then
        install -Dm644 "$iconFile" \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/marktext.png"
      fi
    done
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Simple and elegant markdown editor, available for Linux, macOS and Windows";
    homepage = "https://www.marktext.me";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      nh2
      eduarrrd
      bot-wxt1221
    ];
    platforms = lib.platforms.unix;
    mainProgram = "marktext";
  };
})
