#!/bin/bash
# 开启调试模式，显示执行的每一行命令
set -x
# 确保脚本在出错时退出
set -e

VERSION=${VERSION:-24.10.5}
TARGET=${TARGET:-mediatek-filogic}
PROFILE=${PROFILE:-cmcc_rax3000m}
MIRROR=${MIRROR:-downloads.immortalwrt.org}
SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)
BIN_DIR="${SCRIPTDIR}/bin"

mkdir -p "${BIN_DIR}"

NAME="immortalwrt-imagebuilder-${VERSION}-${TARGET}.Linux-x86_64"
URL_BASE="https://${MIRROR}/releases/${VERSION}/targets/${TARGET//-//}"

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
make image PROFILE=${PROFILE} PACKAGES="${PACKAGES} luci-i18n-base-zh-cn luci-i18n-openvpn-zh-cn luci-proto-wireguard luci-i18n-zerotier-zh-cn luci-i18n-appfilter-zh-cn luci-i18n-wechatpush-zh-cn luci-i18n-wol-zh-cn luci-i18n-acl-zh-cn"

# --- 修改后的打包逻辑 ---
echo "--- 正在打包目标目录 ---"

# 这里的 TARGET_PATH 是 x86/64 这种格式
# 源目录路径：bin/targets/x86/64
SOURCE_DIR="bin/targets/${TARGET//-//}"
# 定义压缩包文件名
ARCHIVE_NAME="${PROFILE}-${VERSION}.tar.gz"

if [ -d "$SOURCE_DIR" ]; then
    echo "找到目标目录: $SOURCE_DIR，正在打包..."
    # 使用 -C 切换到目录内部，避免压缩包内出现冗长的层级路径
    tar -zcvf "${BIN_DIR}/${ARCHIVE_NAME}" -C "$SOURCE_DIR" .
    echo "打包成功: ${BIN_DIR}/${ARCHIVE_NAME}"
else
    echo "错误: 目标目录 $SOURCE_DIR 不存在！编译可能未生成任何结果。"
    # 调试：列出当前目录结构，方便在 GitHub Action 日志中查看
    find bin -maxdepth 3
    exit 1
fi