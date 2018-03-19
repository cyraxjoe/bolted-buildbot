{ stdenv
, lib
, writeShellScriptBin
, makeWrapper
, buildbot-worker
, externalWorkerDir 
, workerConfigFile ? ./config.json }:
let minVersion = "1.0"; in
  assert !(lib.versionAtLeast  buildbot-worker.version  minVersion) -> 
    abort ''
    #########################################################
    The buildbot worker in nixpkgs needs to be at least at version ${minVersion}.

    Current version: ${buildbot-worker.version}
    ##########################################################
  '';
with {
  config = lib.importJSON workerConfigFile;
  missingAttr = a: config: !(builtins.hasAttr a config);
};
  assert missingAttr "name" config -> 
    abort "Missing required 'name' in the config file.";
  assert missingAttr "admin" config -> 
    abort "Missing required 'admin' in the config file.";
  assert missingAttr "description" config -> 
    abort "Missing required 'description' in the config file.";
with rec {
  # allow_shutdown:  Allows the worker to initiate a graceful shutdown. One of 'signal' or 'file'
  # keepalive:       Interval at which keepalives should be sent (in seconds) [default: 600]
  # maxdelay:        Maximum time between connection attempts [default: 300]
  # maxretries:      Maximum number of retries before worker shutdown [default: None]
  # numcpus:         Number of available cpus to use on a build. [default: None]
  # umask:           Controls permissions of generated files. 
  #                  Use umask =0o22 to be world-readable [default: None]
  defaultConfig = { 
    keepalive = 600;
    umask = null;
    maxdelay = 300;
    numcpus = null;
    allow_shutdown = null;
    maxretries = null;
    master = {
      host = "localhost";
      port = 9989;
    };
  };
  params = { 
    config = 
      with builtins;
      let 
       coerceMap = {
          "int" = a: toString a;
          "null" = a: "None";
          "string" = a: a;
       };  
       in lib.mapAttrsRecursive (path: value: 
           let coerceFunc = getAttr (typeOf value) coerceMap;
           in coerceFunc value)
      (defaultConfig // config);
    inherit  buildbot-worker writeShellScriptBin externalWorkerDir;
  };
}; 
let
  BBBWorker = import ./core-worker-setup.nix params;
in
  stdenv.mkDerivation (BBBWorker // rec {
    name = "bbb-worker-${ config.name }-${version}";
    version = "0.0.1";
    src = ./.;
    phases = [ "unpackPhase" "installPhase" ];
    buildInputs = [ buildbot-worker makeWrapper ];
  })
