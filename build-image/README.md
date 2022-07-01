## Flashing RPI on macOS

```bash
sudo diskutil list
sudo diskutil unmountDisk /dev/disk4   
sudo dd if=nixos-sd-image-22.05.20220701.e4e484c-aarch64-linux.img of=/dev/disk4 bs=64K status=progress
```