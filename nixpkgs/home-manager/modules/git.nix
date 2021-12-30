{ config, pkgs, libs, ... }:
{
  programs.git = {
    enable = true;
    userName  = "Johannes Schickling";
    userEmail = "schickling.j@gmail.com";
    signing.signByDefault = true;
    signing.key = "8E9046ABA7CA018432E4A4897D614C236B9A75E6";
  };
}
