{
  lib,
  fetchFromGitHub,
  buildGoModule,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "zennotes-cli";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "ZenNotes";
    repo = "tui";
    tag = "v${finalAttrs.version}";
    hash = "sha256-D1OxGnV3YpxjwndFNz/92HZ0v3UsBALrir7aJAZDXq8=";
  };

  vendorHash = "sha256-1GaaBtKNQIRqR6kwylLdzKzbFSjGu27/9bTTVrzHoyA=";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Simple command-line snippet manager, written in Go";
    homepage = "https://github.com/knqyf263/pet";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ kalbasit ];
  };
})
