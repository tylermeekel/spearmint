{ pkgs, ... }: {
  channel = "unstable";
  
  packages = [
    pkgs.clang
    pkgs.libgcc
    pkgs.gnumake
    pkgs.gleam
    pkgs.elixir
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