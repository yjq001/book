#!/bin/bash

# 目标 IP 列表
IPS=("129.213.121.96" "38.47.115.246" "66.241.124.210")

# 统一使用 22 端口（因为之前的测试显示这两个服务器都开放了 SSH 22 端口）
TEST_PORT=22
TEST_COUNT=20

echo "=========================================================="
echo "          网络连接质量 (TCP 延迟与丢包率) 评测"
echo "=========================================================="
echo "评测时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "测试目标: ${IPS[*]} (基于 TCP $TEST_PORT 端口)"
echo "⚠️ 由于部分节点禁 Ping，本次已自动切换为 TCP 原生探测"
echo "=========================================================="
echo ""

declare -A LOSS_RATE
declare -A AVG_LATENCY

for IP in "${IPS[@]}"; do
    echo "----------------------------------------------------------"
    echo "  正在测试目标 IP: $IP:$TEST_PORT (发送 $TEST_COUNT 次握手...)"
    echo "----------------------------------------------------------"

    SUCCESS=0
    TOTAL_TIME=0
    
    # 手动实现一个简易版 TCP Ping
    for ((i=1; i<=TEST_COUNT; i++)); do
        # 获取毫秒级时间戳
        START=$(date +%s%3N)
        
        # 使用 nc 尝试 TCP 握手，超时设为 2 秒
        if nc -w 2 -z $IP $TEST_PORT &>/dev/null; then
            END=$(date +%s%3N)
            ELAPSED=$((END - START))
            TOTAL_TIME=$((TOTAL_TIME + ELAPSED))
            SUCCESS=$((SUCCESS + 1))
            echo "TCP 握手成功来自 $IP:$TEST_PORT，时间=${ELAPSED}ms"
        else
            echo "TCP 请求超时或被拒绝。"
        fi
        
        # 测试间隔
        sleep 0.2
    done
    
    # 计算丢包率
    LOSS=$(( (TEST_COUNT - SUCCESS) * 100 / TEST_COUNT ))
    
    # 计算平均延迟
    if [ $SUCCESS -gt 0 ]; then
        AVG_MS=$(( TOTAL_TIME / SUCCESS ))
    else
        AVG_MS="N/A"
    fi
    
    LOSS_RATE[$IP]=$LOSS
    AVG_LATENCY[$IP]=$AVG_MS
    
    echo ""
    echo "统计结果: 发送=$TEST_COUNT, 成功=$SUCCESS, 丢包率=${LOSS}%"
    if [ "$AVG_MS" != "N/A" ]; then
        echo "平均 TCP 握手延迟 = ${AVG_MS}ms"
    fi
    echo ""
done

echo "=========================================================="
echo "                      🌟 性能报告总结 🌟"
echo "=========================================================="
printf "%-18s | %-10s | %-13s | %-15s\n" "目标 IP" "丢包率" "平均延迟 (ms)" "链路评级"
echo "----------------------------------------------------------"

for IP in "${IPS[@]}"; do
    LOSS=${LOSS_RATE[$IP]}
    LATENCY=${AVG_LATENCY[$IP]}
    RATING="未知"
    
    if [ "$LOSS" -eq 100 ]; then
        RATING="❌ 离线/阻断"
    elif [ "$LOSS" -gt 10 ]; then
        RATING="⚠️ 极差 (高丢包)"
    elif [ "$LATENCY" == "N/A" ]; then
        RATING="❌ 无法测算"
    else
        # 粗略判断延迟
        LATENCY_INT=${LATENCY%.*}
        if [ "$LOSS" -gt 0 ]; then
            RATING="⚠️ 波动 (轻微丢包)"
        elif [ "$LATENCY_INT" -lt 80 ]; then
            RATING="⭐⭐⭐ 极佳"
        elif [ "$LATENCY_INT" -lt 180 ]; then
            RATING="⭐⭐ 良好"
        elif [ "$LATENCY_INT" -lt 300 ]; then
            RATING="⭐ 一般"
        else
            RATING="🐢 较差"
        fi
    fi
    
    printf "%-16s | %-10s | %-13s | %-15s\n" "$IP" "${LOSS}%" "$LATENCY" "$RATING"
done

echo ""
echo "=========================================================="
echo "                      💡 最终分析结论"
echo "=========================================================="
for IP in "${IPS[@]}"; do
    LOSS=${LOSS_RATE[$IP]}
    LATENCY=${AVG_LATENCY[$IP]}
    
    echo -n "👉 [${IP}] : "
    if [ "$LOSS" -eq 100 ]; then
        echo "22 端口 TCP 握手完全失败。服务器可能关机，或者 SSH 端口被阻断。"
    elif [ "$LOSS" -gt 10 ]; then
        echo "TCP 丢包率高达 ${LOSS}%，连接极度不稳定。不建议用于生产环境，或者任何依赖长连接的服务（极易断开）。"
    elif [ "$LOSS" -gt 0 ]; then
        echo "存在 ${LOSS}% 的 TCP 丢包，说明网络存在抖动或拥堵。可能会出现连接中断重连，适合对稳定性要求不高的场景。"
    else
        LATENCY_INT=${LATENCY%.*}
        if [ "$LATENCY_INT" -lt 80 ]; then
            echo "0丢包且 TCP 延迟极低 (${LATENCY}ms)。网络质量优秀，响应迅速，非常适合作为主力节点使用！"
        elif [ "$LATENCY_INT" -lt 180 ]; then
            echo "0丢包，TCP 延迟处于正常国际线路水平 (${LATENCY}ms)。连接非常稳定，适合日常服务调用。"
        elif [ "$LATENCY_INT" -lt 300 ]; then
            echo "0丢包，TCP 延迟偏高 (${LATENCY}ms)。连接虽稳但建联慢，建议只做非实时性任务使用。"
        else
            echo "0丢包，但是延迟极高 (${LATENCY}ms)，通常是绕路非常严重。请避免对交互性强的应用使用此线路。"
        fi
    fi
done
echo "=========================================================="
