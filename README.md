# Minimalistic Gstreamer Zig program
This is a Zig program that will compile and display a gstreamer videotestsrc pattern!

I compiled this using Nix to install Gstreamer and Glib-2.0 for reproducable builds. You will need to edit the `build.zig` to point to your system's `gst.h`, `glib.h` and `glib-object.h` if not using Nix.

If you have Nix installed, all you need to do is enter this directory and run `nix develop` (which requires the experimental `flakes` and `nix-commands` enabled)

Tested with a NixOS WSL2 instance!

![Screenshot 2024-09-29 163035](https://github.com/user-attachments/assets/107d646a-9228-4fb2-9fbb-fc7ccbcfde68)


This is just a proof-of-concept for others to build off of, as I could not find any other reproducable builds of gstreamer applications using just the raw C header files. 
