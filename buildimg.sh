#/bin/sh
SCRIPTDIR=$(cd "$(dirname "$0")";pwd)
[ -d bin ] || mkdir bin
[ -z ${VERSION} ] && VERSION=21.02.1
[ -z ${MIRROR} ] && MIRROR=downloads.openwrt.org
[ -z ${TARGET} ] && exit 1
[ -z ${PROFILE} ] && exit 1
NAME=openwrt-imagebuilder-${VERSION}-${TARGET}.Linux-x86_64
IMAGE_URL=${MIRROR}/releases/${VERSION}/targets/${TARGET/-//}/${NAME}.tar.xz
[ -f ${PROFILE}.tar.xz ] || wget -O ${PROFILE}.tar.xz ${IMAGE_URL} >nul || exit $?
 tar xJvf ${PROFILE}.tar.xz >nul || exit $?
cd ${NAME} || exit $?
[ -z ${MIRROR} ] || sed -i "s@downloads.openwrt.org@${MIRROR}@" repositories.conf
[ -d packages ] || mkdir packages
cp -af ${SCRIPTDIR}/addon_packages/*.ipk packages
grep '^src addon' repositories.conf  || echo src addon file:packages >> repositories.conf
make image PROFILE=${PROFILE} FILES=${SCRIPTDIR}/addon_file/ PACKAGES="${PACKAGES} luci-i18n-ddns-zh-cn ddns-scripts_aliyun netdata wget-ssl socat fdisk resize2fs base-files  bash block-mount  busybox  ca-bundle  ca-certificates  certtool  coreutils  coreutils-nohup  curl  dnsmasq-full  dropbear  e2fsprogs  etherwake  firewall  fstools  fwtool  kmod-pppoe  kmod-tun  lua  luci  luci-base  luci-compat  luci-i18n-base-zh-cn  luci-i18n-firewall-zh-cn  luci-i18n-mwan3-zh-cn  luci-i18n-openvpn-zh-cn luci-i18n-opkg-zh-cn luci-i18n-wol-zh-cn  mkf2fs  opkg  ppp  ppp-mod-pppoe  r8169-firmware  terminfo  luci-app-zerotier luci-app-frps luci-app-frpc xinetd"
cp -f bin/targets/${TARGET/-//}/*.img.gz ../bin/