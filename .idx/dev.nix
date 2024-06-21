{ pkgs, ... }: {
  channel = "unstable";
  
  packages = [
    pkgs.gleam
    pkgs.erlang
  ];

  idx = {
    extensions = [
      "Catppuccin.catppuccin-vsc"
      "gleam.gleam"
      "tamasfe.even-better-toml"
    ];
  };
}