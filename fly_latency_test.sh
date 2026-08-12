#!/bin/bash

# ==============================================================================
# Fly.io 延迟测试脚本
# 说明：Fly.io 使用 Anycast 网络，默认会将请求路由到离你最近的机房。
# 这个脚本会：
# 1. 测试你连接到 Fly.io 边缘网络（最近机房）的延迟
# 2. 获取你当前被路由到的具体机房代码
# ==============================================================================

echo "🔍 正在测试连接到 Fly.io 边缘网络的延迟..."
echo "---------------------------------------------------"

# 测试基础延迟
PING_TIME=$(curl -o /dev/null -s -w "%{time_total}\n" https://debug.fly.dev)
# 将秒转换为毫秒
LATENCY_MS=$(awk "BEGIN {print $PING_TIME * 1000}")

echo "⏱️  到最近 Fly.io 边缘节点的延迟约为: ${LATENCY_MS} ms"

# 获取当前被路由到的机房
REGION=$(curl -s https://debug.fly.dev | grep "Fly-Region" | awk '{print $2}')
if [ -z "$REGION" ]; then
    REGION="未知"
fi
echo "📍 你当前被 Anycast 路由到的机房是: ${REGION}"

echo "---------------------------------------------------"
echo "⚠️  注意："
echo "Fly.io 采用了 Anycast IP，外部网络无法直接 ping 通所有单独的区域（Region）。"
echo "如果你想测试到其他特定机房的延迟，必须在该机房部署一个应用，然后使用："
echo "  flyctl ping <region_code>.app.internal"
echo "（通过 WireGuard 私有网络进行测试）"
