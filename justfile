
allocated_ram := "2G"
shared_dir := "./vmshare"

share_mount_flags := f"-fsdev local,id=sharedir,path='{{shared_dir}}',security_model=mapped-xattr -device virtio-9p-pci,fsdev=sharedir,mount_tag=hostshare"
opts := f"-enable-kvm -boot d -m {{allocated_ram}} -cpu host -nic user {{share_mount_flags}} -serial mon:stdio"

@_help:
    just --list

run CDROM_PATH:
    qemu-system-x86_64 -cdrom {{CDROM_PATH}} {{opts}}
