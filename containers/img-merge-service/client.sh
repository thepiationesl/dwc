#!/usr/bin/env bash
set -Eeuo pipefail

# IMG MERGE CLIENT - 磁盘镜像合并客户端
# 用于从IMG MERGE SERVICE拉取磁盘镜像

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_SERVER="http://localhost:8080"
DEFAULT_TIMEOUT=300
DEFAULT_CHUNK_SIZE=8192

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# 显示帮助
show_help() {
    cat << EOF
IMG MERGE CLIENT - 磁盘镜像合并客户端

用法: $0 [选项] <命令> [参数...]

命令:
  list                     列出服务器上的所有镜像
  pull <remote> [local]    从服务器拉取镜像
  push <local> [remote]    推送镜像到服务器
  info <image>             获取镜像信息
  delete <image>           删除服务器上的镜像
  health                   检查服务器健康状态

选项:
  -s, --server <url>       服务器URL (默认: $DEFAULT_SERVER)
  -t, --timeout <seconds>  超时时间 (默认: $DEFAULT_TIMEOUT)
  -d, --debug              启用调试模式
  -h, --help               显示此帮助信息

环境变量:
  IMG_MERGE_SERVER         服务器URL
  IMG_MERGE_TIMEOUT        超时时间
  DEBUG                    调试模式

示例:
  $0 list
  $0 pull windows.img
  $0 pull windows.img my-windows.img
  $0 push my-disk.img server-disk.img
  $0 info windows.img

EOF
}

# 解析参数
SERVER="${IMG_MERGE_SERVER:-$DEFAULT_SERVER}"
TIMEOUT="${IMG_MERGE_TIMEOUT:-$DEFAULT_TIMEOUT}"
DEBUG="${DEBUG:-false}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--server)
            SERVER="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -d|--debug)
            DEBUG="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# 检查依赖
check_dependencies() {
    local deps=("curl" "jq")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "缺少依赖: $dep"
            exit 1
        fi
    done
}

# API 调用函数
api_call() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local output_file="${4:-}"
    
    local url="${SERVER}/api/v1/${endpoint}"
    
    log_debug "API调用: $method $url"
    
    local curl_args=(
        -s
        -w "%{http_code}"
        --connect-timeout 10
        --max-time "$TIMEOUT"
    )
    
    if [[ -n "$output_file" ]]; then
        curl_args+=(-o "$output_file")
    fi
    
    if [[ -n "$data" ]]; then
        curl_args+=(-H "Content-Type: application/json" -d "$data")
    fi
    
    local response
    response=$(curl "${curl_args[@]}" -X "$method" "$url" 2>&1)
    
    local http_code="${response: -3}"
    local body="${response:0:${#response}-3}"
    
    log_debug "HTTP状态码: $http_code"
    
    if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
        echo "$body"
        return 0
    else
        log_error "API调用失败 (HTTP $http_code): $body"
        return 1
    fi
}

# 列出镜像
list_images() {
    log_info "获取镜像列表..."
    
    local response
    response=$(api_call "GET" "images")
    
    if [[ $? -eq 0 ]]; then
        echo "$response" | jq -r '.images[] | "\(.name)\t\(.size)\t\(.modified)"' | column -t -s $'\t'
        echo ""
        echo "总计: $(echo "$response" | jq '.count') 个镜像"
    fi
}

# 拉取镜像
pull_image() {
    local remote_name="$1"
    local local_name="${2:-$remote_name}"
    
    log_info "从服务器拉取镜像: $remote_name -> $local_name"
    
    # 检查本地文件是否已存在
    if [[ -f "$local_name" ]]; then
        log_warn "本地文件已存在: $local_name"
        read -p "是否覆盖? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "操作已取消"
            return 0
        fi
    fi
    
    # 下载文件
    local url="${SERVER}/api/v1/images/${remote_name}"
    
    log_debug "下载URL: $url"
    
    if curl -fSL --connect-timeout 10 --max-time "$TIMEOUT" -o "$local_name" "$url" 2>&1; then
        log_info "镜像下载成功: $local_name"
        
        # 显示文件信息
        if command -v ls &> /dev/null; then
            ls -lh "$local_name"
        fi
    else
        log_error "下载失败"
        rm -f "$local_name"
        return 1
    fi
}

# 推送镜像
push_image() {
    local local_file="$1"
    local remote_name="${2:-$(basename "$local_file")}"
    
    if [[ ! -f "$local_file" ]]; then
        log_error "本地文件不存在: $local_file"
        return 1
    fi
    
    log_info "推送镜像到服务器: $local_file -> $remote_name"
    
    local url="${SERVER}/api/v1/images/${remote_name}"
    
    log_debug "上传URL: $url"
    
    local response
    response=$(curl -s -w "%{http_code}" -F "file=@${local_file}" "$url" 2>&1)
    
    local http_code="${response: -3}"
    local body="${response:0:${#response}-3}"
    
    if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
        log_info "镜像上传成功"
        echo "$body" | jq .
    else
        log_error "上传失败 (HTTP $http_code): $body"
        return 1
    fi
}

# 获取镜像信息
get_image_info() {
    local image_name="$1"
    
    log_info "获取镜像信息: $image_name"
    
    local response
    response=$(api_call "GET" "info/$image_name")
    
    if [[ $? -eq 0 ]]; then
        echo "$response" | jq .
    fi
}

# 删除镜像
delete_image() {
    local image_name="$1"
    
    log_info "删除服务器上的镜像: $image_name"
    
    read -p "确认删除? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then log_info "操作已取消"
        return 0
    fi
    
    local response
    response=$(api_call "DELETE" "images/$image_name")
    
    if [[ $? -eq 0 ]]; then
        log_info "镜像删除成功"
        echo "$response" | jq .
    fi
}

# 检查服务器健康状态
check_health() {
    log_info "检查服务器健康状态..."
    
    local response
    response=$(api_call "GET" "health")
    
    if [[ $? -eq 0 ]]; then
        log_info "服务器状态: $(echo "$response" | jq -r '.status')"
        echo "$response" | jq .
    fi
}

# 主函数
main() {
    check_dependencies
    
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        list)
            list_images
            ;;
        pull)
            if [[ $# -lt 1 ]]; then
                log_error "用法: $0 pull <remote> [local]"
                exit 1
            fi
            pull_image "$@"
            ;;
        push)
            if [[ $# -lt 1 ]]; then
                log_error "用法: $0 push <local> [remote]"
                exit 1
            fi
            push_image "$@"
            ;;
        info)
            if [[ $# -lt 1 ]]; then
                log_error "用法: $0 info <image>"
                exit 1
            fi
            get_image_info "$1"
            ;;
        delete)
            if [[ $# -lt 1 ]]; then
                log_error "用法: $0 delete <image>"
                exit 1
            fi
            delete_image "$1"
            ;;
        health)
            check_health
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
