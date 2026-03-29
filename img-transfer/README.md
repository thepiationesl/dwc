# img-transfer v2.0.0

VM镜像动态迁移工具 - 多线程、断点续传、自动清理

## 特性

- **多线程下载**: 默认4线程并发
- **断点续传**: 中断后自动从断点继续
- **动态迁移**: 下载完成后自动删除源文件，不占双倍空间
- **静态编译**: 单二进制，无依赖

## 使用

### 服务端(有镜像的机器)

```bash
# 基本用法
./img-transfer serve -dir /vm -port 8080

# 下载后自动删除源文件
./img-transfer serve -dir /vm -port 8080 -delete-after

# 带认证令牌
./img-transfer serve -dir /vm -port 8080 -token mysecret
```

### 客户端(Codespaces)

```bash
# 拉取文件
./img-transfer pull -server http://host:8080 -file disk.img

# 多线程+指定块大小
./img-transfer pull -server http://host:8080 -file disk.img -workers 8 -chunk 100

# 拉取并让服务端删除源文件(动态迁移)
./img-transfer pull -server http://host:8080 -file disk.img -delete

# 带认证
./img-transfer pull -server http://host:8080 -file disk.img -token mysecret
```

### API

```bash
# 列出文件
curl http://host:8080/list

# 获取文件信息
curl http://host:8080/info/disk.img

# 下载文件(支持Range断点续传)
curl -H "Range: bytes=0-1048575" http://host:8080/download/disk.img
```

## 编译

```bash
# Linux
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o img-transfer .

# macOS
GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -o img-transfer .

# Windows
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o img-transfer.exe .
```
