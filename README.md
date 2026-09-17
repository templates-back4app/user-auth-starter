# user-auth-starter

**Signup, login, e-mail verification, password reset and logout for a web page and a Flutter app, with no auth server of your own: six REST calls to a managed Back4app backend.**

Companion repository for the Back4app blog post *How to Add Signup, Login and Password Reset to an App Without Writing an Auth Server*. Everything in the post was measured on this code on September 17, 2026.

> Article: link added at publication.

## What is in here

- `web/` — one HTML page and `app.js` (vanilla JavaScript): `POST /users`, `POST /login`, `GET /users/me`, `POST /requestPasswordReset`, `POST /verificationEmailRequest`, `POST /logout`. The session token lives in `sessionStorage`.
- `flutter/` — the same six calls in Dart (`lib/auth_api.dart`, package `http`, no SDK) behind a one-screen Flutter app (`lib/main.dart`), plus `test/auth_api_test.dart`, which runs the real flow against the real backend.
- `cloud/main.js` — the backend rules: `beforeSave` on `_User` (e-mail required and lower-cased, username ≥ 3 characters) and a `whoami` Cloud Function that needs a session.
- `auth-check.sh` — the whole flow from `curl`, with timings and the error codes for wrong password, duplicate username and duplicate e-mail.

## Run it

```bash
cp web/config.example.js web/config.js          # App ID + JavaScript key from the backend's Overview page
python3 -m http.server 8095 --directory web     # open http://127.0.0.1:8095/

cp flutter/lib/config.example.dart flutter/lib/config.dart   # App ID + Client key
cd flutter && flutter test                      # signs up, logs out, logs in, fails a wrong password — for real
flutter run -d chrome

APP_ID=… JS_KEY=… ./auth-check.sh example.com
```

## Deploy the backend half

1. Back4app → New App → Build your Backend. Copy the App ID and the JavaScript key (web) or Client key (Flutter) from Overview.
2. Cloud Code → `main.js` → paste `cloud/main.js` → Deploy. On a fresh backend the first Deploy ships nothing: edit the file and deploy again, then prove it with a request (`ab` as username must fail with code 142).
3. Password-reset e-mails work out of the box. Verification e-mails are switched on under Notifications → Email → Verification and need a validated card on the account.

## License

MIT
