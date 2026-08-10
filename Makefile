# dwc - 无特权云工作站构建入口
# 用法：
#   make list            # 列出全部镜像
#   make build           # 构建全部镜像
#   make build IMG=desk  # 构建单个镜像
#   make run IMG=desk    # 运行单个镜像（交互式）
#   make clean IMG=desk  # 删除镜像

IMAGES = desk full lite lite-ice asbru studio py browser jump chat code build vm tor
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

run:
	@echo "==> 运行 $(IMG) (交互式, 端口映射见 Dockerfile EXPOSE)"
	docker run --rm -it \
		-p 2222:2222 \
		-v dwc-$(IMG)-config:/config \
		-v $$(pwd):/workspace \
		--name dwc-$(IMG) \
		$(REGISTRY)dwc-$(IMG):$(TAG)

clean:
	@echo "==> 清理 $(IMG)"
	docker rmi $(REGISTRY)dwc-$(IMG):$(TAG) 2>/dev/null || true
