#!/bin/bash
#
# 项目名称：clash-toggle
# 文件名称：clash.sh
# 创建时间：2026-02-27 20:48:49
#
# 系统用户：wyl
# 作　　者：無以菱
# 联系邮箱：huangjing510@126.com
# 功能描述：仅在当前终端会话中切换代理变量，支持 start|stop|status，未传参显示帮助信息
# 适用说明：当前默认自动探测逻辑主要面向 WSL 场景，非 WSL 建议手动传入 host 和 port
#

set -e

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

show_help() {
  echo -e "${CYAN}用法：${RESET}"
  echo '  eval "$(/data/claude/clash.sh start [host] [port])"'
  echo '  eval "$(/data/claude/clash.sh stop)"'
  echo '  /data/claude/clash.sh status'
  echo
  echo -e "${CYAN}命令：${RESET}"
  echo '  start [host] [port]   输出开启代理所需的 export 语句（默认自动探测 host，默认端口 7890）'
  echo '  stop                  输出关闭代理所需的 unset 语句'
  echo '  status                查看当前环境中的代理状态'
  echo
  echo -e "${CYAN}示例：${RESET}"
  echo '  eval "$(/data/claude/clash.sh start)"'
  echo '  eval "$(/data/claude/clash.sh start 172.31.112.1 7890)"'
  echo '  eval "$(/data/claude/clash.sh stop)"'
  echo '  /data/claude/clash.sh status'
  echo
  echo -e "${CYAN}说明：${RESET}"
  echo '  1) 本脚本不读写 ~/.bashrc'
  echo '  2) start/stop 需配合 eval 执行，才能作用于当前终端'
  echo '  3) status 显示 no_proxy=<empty> 表示未设置，属于正常状态'
}

proxy_detect_host() {
  if [ -n "${1:-}" ]; then
    printf '%s\n' "$1"
    return 0
  fi

  if [ -n "${CLASH_HOST:-}" ]; then
    printf '%s\n' "$CLASH_HOST"
    return 0
  fi

  local ns
  ns="$(awk '/^nameserver /{print $2; exit}' /etc/resolv.conf 2>/dev/null || true)"
  if [ -n "$ns" ]; then
    printf '%s\n' "$ns"
    return 0
  fi

  local gw
  gw="$(ip route 2>/dev/null | awk '/^default /{print $3; exit}' || true)"
  if [ -n "$gw" ]; then
    printf '%s\n' "$gw"
    return 0
  fi

  return 1
}

proxy_start() {
  local host
  local port

  host="$(proxy_detect_host "${1:-}")" || {
    echo -e "${RED}无法自动获取代理地址，请手动指定 host${RESET}" >&2
    echo "示例：eval \"$(/data/claude/clash.sh start 172.31.112.1 7890)\"" >&2
    return 1
  }
  port="${2:-${CLASH_PORT:-7890}}"

  printf 'export http_proxy=%q\n' "http://${host}:${port}"
  printf 'export https_proxy=%q\n' "http://${host}:${port}"

  if [ -t 1 ]; then
    echo -e "${YELLOW}检测到直接执行：当前仅输出命令，未生效${RESET}" >&2
    echo -e "${CYAN}请执行：eval \"$(${0} start ${host} ${port})\"${RESET}" >&2
  fi
}

proxy_stop() {
  echo "unset http_proxy https_proxy"

  if [ -t 1 ]; then
    echo -e "${YELLOW}检测到直接执行：当前仅输出命令，未生效${RESET}" >&2
    echo -e "${CYAN}请执行：eval \"$(${0} stop)\"${RESET}" >&2
  fi
}

proxy_status() {
  if [ -n "${http_proxy:-}" ] || [ -n "${https_proxy:-}" ]; then
    echo -e "代理状态 ${GREEN}[enable]${RESET}"
  else
    echo -e "代理状态 ${RED}[disable]${RESET}"
  fi
  echo "http_proxy=${http_proxy:-<empty>}"
  echo "https_proxy=${https_proxy:-<empty>}"
  if [ -n "${no_proxy:-}" ]; then
    echo "no_proxy=${no_proxy}"
  else
    echo "no_proxy=<empty> (未设置，正常)"
  fi
}

main() {
  case "${1:-}" in
    start)
      proxy_start "${2:-}" "${3:-}"
      ;;
    stop)
      proxy_stop
      ;;
    status)
      proxy_status
      ;;
    "")
      show_help
      ;;
    *)
      echo -e "${YELLOW}未知参数：$1${RESET}"
      show_help
      return 1
      ;;
  esac
}

main "$@"
