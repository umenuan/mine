#!/bin/sh

# 配置信息（需替换为实际值）
TELEGRAM_BOT_TOKEN="233"
TELEGRAM_CHAT_ID="233"

# 获取当前时间（带时区信息）
CURRENT_TIME=$(TZ='Asia/Shanghai' date +"%Y-%m-%d %H:%M:%S %Z")  # 可修改时区

# 构造消息内容
MESSAGE="🕒 当前时间：${CURRENT_TIME}"

# 发送到Telegram
curl -s -X POST \
  https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage \
  -d chat_id=${TELEGRAM_CHAT_ID} \
  -d text="${MESSAGE}" \
  -d parse_mode="HTML"

# 检查发送结果
if [ $? -eq 0 ]; then
  echo "[$(date)] 消息发送成功"
else
  echo "[$(date)] 消息发送失败"
fi