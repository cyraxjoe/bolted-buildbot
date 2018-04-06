###############
Bolted Buildbot
###############

Nix wrapper on top of buildbot to manage the configuration of the master and workers in nix. 

========
Overview
========

`Bolted` Buildbot is a set of nix expression and bash scripts that allows you
to reliable manage your CI/CD/CB systems based on buildbot, by adding a set
of additional scripts to manage your buildbot instance and more importantly
to consider the buildbot configuration as a dependency of the deployment.

By considering the Builtbot Master or Worker configuration as a dependency
you can safely upgrade and `rollback` your configuration changes.

The core idea is that `Bolted` Buildbot allows you to tread your CI system
with lot less care by forcing you to go over the nix layer first and
implicitly visioning your changes by making your current configs read only
and any new change would have to be on a new derivation.


===============
Getting started
===============

First and foremost, you have to have `Nix <https://nixos.org/nix/>`_ either implicitly
by using `NixOS <https://nixos.org/>`_ or by using just Nix on MacOS or Linux.

The main entry point to use Bolted Buildbot is by using ``release.nix`` and configure
the parameters in the nix expression.

Parameters:

  nixpkgs
    It should point to a checkout of `nixpkgs <https://github.com/nixos/nixpkgs>`_ 
    preferably to a recent stable release like: `18.03 <https://github.com/nixos/nixpkgs-channels/tree/nixos-18.03>`_. By default it will try to use the envvar ``NIX_PATH`` for ``<nixpkgs>``.

  masterSrc
    The master source. Default to ``null``.

  masterConfigFile
    Master config file in JSON format. Default to ``null``.

  masterPlugins
    Master buildbot plugins. Default to ``[ "www" "console-view" "waterfall-view" "grid-view" "wsgi-dashboards" "badges" ]``.

  externalMasterDir
    Base directory on which the Master Bolted Buildbot would be deployed. Default to ``/tmp/bbb-master``.

  externalWorkerDir
    Base directory on which the Worker Bolted Buildbot would be deployed. Default to ``/tmp/bbb-worker``.

  workerConfigFile
    Worker config file in JSON format. Default to ``null``


