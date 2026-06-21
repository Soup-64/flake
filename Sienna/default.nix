{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ../core.nix
    ./hardware-configuration.nix
    inputs.lanzaboote-stable.nixosModules.lanzaboote
  ];

  # NIX SETTINGS

  networking.hostName = "Sienna";
  system.stateVersion = "25.11";

}
