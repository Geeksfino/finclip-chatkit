.PHONY: help build clean install run start stop uninstall lint test check-device apk debug release

# 应用配置
APP_PACKAGE := com.finclip.chatkit.examples
MAIN_ACTIVITY := com.finclip.chatkit.examples/.MainActivity
APK_DEBUG := app/build/outputs/apk/debug/app-debug.apk
APK_RELEASE := app/build/outputs/apk/release/app-release.apk

# 默认目标
.DEFAULT_GOAL := help

# 显示帮助信息
help:
	@echo "ChatKit Android 示例应用 - Makefile 命令"
	@echo ""
	@echo "可用命令："
	@echo "  make build          - 构建 Debug APK"
	@echo "  make debug          - 构建 Debug APK（同 build）"
	@echo "  make release        - 构建 Release APK"
	@echo "  make clean          - 清理构建文件"
	@echo "  make install        - 安装 Debug 版本到设备"
	@echo "  make uninstall      - 从设备卸载应用"
	@echo "  make run            - 构建、安装并启动应用"
	@echo "  make start          - 启动已安装的应用"
	@echo "  make stop           - 停止运行中的应用"
	@echo "  make apk            - 仅构建 APK（不安装）"
	@echo "  make lint           - 运行代码检查"
	@echo "  make test           - 运行单元测试"
	@echo "  make check-device   - 检查设备连接状态"
	@echo "  make logcat         - 查看应用日志"
	@echo "  make logcat-clear   - 清除日志缓冲区"
	@echo ""

# 检查设备连接
check-device:
	@echo "检查设备连接..."
	@adb devices | grep -q "device$$" || (echo "错误：未检测到已连接的设备或模拟器" && exit 1)
	@echo "✓ 设备已连接"

# 构建 Debug APK
build: check-device
	@echo "构建 Debug APK..."
	@./gradlew assembleDebug
	@echo "✓ 构建完成: $(APK_DEBUG)"

# 构建 Debug APK（别名）
debug: build

# 构建 Release APK
release:
	@echo "构建 Release APK..."
	@./gradlew assembleRelease
	@echo "✓ 构建完成: $(APK_RELEASE)"

# 仅构建 APK（不检查设备）
apk:
	@echo "构建 Debug APK..."
	@./gradlew assembleDebug
	@echo "✓ 构建完成: $(APK_DEBUG)"

# 清理构建文件
clean:
	@echo "清理构建文件..."
	@./gradlew clean
	@echo "✓ 清理完成"

# 安装 Debug 版本到设备
install: check-device build
	@echo "安装应用到设备..."
	@./gradlew installDebug
	@echo "✓ 安装完成"

# 卸载应用
uninstall: check-device
	@echo "卸载应用..."
	@adb uninstall $(APP_PACKAGE) || echo "应用未安装或已卸载"
	@echo "✓ 卸载完成"

# 启动应用
start: check-device
	@echo "启动应用..."
	@adb shell am start -n $(MAIN_ACTIVITY)
	@echo "✓ 应用已启动"

# 停止应用
stop: check-device
	@echo "停止应用..."
	@adb shell am force-stop $(APP_PACKAGE)
	@echo "✓ 应用已停止"

# 构建、安装并启动应用
run: install start
	@echo "✓ 应用已构建、安装并启动"

# 运行代码检查
lint:
	@echo "运行代码检查..."
	@./gradlew lint
	@echo "✓ 代码检查完成"

# 运行单元测试
test:
	@echo "运行单元测试..."
	@./gradlew test
	@echo "✓ 测试完成"

# 查看应用日志
logcat: check-device
	@echo "查看应用日志（按 Ctrl+C 退出）..."
	@adb logcat | grep -i "chatkit\|ExamplesApplication\|AndroidRuntime"

# 清除日志缓冲区
logcat-clear: check-device
	@echo "清除日志缓冲区..."
	@adb logcat -c
	@echo "✓ 日志缓冲区已清除"
