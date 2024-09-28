{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zig.url = "github:mitchellh/zig-overlay";
    flake-utils = { url = "github:numtide/flake-utils"; };
  };

  outputs = { self, nixpkgs, zig, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem(system:
      let 
        pkgs = import nixpkgs {
          inherit system;
        };
        zig_exe = zig.packages.${system}.master;
      in
      {
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          zig_exe
          glib
          glib.dev
          gst_all_1.gstreamer
          gst_all_1.gstreamer.dev
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
        ];

        GST_DEV_PATH = pkgs.gst_all_1.gstreamer.dev;
        GLIB_DEV_PATH = pkgs.glib.dev;
        GLIB_PATH = pkgs.glib.out;
      };
    }
  );
}
