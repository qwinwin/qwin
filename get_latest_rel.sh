#!/bin/bash
export ALL_PROXY='http://192.168.2.3:8118'
releases_url="https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest"
old_tag="v1.11.1"
tag_name=$(curl -s $releases_url | jq -r '.tag_name')
if [ "$old_tag" != "$tag_name" ];then
    download_url=$(curl -s $releases_url | jq -r '.assets[] | select(.name|test("x86_64-unknown-linux-gnu.*xz$")) | .browser_download_url')
    echo "New version detected: $tag_name"
    wget "$download_url" -O '/tmp/ss-rust.tar.xz'
    tar -xf /tmp/ss-rust.tar.xz -C /hdd/share/things/ss-rust
    sed -i "s/${old_tag}/${tag_name}/" $0
fi