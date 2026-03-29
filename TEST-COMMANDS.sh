#!/bin/bash
# DWC 项目测试命令参考
# 复制粘贴使用的常用命令集合
# 使用方式: 根据需要复制命令到终端

# ═══════════════════════════════════════════════════════════════
# 📍 导航命令
# ═══════════════════════════════════════════════════════════════

# 进入项目根目录
cd /workspaces/dwc

# 进入 noVNC 项目
cd /workspaces/dwc/novnc

# 返回项目根目录
cd ..


# ═══════════════════════════════════════════════════════════════
# 🔧 代码质量检查
# ═══════════════════════════════════════════════════════════════

# 检查代码风格
npm run lint

# 自动修复可修复的问题
npm run lint -- --fix

# 检查特定文件
npm run lint -- app/audio.js
npm run lint -- app/ui.js


# ═══════════════════════════════════════════════════════════════
# 🧪 单元测试
# ═══════════════════════════════════════════════════════════════

# 运行完整测试套件（需要浏览器）
npm test

# 指定浏览器运行测试
export TEST_BROWSER_NAME=ChromeHeadless
npm test

# 使用 Firefox
export TEST_BROWSER_NAME=Firefox
npm test

# 使用多个浏览器
export TEST_BROWSER_NAME=Chrome,Firefox
npm test

# 集成测试运行单个模块
npx mocha tests/test.base64.js
npx mocha tests/test.rfb.js
npx mocha tests/test.keyboard.js
npx mocha tests/test.display.js


# ═══════════════════════════════════════════════════════════════
# 🔒 安全审计
# ═══════════════════════════════════════════════════════════════

# 审计依赖漏洞
npm audit

# 查看详细漏洞报告
npm audit --detailed

# 修复低风险漏洞
npm audit fix

# 强制修复所有漏洞（可能破坏兼容性）
npm audit fix --force

# 生成审计报告 JSON
npm audit --json > audit-report.json


# ═══════════════════════════════════════════════════════════════
# 📦 依赖管理
# ═══════════════════════════════════════════════════════════════

# 安装依赖
npm install

# 清除缓存后重新安装
npm cache clean --force && npm install

# 更新过时的依赖
npm update

# 检查过时的依赖
npm outdated

# 列出所有依赖
npm list


# ═══════════════════════════════════════════════════════════════
# 🐳 Docker 测试环境
# ═══════════════════════════════════════════════════════════════

# 进入开发容器
docker-compose exec dev bash

# 在容器中运行 lint
docker-compose exec dev sh -c "cd /workspaces/dwc/novnc && npm run lint"

# 在容器中运行测试
docker-compose exec dev sh -c "cd /workspaces/dwc/novnc && npm test"

# 查看容器日志
docker-compose logs dev

# 启动容器
docker-compose up -d dev

# 停止容器
docker-compose down


# ═══════════════════════════════════════════════════════════════
# 📊 报告查看
# ═══════════════════════════════════════════════════════════════

# 查看完整测试报告
cat /workspaces/dwc/TEST-REPORT.md

# 查看测试摘要
cat /workspaces/dwc/TEST-SUMMARY.md

# 查看快速参考
cat /workspaces/dwc/TESTING-QUICK-REFERENCE.md

# 查看测试结果
cat /workspaces/dwc/TESTING-RESULTS.txt

# 查看文档索引
cat /workspaces/dwc/TESTING-INDEX.md

# 在 less 中查看（按 q 退出）
less /workspaces/dwc/TEST-REPORT.md

# 在 vim 中编辑
vim /workspaces/dwc/novnc/app/audio.js


# ═══════════════════════════════════════════════════════════════
# 🔄 工作流快速命令
# ═══════════════════════════════════════════════════════════════

# 【完整测试流程】
cd /workspaces/dwc/novnc && \
npm run lint && \
npm audit && \
echo "✅ 代码质量检查完成"

# 【修复所有可修复问题】
cd /workspaces/dwc/novnc && \
npm run lint -- --fix && \
npm audit fix && \
npm run lint && \
echo "✅ 所有问题已修复"

# 【生成审计报告】
cd /workspaces/dwc/novnc && \
npm audit --json > audit-$(date +%Y%m%d).json && \
echo "✅ 审计报告已生成: audit-$(date +%Y%m%d).json"

