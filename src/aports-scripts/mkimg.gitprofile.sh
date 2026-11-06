profile_gitprofile() {
    profile_standard
    
    # Append git to the package list
    apks="$apks git"
    
    # Use our own overlay generator (do not point at the stock DHCP overlay)
    apkovl="scripts/genapkovl-gitprofile.sh"
    
    local _k _a
    for _k in $kernel_flavors; do
        apks="$apks linux-$_k"
        for _a in $kernel_addons; do
            apks="$apks $_a-$_k"
        done
    done
    apks="$apks linux-firmware"
}
