# IMG MERGE SERVICE - 磁盘镜像合并服务
# 用于在VM容器间同步和合并磁盘镜像文件
# 支持Cloudflare Tunnel

FROM python:3.11-slim

LABEL maintainer="DWC Project"
LABEL description="IMG MERGE SERVICE - Disk image merge service for VM containers"
LABEL version="1.0.0"

# 环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    STORAGE_DIR=/storage \
    PORT=8080 \
    HOST=0.0.0.0 \
    MAX_CONTENT_LENGTH=10737418240 \
    DEBUG=false

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 基础工具
    curl \
    wget \
    jq \
    procps \
    # 磁盘工具
    qemu-utils \
    # 网络工具
    netcat-openbsd \
    iproute2 \
    # 用于Cloudflare Tunnel
    cloudflared \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 创建目录
RUN mkdir -p /storage /app /var/log/img-merge && \
    chmod 755 /storage /app /var/log/img-merge

# 复制应用文件
COPY requirements.txt /app/
COPY app.py /app/
COPY entrypoint.sh /app/
COPY cloudflared-config.yaml /app/

# 安装Python依赖
RUN pip install --no-cache-dir -r /app/requirements.txt

# 设置权限
RUN chmod +x /app/entrypoint.sh

# 工作目录
WORKDIR /app

# 卷
VOLUME ["/storage"]

# 端口: HTTP API
EXPOSE 8080

# 入口点
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["python", "app.py"]
