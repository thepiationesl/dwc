# dwc - 无特权云工作站构建入口
# 用法：
#   make list            # 列出全部镜像
#   make build           # 构建全部镜像
#   make build IMG=desk  # 构建单个镜像
#   make run IMG=desk    # 运行单个镜像（交互式，按镜像自动映射端口）
#   make clean IMG=desk  # 删除镜像

IMAGES = desk full lite lite-ice asbru studio py browser jump chat code build tor
REGISTRY ?=
TAG ?= latest
IMG ?= desk

.PHONY: list build run clean help

help:
	@echo "dwc 构建入口"
	@echo "  make list"
	@echo "  make build IMG=desk    (缺省构建全部)"
	@echo "  make run IMG=desk      (缺省运行 desk)"
	@echo "  make clean IMG=desk    (缺省清理全部)"

list:
	@echo "镜像清单："
	@for img in $(IMAGES); do echo "  $$img"; done

build: $(addprefix build/,$(IMAGES))

build/%:
	@img=$*; echo "==> 构建 $$img"
	docker build -t $(REGISTRY)dwc-$$img:$(TAG) -f images/$$img/Dockerfile .

# 按镜像类型映射端口（桌面型带 VNC/noVNC，远程型带各自服务端口）
# 端口来自各 Dockerfile 的 EXPOSE 与各 ENV 默认值（SSH_PORT=2222 等）
run:
	@case "$(IMG)" in \
	  desk|lite|lite-ice|asbru|py) \
	    docker run --rm -it -p 2222:2222 -p 5901:5901 -p 6080:6080 \
	      -v dwc-$(IMG)-config:/config -v $$(pwd):/workspace --name dwc-$(IMG) $(REGISTRY)dwc-$(IMG):$(TAG) ;; \
	  full|studio) \
	    docker run --rm -it -p 2222:2222 -p 5901:5901 -p 6080:6080 -p 3389:3389 -p 4000:4000 -p 7070:7070 \
	      -v dwc-$(IMG)-config:/config -v $$(pwd):/workspace --name dwc-$(IMG) $(REGISTRY)dwc-$(IMG):$(TAG) ;; \
	  code) \
	    docker run --rm -it -p 2222:2222 -p 8443:8443 \
	      -v dwc-$(IMG)-config:/config -v $$(pwd):/workspace --name dwc-$(IMG) $(REGISTRY)dwc-$(IMG):$(TAG) ;; \
	  tor) \
	    docker run --rm -it -p 2222:2222 -p 9050:9050 -p 9051:9051 -p 5353:5353 \
	      -v dwc-$(IMG)-config:/config --name dwc-$(IMG) $(REGISTRY)dwc-$(IMG):$(TAG) ;; \
	  jump) \
	    docker run --rm -it -p 2222:2222 \
	      -v dwc-$(IMG)-config:/config --name dwc-$(IMG) $(REGISTRY)dwc-$(IMG):$(TAG) ;; \
	  *) \
	    docker run --rm -it -p 2222:2222 \
	      -v dwc-$(IMG)-config:/config -v $$(pwd):/workspace --name dwc-$(IMG) $(REGISTRY)dwc-$(IMG):$(TAG) ;; \
	esac

clean:
	@echo "==> 清理 $(IMG)"
	docker rmi $(REGISTRY)dwc-$(IMG):$(TAG) 2>/dev/null || true