# 【验证修改】
cd /workspaces/dwc && \
git status && \
git diff novnc/app/audio.js | head -50

# 【查看所有修改】
cd /workspaces/dwc && \
git log --oneline | head -10


# ═══════════════════════════════════════════════════════════════
# 🎯 调试和故障排除
# ═══════════════════════════════════════════════════════════════

# 启用音频调试日志（在浏览器控制台运行）
localStorage.setItem('DEBUG_AUDIO', 'true');
location.reload();

# 禁用音频调试日志
localStorage.removeItem('DEBUG_AUDIO');
location.reload();

# 查看 npm 脚本列表
npm run

# 检查 Node.js 和 npm 版本
node --version && npm --version

# 清空 npm 缓存
npm cache clean --force

# 删除 node_modules 并重新安装
rm -rf node_modules package-lock.json && npm install

# 看 node_modules 大小
du -sh node_modules

# 列出全局安装的包
npm list -g --depth=0


# ═══════════════════════════════════════════════════════════════
# 📈 性能和分析
# ═══════════════════════════════════════════════════════════════

# 测试执行时间测量
time npm run lint

# 获取依赖树
npm list

# 分析包大小
npm list --prod

# 查找必要的更新
npm outdated

# 检查安全漏洞详情
npm audit --json | jq .vulnerabilities


# ═══════════════════════════════════════════════════════════════
# 💡 有用的 Tips
# ═══════════════════════════════════════════════════════════════

# 并行运行多个命令
npm run lint && npm test &

# 在后台运行测试
npm test > test-results.log 2>&1 &

# 检查特定依赖
npm list webpack

# 查看依赖的详细信息
npm view package-name@version

# 获取最新版本信息
npm search test-framework


# ═══════════════════════════════════════════════════════════════
# 📝 常见问题快速修复
# ═══════════════════════════════════════════════════════════════

# 问题: 包安装缓存导致问题
# 解决: 
npm cache clean --force
rm -rf node_modules package-lock.json
npm install

# 问题: ESLint 显示过期的错误
# 解决:
npm run lint -- --fix
npm run lint

# 问题: 安全漏洞过多
# 解决:
npm audit
npm audit fix
npm audit fix --force

# 问题: 测试时浏览器不可用
# 解决:
export TEST_BROWSER_NAME=ChromeHeadless
npm test 2>&1 | tee test-log.txt

# 问题: npm 命令很慢
# 解决:
npm cache clean --force --prefer-offline --no-audit


# ═══════════════════════════════════════════════════════════════
# ✨ 最常用的命令 (快速参考)
# ═══════════════════════════════════════════════════════════════

# [最常用] 检查代码风格
cd /workspaces/dwc/novnc && npm run lint

# [最常用] 修复风格问题
cd /workspaces/dwc/novnc && npm run lint -- --fix

# [最常用] 查看审计
cd /workspaces/dwc/novnc && npm audit

# [最常用] 在 Docker 中测试
cd /workspaces/dwc && docker-compose exec dev sh -c "cd novnc && npm run lint"


# ═══════════════════════════════════════════════════════════════
# 🚀 一键执行脚本
# ═══════════════════════════════════════════════════════════════

# 创建并运行完整测试脚本
cat > /tmp/test-dwc.sh << 'SCRIPT'
#!/bin/bash
set -e

echo "🚀 DWC 项目完整测试开始..."
cd /workspaces/dwc/novnc

echo ""
echo "📋 步骤 1: 检查代码风格..."
npm run lint

echo ""
echo "🔒 步骤 2: 安全审计..."
npm audit

echo ""
echo "✅ 所有测试完成！"
echo ""
echo "📊 测试报告位置:"
echo "  - /workspaces/dwc/TEST-REPORT.md"
echo "  - /workspaces/dwc/TEST-SUMMARY.md"
echo "  - /workspaces/dwc/TESTING-RESULTS.txt"
SCRIPT

chmod +x /tmp/test-dwc.sh
/tmp/test-dwc.sh


# ═══════════════════════════════════════════════════════════════
# 📌 最后一条命令: 重置工作环境
# ═══════════════════════════════════════════════════════════════

# 回到项目根目录
cd /workspaces/dwc

# 显示项目结构
tree -L 2 -I 'node_modules'

# 显示最终状态
echo "✅ 项目已就绪！查看报告: cat TESTING-RESULTS.txt"
