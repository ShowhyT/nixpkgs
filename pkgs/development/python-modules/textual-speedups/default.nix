{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  rustPlatform,
}:

buildPythonPackage (finalAttrs: {
  pname = "textual-speedups";
  version = "0.2.1-unstable-2026-04-08";
  pyproject = true;

  # TODO: on next release, use tag, instead of rev
  src = fetchFromGitHub {
    owner = "willmcgugan";
    repo = "textual-speedups";
    rev = "5f01ad052564ca1ac14ecf33a69c6d39be17a8af";
    hash = "sha256-jefe54C41fxocRtR1JickaBV2Dja5pWyHMXkr9PdcJM=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src;
    version = "0.2.1";
    hash = "sha256-Bz4ocEziOlOX4z5F9EDry99YofeGyxL/6OTIf/WEgK4=";
  };

  nativeBuildInputs = with rustPlatform; [
    cargoSetupHook
    maturinBuildHook
  ];

  pythonImportsCheck = [ "textual_speedups" ];

  # No tests
  doCheck = false;

  meta = {
    description = "Optional Rust speedups for Textual";
    homepage = "https://github.com/willmcgugan/textual-speedups";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ GaetanLepage ];
  };
})
