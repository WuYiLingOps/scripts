#!/bin/bash
#
# 项目名称：data-shell
# 文件名称：switch_node_version.sh
# 创建时间：2026-03-02 19:18:17
#
# 系统用户：wyl
# 作　　者：無以菱
# 联系邮箱：huangjing510@126.com
# 功能描述：管理 nvm 的 Node.js 版本，支持查看、安装、删除及设置默认版本
#

set -eo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RESET='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${RESET} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }
log_step() { echo -e "${BLUE}[STEP]${RESET} ${PURPLE}$1${RESET}"; }

load_nvm() {
    export NVM_DIR="${HOME}/.nvm"
    [ -s "${NVM_DIR}/nvm.sh" ] && . "${NVM_DIR}/nvm.sh"
}

install_nvm() {
    log_step "未检测到 nvm，开始安装"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    else
        log_error "缺少 curl/wget，无法自动安装 nvm"
        exit 1
    fi
}

show_remote_versions() {
    echo -e "${YELLOW}=== 仅显示最新 5 个 LTS 版本 ===${RESET}"
    if ! nvm ls-remote --lts | tail -5; then
        log_warn "获取 LTS 列表失败，可能是网络问题"
    fi
}

install_node_version() {
    local version="$1"
    log_step "安装 Node.js ${version}"
    nvm install "${version}"
    log_info "安装完成"
}

set_default_version() {
    local version="$1"
    if version_installed "${version}"; then
        log_step "设置默认版本为 ${version}"
        nvm alias default "${version}"
        nvm use "${version}"
        log_info "当前默认版本: $(node -v)"
    else
        log_warn "版本 ${version} 未安装，请先安装"
    fi
}

set_npm_registry() {
    local registry="$1"
    local current_registry
    current_registry="$(npm get registry 2>/dev/null || true)"
    log_info "当前 npm 源: ${current_registry:-未知}"
    npm config set registry "$registry"
    log_info "已切换 npm 源到: $(npm get registry)"
}

version_installed() {
    local version="$1"
    nvm ls "$version" 2>/dev/null | grep -q "v${version}\|${version}"
}

usage() {
    cat <<'EOF'
用法:
  switch_node_version.sh [选项]

选项:
  --install <版本>   安装指定 Node.js 版本
  --delete <版本>    删除指定已安装版本
  --default <版本>   设置指定版本为默认
  --registry <地址>  设置 npm 镜像源（如 https://registry.npmmirror.com）
  --skip-remote      跳过远程版本列表查询
  -h, --help         显示帮助

说明:
  1) 不传参数时为交互模式
  2) 传任意参数时为非交互模式
  3) 默认仅展示最新 5 个 LTS 可安装版本

传参示例:
  # 安装并设置默认版本
  switch_node_version.sh --install 20 --default 20

  # 删除已安装版本
  switch_node_version.sh --delete 18.20.8

  # 设置 npm 源并跳过远程版本查询
  switch_node_version.sh --registry https://registry.npmmirror.com --skip-remote

  # 组合操作（按 安装 -> 删除 -> 设默认 -> 设源 顺序执行）
  switch_node_version.sh --install 22 --delete 18.20.8 --default 22 --registry https://registry.npmmirror.com
EOF
}

INSTALL_VER_ARG=""
DELETE_VER_ARG=""
DEFAULT_VER_ARG=""
REGISTRY_ARG=""
SKIP_REMOTE=false
NON_INTERACTIVE=false

while [ $# -gt 0 ]; do
    case "$1" in
        --install)
            INSTALL_VER_ARG="${2:-}"
            shift 2
            ;;
        --delete)
            DELETE_VER_ARG="${2:-}"
            shift 2
            ;;
        --default)
            DEFAULT_VER_ARG="${2:-}"
            shift 2
            ;;
        --registry)
            REGISTRY_ARG="${2:-}"
            shift 2
            ;;
        --skip-remote)
            SKIP_REMOTE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            usage
            exit 1
            ;;
    esac
