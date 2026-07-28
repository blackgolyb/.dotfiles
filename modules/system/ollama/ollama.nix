{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.system.ollama;
in
{
  options.my.system.ollama.enable = lib.mkEnableOption "Ollama with Open WebUI";

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-vulkan;

      host = "127.0.0.1";
      port = 11434;

      loadModels = [
        "gemma4:e4b"
        "qwen3.5:9b"
      ];

      environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "16384";
        OLLAMA_IGPU_ENABLE = "1";
        OLLAMA_MAX_LOADED_MODELS = "1";
        OLLAMA_KEEP_ALIVE = "10m";
      };
    };

    services.open-webui = {
      enable = true;

      host = "127.0.0.1";
      port = 3113;

      environment = {
        OLLAMA_BASE_URL = "http://127.0.0.1:11434";
        WEBUI_AUTH = "False";
      };
    };

    environment.systemPackages = [
      pkgs.ollama-vulkan
    ];
  };
}
