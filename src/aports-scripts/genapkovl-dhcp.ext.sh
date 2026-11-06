
# This appends to uptream genapkvol

makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
git
EOF

# (Optional) Add any other custom files or scripts here:
# mkdir -p "$tmp"/usr/local/bin
# echo 'echo "Hello from custom script!"' > "$tmp"/usr/local/bin/myscript.sh
# chmod +x "$tmp"/usr/local/bin/myscript.sh
