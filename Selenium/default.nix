{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ../core.nix
    ../desktop.nix
    ./hardware-configuration.nix
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  # NIX SETTINGS

  networking.hostName = "Selenium";
  system.stateVersion = "25.05";

}
