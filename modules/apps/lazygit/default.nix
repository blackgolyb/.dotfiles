{ config, lib, ... }:

let
  cfg = config.my.apps.lazygit;
in
{
  options.my.apps.lazygit.enable = lib.mkEnableOption "Lazygit";

  config = lib.mkIf cfg.enable {
    programs.lazygit = {
      enable = true;

      settings = {
        os = {
          edit = ''
            sh -c 'if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
              nvr --remote-send "<C-\><C-n><cmd>close<cr>"
              nvr --remote "$1"
            else
              nvim -- "$1"
            fi' -- "{{filename}}"
          '';

          editAtLine = ''
            sh -c 'if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
              nvr --remote-send "<C-\><C-n><cmd>close<cr>"
              nvr --remote +"$2" "$1"
            else
              nvim +"$2" -- "$1"
            fi' -- "{{filename}}" "{{line}}"
          '';

          openDirInEditor = ''
            sh -c 'if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
              nvr --remote-send "<C-\><C-n><cmd>close<cr>"
              nvr --remote "$1"
            else
              nvim -- "$1"
            fi' -- "{{dir}}"
          '';
        };
      };
    };
  };
}
