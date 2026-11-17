#!/bin/bash
set -e
: "${GITHUB_TOKEN:?需要 GITHUB_TOKEN 环境变量}"
GH_USER="${GH_USER:-haodongdong}"
REPO="zuowen"
API="https://api.github.com"
AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28")

echo "① 验证 token…"
curl -sf "${AUTH[@]}" "$API/user" -o /tmp/gh_user.json
LOGIN=$(/usr/bin/python3 -c "import json;print(json.load(open('/tmp/gh_user.json'))['login'])")
echo "   ✓ 登录为 $LOGIN"

echo "② 创建仓库 $REPO…"
CODE=$(curl -s -o /tmp/gh_new.json -w "%{http_code}" -X POST "${AUTH[@]}" "$API/user/repos" \
  -d "{\"name\":\"$REPO\",\"description\":\"考研英语作文模板复习 App\",\"private\":false,\"auto_init\":false}")
if [ "$CODE" = "201" ]; then echo "   ✓ 已创建";
elif [ "$CODE" = "422" ]; then echo "   · 仓库已存在，继续";
else echo "   ✗ 失败 HTTP $CODE"; cat /tmp/gh_new.json; exit 1; fi

echo "③ 推送文件…"
git remote remove origin 2>/dev/null || true
git remote add origin "https://${GITHUB_TOKEN}@github.com/${GH_USER}/${REPO}.git"
git add -A
git -c user.name="$GH_USER" -c user.email="${GH_USER}@users.noreply.github.com" commit -qm "作文复习 App" 2>/dev/null || true
git branch -M main
git push -f -q origin main
echo "   ✓ 已推送"

echo "④ 开启 GitHub Pages…"
CODE=$(curl -s -o /tmp/gh_pages.json -w "%{http_code}" -X POST "${AUTH[@]}" "$API/repos/${GH_USER}/${REPO}/pages" \
  -d '{"source":{"branch":"main","path":"/"}}')
if [ "$CODE" = "201" ]; then echo "   ✓ Pages 已开启";
elif [ "$CODE" = "409" ]; then echo "   · Pages 已存在，改为更新";
  curl -s -o /dev/null -X PUT "${AUTH[@]}" "$API/repos/${GH_USER}/${REPO}/pages" -d '{"source":{"branch":"main","path":"/"}}';
else echo "   ✗ 失败 HTTP $CODE"; cat /tmp/gh_pages.json; fi

echo "⑤ 等待构建…"
for i in $(seq 1 40); do
  sleep 6
  ST=$(curl -s "${AUTH[@]}" "$API/repos/${GH_USER}/${REPO}/pages" | /usr/bin/python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('status','?'), d.get('html_url',''))" 2>/dev/null || echo "? -")
  echo "   [$i] $ST"
  case "$ST" in built*) break;; esac
done

echo "⑥ 验证网址…"
URL="https://${GH_USER}.github.io/${REPO}/"
for i in $(seq 1 20); do
  C=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "$URL" || echo 000)
  echo "   [$i] HTTP $C  $URL"
  [ "$C" = "200" ] && break
  sleep 6
done
echo
echo "完成：$URL"
