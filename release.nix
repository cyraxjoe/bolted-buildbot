{ nixpkgs
, bbb
, masterSrc
, externalMasterDir
}:
{
  inherit (import bbb { inherit nixpkgs masterSrc externalMasterDir; }) lw-master;
}
