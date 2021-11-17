#/bin/sh
export VERSION=21.02.1
export PROFILE=friendlyarm_nanopi-neo2
export TARGET=sunxi-cortexa53
export MIRROR=mirrors.tencent.com\/openwrt
[ -f nps.tar.gz ] && mkdir -p nps/etc/nps && tar zxvf nps.tar.gz -C nps/etc/nps && cp -af nps/* addon_file/
#wget -P addon_packages https://github.com/zzsj0928/luci-app-pushbot/releases/download/3.55-21/luci-app-pushbot_3.55-21_all.ipk
#wget -P addon_packages https://github.com/vernesong/OpenClash/releases/download/v0.43.09-beta/luci-app-openclash_0.43.09-beta_all.ipk
env PACKAGES='luci-app-pushbot luci-app-openclash -dnsmasq dnsmasq-full kmod-rtl8812au-ct hostapd-wolfssl fwtool -ip6tables -odhcp6c' ./buildimg.sh
