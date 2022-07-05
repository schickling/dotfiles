# - NixOS SD image builder AWS configuration
# This will spin up a `a1.2xlarge` instance and build an SD image for NixOS on it using the
# contents of the cloned repository. It will also automatically download the image from the
# remote instance.
# I recommend to enable compression in the main configuration file to minimize downloading
# files.
#
# NOTE: This requires at least Packer 1.5.0.

variable "region" {
  default = "eu-west-1"
}

variable "availability_zone" {
  # note: Some regions don't yet have A1 ARM instances
  default = "eu-west-1b"
}

variable "cachix_auth_token" {
  default = "${env("CACHIX_AUTH_TOKEN")}"
}

variable "cachix_cache" {
  default = "schickling"
}

variable "image_name" {
  type = string
}

source "amazon-ebs" "nixos_sd_image_builder" {
  ami_name            = "nixos_sd_image_builder"
  region              = var.region
  availability_zone   = var.availability_zone
  # This instance has 8 cores and 16 GiB of RAM. It is pretty cheap with Spot and builds the image
  # in about 5 minutes.
  instance_type = "a1.2xlarge"
  // TODO re-enable spot instances when fix https://github.com/hashicorp/packer-plugin-amazon/issues/223
  // spot_instance_types = ["a1.2xlarge"]
  // spot_price          = "auto"
  skip_create_ami     = true

  // fleet_tags = {
  //   # Workaround for https://github.com/hashicorp/packer-plugin-amazon/issues/92
  //   Name = "nixos_sd_image_builder-{{ timestamp }}"
  // }

  source_ami_filter {
    filters = {
      name = "NixOS-22.05.*-aarch64-linux"
      virtualization-type = "hvm"
    }

    most_recent = true

    owners = ["080433136561"] # source: http://jackkelly.name/blog/archives/2020/08/30/building_and_importing_nixos_amis_on_ec2/
  }

  # The default volume size of 8 GiB is too small. Use 24.
  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_type           = "gp2"
    volume_size           = "24"
    delete_on_termination = true
  }

  ssh_username = "root"
  ssh_interface = "public_ip"
}

build {
  sources = ["source.amazon-ebs.nixos_sd_image_builder"]

  provisioner "file" {
    source      = "../nixpkgs"
    destination = "./nixpkgs/"
  }

  provisioner "file" {
    sources     = ["../flake.nix", "../flake.lock", "../.envrc", "../.envrc.local"]
    destination = "./"
  }

  # NOTE This is currently needed (1) to enable flakes and (2) to make `cachix use` work
  # TODO come up with an approach that doesn't require these extra files
  provisioner "file" {
    source      = "./etc-nixos/"
    destination = "/etc/nixos/"
  }

  provisioner "shell-local" {
    inline_shebang = "/bin/sh -ex"
    valid_exit_codes = [0, 1]
    inline = [
      "exit 1"
    ]
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "direnv allow"
      // NOTE disabled cachix for now as uploading the final img artifacts takes multiple minutes
      // and nullifies the speed up gained by Cachix 🙈

      // "nix-env -iA cachix -f https://cachix.org/api/v1/install",
      // "cachix authtoken ${var.cachix_auth_token}",
      // "cachix use ${var.cachix_cache}",
      // "sudo nixos-rebuild switch",
      // "cachix watch-exec ${var.cachix_cache} nix -- build .#images.homepi",
      "nix --extra-experimental-features \"nix-command flakes\" build .#images.${var.image_name}",
      "ls result/sd-image"
    ]
  }

  provisioner "shell-local" {
    inline_shebang = "/bin/sh -ex"
    valid_exit_codes = [0, 1]
    inline = [
      "BACKUP_DIR=backup/`date +%F_%R`",
      "mkdir -p $BACKUP_DIR",
      "mv *.img $BACKUP_DIR/"
    ]
  }

  # Downloads the image.
  provisioner "file" {
    source      = "./result/sd-image/nixos*"
    destination = "./"
    direction   = "download"
  }

  provisioner "shell-local" {
    inline = [
      "echo 'Image *successfully* built and downloaded as' nixos*"
    ]
  }
}
