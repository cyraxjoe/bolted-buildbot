{ stdenv
, python27Packages
, buildbot-pkg }:
let
  pythonPackages = python27Packages;
  inherit (pythonPackages) cairocffi jinja2 buildPythonPackage fetchPypi;

  klein = pythonPackages.klein.overrideAttrs (old: { doInstallCheck = false; }); 

  cairosvg = buildPythonPackage rec {
    name = "${pname}-${version}";

    pname = "CairoSVG";

    version = "1.0.22";

    src = fetchPypi {
      inherit pname version;
      sha256 = "0mqml8cc0ibcqhsjk27pwbfgwyw38p6hydxva9ly7lhi4wx0yvpn";
    };

    propagatedBuildInputs = [ cairocffi ];

    meta = {
      homepage = https://cairosvg.org;
      license = with stdenv.lib; licenses.lgpl3;
      description = "SVG converter based on Cairo";
    };
  };

in
{
  badges = buildPythonPackage rec {
    name = "${pname}-${version}";
    pname = "buildbot-badges";
    version = buildbot-pkg.version;

    src = fetchPypi {
      inherit pname version;
      sha256 = "0jkabxglaz08d3qq4zrnl72rg2zz115g0bvf6h61jkxxlcdahgvl";
    };

    propagatedBuildInputs = [ buildbot-pkg jinja2 klein cairocffi cairosvg ];

    meta = with stdenv.lib; {
      homepage = http://buildbot.net/;
      description = "Buildbot Badges Plugin";
      license = licenses.gpl2;
    };
  };
}
