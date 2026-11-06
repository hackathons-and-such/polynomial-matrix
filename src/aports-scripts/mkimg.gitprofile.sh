profile_gitprofile() {
    profile_standard
    
    # Append git to the package list
    apks="$apks git"
    
    # Point to your inline overlay generator script
    apkovl="scripts/genapkovl-dhcp.sh"
    
    local _k _a
    for _k in $kernel_flavors; do
        apks="$apks linux-$_k"
        for _a in $kernel_addons; do
            apks="$apks $_a-$_k"
        done
    done
    apks="$apks linux-firmware"
}
