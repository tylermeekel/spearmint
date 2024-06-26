{ pkgs, ... }: {
  channel = "unstable";
  
  packages = [
    pkgs.gleam
    pkgs.erlang
    pkgs.rebar3
    pkgs.postgresql_16
  ];

  idx = {
    extensions = [
      "Catppuccin.catppuccin-vsc"
      "gleam.gleam"
      "tamasfe.even-better-toml"
      "rangav.vscode-thunder-client"
    ];
  };
}