# OpenClaw sandbox container image.
#
# The default OpenClaw Docker sandbox image has no coding toolchain. This one
# bakes in git, node, python, and the OpenCode CLI so that delegated coding
# work runs opencode directly inside the sandbox (OpenClaw -> docker sandbox ->
# OpenCode -> repo), per the deployment plan.

{ pkgs }:

let
  toolRoot = pkgs.buildEnv {
    name = "openclaw-sandbox-tools";
    paths = [
      pkgs.bash
      pkgs.coreutils
      pkgs.git
      pkgs.openssh
      pkgs.curl
      pkgs.wget
      pkgs.jq
      pkgs.ripgrep
      pkgs.python3
      pkgs.nodejs
      pkgs.gnupg
      pkgs.vim
      pkgs.which
      pkgs.procps
      pkgs.util-linux
      pkgs.cacert
      pkgs.opencode
    ];
    pathsToLink = [
      "/bin"
      "/share"
    ];
    ignoreCollisions = true;
  };

  sh = pkgs.runCommand "openclaw-sandbox-sh" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.bash}/bin/bash $out/bin/sh
  '';

  root = pkgs.symlinkJoin {
    name = "openclaw-sandbox-root";
    paths = [
      toolRoot
      sh
    ];
    ignoreCollisions = true;
  };
in
pkgs.dockerTools.buildImage {
  name = "openclaw-sandbox";
  tag = "latest";

  copyToRoot = root;

  config = {
    Env = [
      "PATH=/bin:/usr/bin"
      "HOME=/tmp"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "GIT_EDITOR=true"
    ];
    WorkingDir = "/tmp";
    Cmd = [
      "sleep"
      "infinity"
    ];
  };
}
