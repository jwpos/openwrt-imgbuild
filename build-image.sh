#!/bin/bash
# 开启调试模式，显示执行的每一行命令
set -x
# 确保脚本在出错时退出
set -e

VERSION=${VERSION:-24.10.3}
TARGET=${TARGET:-x86-64}
PROFILE=${PROFILE:-generic}
MIRROR=${MIRROR:-downloads.immortalwrt.org}
SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)
BIN_DIR="${SCRIPTDIR}/bin"

mkdir -p "${BIN_DIR}"

# 转换平台路径：x86-64 -> x86/64
TARGET_PATH=${TARGET//-/\/}
NAME="immortalwrt-imagebuilder-${VERSION}-${TARGET}.Linux-x86_64"
URL_BASE="https://${MIRROR}/releases/${VERSION}/targets/${TARGET_PATH}"

echo "--- 调试信息 ---"
echo "工作目录: $(pwd)"
echo "下载地址: ${URL_BASE}"

# 探测扩展名
if wget --spider -q "${URL_BASE}/${NAME}.tar.zst"; then
    EXTENSION="tar.zst"
elif wget --spider -q "${URL_BASE}/${NAME}.tar.xz"; then
    EXTENSION="tar.xz"
else
    echo "错误: 找不到远程文件，请检查 VERSION 或 TARGET 是否正确。"
    exit 1
fi

FULL_NAME="${NAME}.${EXTENSION}"

# 下载
[ -f "$FULL_NAME" ] || wget -O "$FULL_NAME" "${URL_BASE}/${FULL_NAME}"

# 解压
if [ ! -d "$NAME" ]; then
    if [[ "$EXTENSION" == "tar.zst" ]]; then
        tar --zstd -xvf "$FULL_NAME"
    else
        tar -xJvf "$FULL_NAME"
    fi
fi

cd "$NAME"

# 修改镜像源
[ -z "${MIRROR}" ] || sed -i "s@downloads.immortalwrt.org@${MIRROR}@" repositories.conf

# 插件包处理
if [ -d "${SCRIPTDIR}/addon_packages" ]; then
    mkdir -p packages
    cp -af "${SCRIPTDIR}/addon_packages"/*.ipk packages/ 2>/dev/null || true
    grep -q '^src addon' repositories.conf || echo "src addon file:$(pwd)/packages" >> repositories.conf
fi

# 开始编译
echo "--- 执行 Make ---"
make image PROFILE=${PROFILE} PACKAGES="${PACKAGES} luci-i18n-base-zh-cn"

# 拷贝结果
cp -f bin/targets/${TARGET_PATH}/*.img.gz "${BIN_DIR}/" || echo "警告: 未找到生成的镜像文件"