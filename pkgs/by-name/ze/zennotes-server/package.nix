{
  lib,
  buildGoModule,
  fetchFromGitHub,
  buildNpmPackage,
  electron_41,
  nix-update-script,
}:
let
  version = "2.19.0";

  src = fetchFromGitHub {
    owner = "ZenNotes";
    repo = "zennotes";
    tag = "v${version}";
    hash = "sha256-pf90wkUMIJ9wGM8JzkTWv/CipJc0cBzeSozhKdGPCGw=";
  };

  web = buildNpmPackage {
    pname = "zennotes-web";
    inherit version src;

    npmDepsHash = "sha256-z1njt74VvEpxO75bprGD3/eUsv1gH2GPIz6Svye+WYg=";

    npmWorkspace = "apps/web";

    env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r apps/web/dist $out/dist
      runHook postInstall
    '';
  };
in
buildGoModule (finalAttrs: {
  pname = "zennotes-server";
  inherit version src;

  sourceRoot = "${src.name}/apps/server";

  vendorHash = "sha256-ZdOHC2JldvnKSDUFnBUJrKD4F1IWfvYJBksgeDnU9cw=";

  postPatch = "cp -r ${web}/dist web/dist";

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Keyboard-first local Markdown notes with Vim motions, diagrams, and MCP integration";
    homepage = "https://zennotes.org/";
    changelog = "https://github.com/ZenNotes/zennotes/releases/tag/v${finalAttrs.version}";
    license = licenses.mit;
    mainProgram = "zennotes-server";
    maintainers = with lib.maintainers; [
      showhyt
    ];
  };
})
