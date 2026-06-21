{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ../core.nix
    ./hardware-configuration.nix
    inputs.lanzaboote.nixosModules.lanzaboote-stable
  ];

  # NIX SETTINGS

  networking.hostName = "Sienna";
  system.stateVersion = "25.11";

}