done

if [ -n "${INSTALL_VER_ARG}" ] || [ -n "${DELETE_VER_ARG}" ] || [ -n "${DEFAULT_VER_ARG}" ] || [ -n "${REGISTRY_ARG}" ]; then
    NON_INTERACTIVE=true
fi

log_step "加载 nvm 环境"
load_nvm
if ! command -v nvm >/dev/null 2>&1; then
    install_nvm
    load_nvm
fi
if ! command -v nvm >/dev/null 2>&1; then
    log_error "nvm 安装或加载失败，请检查 ~/.nvm/nvm.sh"
    exit 1
fi

log_step "列出当前已安装的 Node.js 版本"
nvm ls

echo
if [ "${SKIP_REMOTE}" = true ]; then
    log_warn "已跳过远程版本列表查询"
else
    log_step "列出可安装的最新版本"
    show_remote_versions
fi

if [ "${NON_INTERACTIVE}" = true ]; then
    log_step "非交互模式执行"

    if [ -n "${INSTALL_VER_ARG}" ]; then
        install_node_version "${INSTALL_VER_ARG}"
    fi

    if [ -n "${DELETE_VER_ARG}" ]; then
        if version_installed "${DELETE_VER_ARG}"; then
            log_step "删除 Node.js ${DELETE_VER_ARG}"
            nvm uninstall "${DELETE_VER_ARG}"
            log_info "删除完成"
        else
            log_warn "版本 ${DELETE_VER_ARG} 未安装，跳过删除"
        fi
    fi

    if [ -n "${DEFAULT_VER_ARG}" ]; then
        set_default_version "${DEFAULT_VER_ARG}"
    fi

    if [ -n "${REGISTRY_ARG}" ]; then
        set_npm_registry "${REGISTRY_ARG}"
    fi
else
    echo
    read -r -p "是否安装某个 Node.js 版本？(y/N): " need_install
    if [[ "${need_install}" =~ ^[Yy]$ ]]; then
        read -r -p "请输入要安装的版本号（如 22.14.0 或 20）: " install_ver
        if [ -n "${install_ver}" ]; then
            install_node_version "${install_ver}"
        else
            log_warn "未输入版本号，跳过安装"
        fi
    fi

    echo
    read -r -p "是否删除已安装的某个 Node.js 版本？(y/N): " need_delete
    if [[ "${need_delete}" =~ ^[Yy]$ ]]; then
        read -r -p "请输入要删除的版本号（如 18.20.8）: " delete_ver
        if [ -z "${delete_ver}" ]; then
            log_warn "未输入版本号，跳过删除"
        elif version_installed "${delete_ver}"; then
            log_step "删除 Node.js ${delete_ver}"
            nvm uninstall "${delete_ver}"
            log_info "删除完成"
        else
            log_warn "版本 ${delete_ver} 未安装，跳过删除"
        fi
    fi

    echo
    read -r -p "是否设置某个 Node.js 版本为默认版本？(y/N): " need_default
    if [[ "${need_default}" =~ ^[Yy]$ ]]; then
        read -r -p "请输入要设为默认的版本号（如 20.19.0）: " default_ver
        if [ -z "${default_ver}" ]; then
            log_warn "未输入版本号，跳过设置默认"
        else
            set_default_version "${default_ver}"
        fi
    fi

    echo
    read -r -p "是否配置 npm 镜像源？(y/N): " need_registry
    if [[ "${need_registry}" =~ ^[Yy]$ ]]; then
        read -r -p "请输入 npm 源地址（默认 https://registry.npmmirror.com）: " registry_input
        if [ -z "${registry_input}" ]; then
            registry_input="https://registry.npmmirror.com"
        fi
        set_npm_registry "${registry_input}"
    fi
fi

echo
log_step "最终版本状态"
nvm ls
log_info "脚本执行完成"