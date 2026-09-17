#!/usr/bin/env bash
# Stack: bash + curl | File: auth-check.sh
# Walks the whole auth flow against a backend: signup → login → me → wrong password → duplicate → reset request → logout → me again.
# usage: APP_ID=… JS_KEY=… ./auth-check.sh [email-domain]
set -euo pipefail
BASE="${BASE:-https://parseapi.back4app.com}"; DOMAIN="${1:-example.com}"
H=(-H "X-Parse-Application-Id: $APP_ID" -H "X-Parse-JavaScript-Key: $JS_KEY" -H "X-Parse-Revocable-Session: 1" -H "Content-Type: application/json")
U="user$RANDOM"; E="$U@$DOMAIN"; P="correct-horse-$RANDOM"
ms() { python3 -c 'import time; print(int(time.time()*1000))'; }
step() { printf '%-28s' "$1"; }

step "1 signup";      T0=$(ms); R=$(curl -s -w '\n%{http_code}' "${H[@]}" -X POST "$BASE/users" -d "{\"username\":\"$U\",\"email\":\"$E\",\"password\":\"$P\"}"); echo "$(tail -1 <<<"$R")  $(( $(ms) - T0 )) ms"
TOKEN=$(head -1 <<<"$R" | python3 -c 'import json,sys; print(json.load(sys.stdin)["sessionToken"])')
step "2 me (session token)";  T0=$(ms); curl -s -o /dev/null -w '%{http_code}' "${H[@]}" -H "X-Parse-Session-Token: $TOKEN" "$BASE/users/me"; echo "  $(( $(ms) - T0 )) ms"
step "3 login";       T0=$(ms); R=$(curl -s -w '\n%{http_code}' "${H[@]}" -X POST "$BASE/login" -d "{\"username\":\"$U\",\"password\":\"$P\"}"); echo "$(tail -1 <<<"$R")  $(( $(ms) - T0 )) ms"
TOKEN2=$(head -1 <<<"$R" | python3 -c 'import json,sys; print(json.load(sys.stdin)["sessionToken"])')
step "4 wrong password";      curl -s -w '\n' "${H[@]}" -X POST "$BASE/login" -d "{\"username\":\"$U\",\"password\":\"nope\"}"
step "5 duplicate username";  curl -s -w '\n' "${H[@]}" -X POST "$BASE/users" -d "{\"username\":\"$U\",\"email\":\"other-$E\",\"password\":\"$P\"}"
step "6 duplicate e-mail";    curl -s -w '\n' "${H[@]}" -X POST "$BASE/users" -d "{\"username\":\"other-$U\",\"email\":\"$E\",\"password\":\"$P\"}"
step "7 reset request";       curl -s -w '\n' "${H[@]}" -X POST "$BASE/requestPasswordReset" -d "{\"email\":\"$E\"}"
step "8 logout";              curl -s -o /dev/null -w '%{http_code}\n' "${H[@]}" -H "X-Parse-Session-Token: $TOKEN2" -X POST "$BASE/logout"
step "9 me after logout";     curl -s -w '\n' "${H[@]}" -H "X-Parse-Session-Token: $TOKEN2" "$BASE/users/me"
step "10 first token still ok"; curl -s -o /dev/null -w '%{http_code}\n' "${H[@]}" -H "X-Parse-Session-Token: $TOKEN" "$BASE/users/me"
echo "user: $U  ($E)"
