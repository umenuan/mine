#!/bin/bash

# 配置信息
API_KEY="xxx"
BOT_TOKEN="xxx"
CHAT_ID="xxx"
CITY="xxx"

# 获取天气数据
WEATHER_JSON=$(curl -s "http://api.openweathermap.org/data/2.5/weather?q=$CITY&appid=$API_KEY&units=metric&lang=zh_cn")

# 检查API响应是否有效
cod=$(echo "$WEATHER_JSON" | jq -r '.cod')
if [ "$cod" != "200" ]; then
    echo "错误：无法获取天气数据。API返回：$WEATHER_JSON"
    exit 1
fi

# 获取天气预报数据
API_RESPONSE=$(curl -s "http://api.openweathermap.org/data/2.5/forecast?q=$CITY&appid=$API_KEY&units=metric&lang=zh_cn")

# 检查API响应有效性
if [ $(echo "$API_RESPONSE" | jq -r '.cod') != "200" ]; then
  echo "API请求失败: $API_RESPONSE"
  exit 1
fi

# 解析基础字段
temp=$(echo "$WEATHER_JSON" | jq -r '.main.temp')
feels_like=$(echo "$WEATHER_JSON" | jq -r '.main.feels_like')
humidity=$(echo "$WEATHER_JSON" | jq -r '.main.humidity')
pressure=$(echo "$WEATHER_JSON" | jq -r '.main.pressure')
wind_speed=$(echo "$WEATHER_JSON" | jq -r '.wind.speed')
weather_desc=$(echo "$WEATHER_JSON" | jq -r '.weather[0].description')
weather_main=$(echo "$WEATHER_JSON" | jq -r '.weather[0].main')

# 解析日出日落时间（转换为北京时间）
sunrise=$(TZ='Asia/Shanghai' date -d "@$(echo "$WEATHER_JSON" | jq -r '.sys.sunrise')" +"%H:%M")
sunset=$(TZ='Asia/Shanghai' date -d "@$(echo "$WEATHER_JSON" | jq -r '.sys.sunset')" +"%H:%M")

# 解析其他时间戳
dt=$(echo "$WEATHER_JSON" | jq -r '.dt')
update_time=$(TZ='Asia/Shanghai' date -d "@$dt" +"%Y-%m-%d %H:%M")

# 解析第一个预报点（未来0-3小时）
forecast=$(echo "$API_RESPONSE" | jq '.list[0]')

# 提取关键字段（添加默认值处理）
pop=$(echo "$forecast" | jq -r '.pop // 0')  # 如果pop字段不存在，默认0
dtt=$(echo "$forecast" | jq -r '.dt')
desc=$(echo "$forecast" | jq -r '.weather[0].description')

# 转换时间
start_time=$(TZ='Asia/Shanghai' date -d "@$dtt" +"%H:%M")
end_time=$(TZ='Asia/Shanghai' date -d "@$((dtt + 10800))" +"%H:%M")

# 计算降水概率百分比
pop_percent=$(awk -v pop="$pop" 'BEGIN {printf "%.0f%%", pop * 100}')

# 使用awk进行浮点数比较（替代bc）
advice=$(awk -v pop="$pop" 'BEGIN {
  if (pop > 0.7) print "⛈️ 大雨预警！尽量避免外出";
  else if (pop > 0.3) print "⚠️ 建议带伞";
  else print "✅ 可以放心出门";
}')


# 根据天气类型选择Emoji图标
case $weather_main in
    "Clear") weather_icon="☀️";;
    "Clouds") weather_icon="☁️";;
    "Rain") weather_icon="🌧️";;
    "Snow") weather_icon="❄️";;
    "Thunderstorm") weather_icon="⛈️";;
    *) weather_icon="🌤️";;
esac

# 构建消息模板
MESSAGE="<b>${weather_icon} 武汉天气实况</b>
━━━━━━━━━━━━━━━━━━━━━━━
☁️ 天气   <b>${weather_desc}</b>
🌡 温度   <b>${temp}°C</b> (体感 ${feels_like}°C)
💦 湿度   <b>${humidity}%</b>
💨 风速   <b>${wind_speed} m/s</b>
🎚️ 气压   <b>${pressure} hPa</b>
🌅 日出   <b>${sunrise}</b>
🌇 日落   <b>${sunset}</b>
<b>🌧️ 武汉未来3小时降水预报</b>
🕒 时段   : ${start_time} - ${end_time}
📝 天气   : ${desc}
💧 降水概率: <b>${pop_percent}</b>
💡 建议   : ${advice}
━━━━━━━━━━━━━━━━━━━━━━━
⏱ 更新于 <i>${update_time}</i>"

# 发送消息到Telegram
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d "chat_id=${CHAT_ID}" \
  -d "text=${MESSAGE}" \
  -d "parse_mode=HTML" \
  --output /dev/null