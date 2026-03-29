#!/usr/bin/env bash
set -Eeuo pipefail

# IMG MERGE SERVICE Entrypoint
# 支持Cloudflare Tunnel

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查环境
check_environment() {
    log_info "Checking environment..."
    
    # 检查存储目录
    if [[ ! -d "${STORAGE_DIR}" ]]; then
        log_warn "Storage directory ${STORAGE_DIR} does not exist, creating..."
        mkdir -p "${STORAGE_DIR}"
    fi
    
    # 检查端口
    if [[ -z "${PORT}" ]]; then
        log_error "PORT environment variable is not set"
        exit 1
    fi
    
    # 检查qemu-img
    if ! command -v qemu-img &> /dev/null; then
        log_warn "qemu-img not found, some features may not work"
    fi
    
    log_info "Environment check completed"
}

# 配置Cloudflare Tunnel
setup_cloudflare_tunnel() {
    if [[ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]]; then
        log_info "Setting up Cloudflare Tunnel..."
        
        # 创建cloudflared配置目录
        mkdir -p /etc/cloudflared
        
        # 复制配置文件
        if [[ -f "/app/cloudflared-config.yaml" ]]; then
            cp /app/cloudflared-config.yaml /etc/cloudflared/config.yml
        else
            # 创建基本配置
            cat > /etc/cloudflared/config.yml << EOF
tunnel: ${CLOUDFLARE_TUNNEL_TOKEN}
credentials-file: /etc/cloudflared/credentials.json

ingress:
  - service: http://localhost:${PORT}
EOF
        fi
        
        # 启动cloudflared（后台运行）
        log_info "Starting Cloudflare Tunnel..."
        cloudflared tunnel --config /etc/cloudflared/config.yml run &
        
        # 等待隧道建立
        sleep 5
        
        log_info "Cloudflare Tunnel started"
    else
        log_info "No Cloudflare Tunnel token provided, skipping tunnel setup"
    fi
}

# 信号处理
cleanup() {
    log_info "Shutting down..."
    
    # 停止cloudflared
    if pgrep cloudflared > /dev/null; then
        log_info "Stopping Cloudflare Tunnel..."
        pkill cloudflared
    fi
    
    log_info "Cleanup completed"
    exit 0
}

# 设置信号处理
trap cleanup SIGTERM SIGINT

# 主函数
main() {
    log_info "Starting IMG MERGE SERVICE..."
    
    # 检查环境
    check_environment
    
    # 设置Cloudflare Tunnel
    setup_cloudflare_tunnel
    
    # 启动应用
    log_info "Starting application..."
    exec "$@"
}

# 运行主函数
main "$@"
