{ nixpkgs ? <nixpkgs>
, masterSrc
, externalMasterDir ? "/tmp/ci"
, bbb ? ./.
}:
let
  masterSrc' = with (import nixpkgs {});
  (if lib.hasPrefix "/nix/store" masterSrc
    then masterSrc
  else
    copyPathToStore masterSrc);
in {
  inherit (import bbb { masterSrc=masterSrc'; inherit nixpkgs externalMasterDir; }) lw-master;
}
