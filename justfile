
allocated_ram := "4G"
shared_dir := "./src"

share_mount_flags := f"-fsdev local,id=sharedir,path='{{shared_dir}}',security_model=mapped-xattr -device virtio-9p-pci,fsdev=sharedir,mount_tag=hostshare"
opts := f"-enable-kvm -m {{allocated_ram}} -cpu host -smp 8 -nic user {{share_mount_flags}} -serial mon:stdio"

@_help:
    just --list

run CDROM_PATH DRIVE_PATH:
    qemu-system-x86_64 -cdrom {{CDROM_PATH}} -drive file={{DRIVE_PATH}},format=qcow2,if=virtio -boot c {{opts}}

launch_custom_img IMG_PATH:
    qemu-system-x86_64 -cdrom {{IMG_PATH}} -boot d {{opts}}
