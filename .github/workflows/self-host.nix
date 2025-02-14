# Usage: `nix-build runner.nix --argstr spec2006src <SPEC2006SRC> --argstr github_token <GITHUB_TOKEN>`
# * The GitHub token (valid for 366 days, limited by OpenXiangShan) is needed to
#   retrieve the runner token (only valid for one hour, limited by GitHub).
#   https://docs.github.com/en/rest/actions/self-hosted-runners?apiVersion=2022-11-28#create-a-registration-token-for-a-repository
#   > The fine-grained token must have the following permission set:
#   > "Administration" repository permissions (write)
# * Generate the github token here:
#   https://github.com/settings/tokens?type=beta
{ pkgs ? import <nixpkgs> {}
, spec2006src
, github_token
}: let
  name = "runner-deterload";
  runner = import (pkgs.fetchFromGitHub {
    owner = "xieby1";
    repo = "nix_config";
    rev = "3f08da6e040d2004246922b4f532d350cf5ce836";
    hash = "sha256-B2LrDa2sYmFsKpeizJR2Pz0/bajeWBqJ032pgB05CAU=";
  } + "/scripts/pkgs/github-runner.nix") {
    inherit pkgs;
    extraPodmanOpts = ["-v ${spec2006src}:/${builtins.baseNameOf spec2006src}:ro"];
    extraPkgsInPATH = [pkgs.git];
  };
  run-ephemeral = pkgs.writeShellScriptBin name ''
    resp=$(curl -L \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${github_token}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      Https://api.github.com/repos/OpenXiangShan/Deterload/actions/runners/registration-token)
    # https://unix.stackexchange.com/questions/13466/can-grep-output-only-specified-groupings-that-match
    runner_token=$(echo $resp | grep -oP '"token":\s*"\K[^"]*')
    ${runner} \
      --labels 'self-hosted,Linux,X64,nix,spec2006' \
      --ephemeral \
      --url https://github.com/OpenXiangShan/Deterload \
      --token $runner_token
  '';
in run-ephemeral
