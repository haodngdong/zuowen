#!/bin/bash
# 网络恢复后自动推送到 GitHub
cd "$HOME/Desktop/作文复习-发布" || exit 1
for i in $(seq 1 120); do
  C=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 https://api.github.com/ 2>/dev/null)
  if [ "$C" = "200" ]; then
    echo "[$(date +%H:%M:%S)] GitHub 恢复，开始推送…"
    if git push -q origin main 2>/dev/null; then
      echo "[$(date +%H:%M:%S)] ✓ 推送成功"
      exit 0
    else
      echo "[$(date +%H:%M:%S)] 推送失败，继续等"
    fi
  fi
  sleep 30
done
echo "超时放弃"
