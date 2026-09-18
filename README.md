# user-auth-starter

**Signup, login, logout, password reset by e-mail and e-mail verification for a web page and a Flutter app, with no auth server of your own.** Six REST calls to a managed [Back4app](https://www.back4app.com/) backend do the whole account system; the code here is 91 lines of vanilla JavaScript, 58 lines of Dart and a 17-line backend rule.

Measured on September 17, 2026: signup in **597 ms**, login in **245 ms**, and the password-reset e-mail in the inbox **1 second** after the request. Every number in the article comes from this exact code.

> Read the article: *How to Add Signup, Login and Password Reset to an App Without Writing an Auth Server* — link added at publication.

## Why no auth server

Hashing passwords, minting and revoking session tokens, sending a reset e-mail with a one-time link, hosting the page where the new password is typed: a managed backend already does all of it, behind a users class and a REST API. Your app sends an App ID and a client key with each request and keeps one thing, the session token. No password hash, token secret or mail server ever touches your code.

| Call | What it does | Measured |
|---|---|---|
| `POST /users` | Creates the account, returns `sessionToken` | 201 · 597 ms |
| `POST /login` | Checks the password, returns a new token | 200 · 245 ms |
| `GET /users/me` | Validates the token, returns the user | 200 |
| `POST /requestPasswordReset` | Sends the reset e-mail with a hosted reset page | 200 · e-mail 1 s later |
| `POST /verificationEmailRequest` | Sends the verification e-mail (once enabled) | 200 |
| `POST /logout` | Revokes the calling token | 200 · next `GET /users/me` → 209 |

## What is in here

- `web/` — one HTML page and `app.js` (vanilla JavaScript, no framework, no SDK): the six calls above. The session token lives in `sessionStorage`.
- `flutter/` — the same six calls in Dart (`lib/auth_api.dart`, package `http`) behind a one-screen Flutter app (`lib/main.dart`), plus `test/auth_api_test.dart`, which runs the real flow against the real backend: sign up, check the session, log out, log back in, fail a wrong password.
- `cloud/main.js` — the backend rules, deployed as Cloud Code: `beforeSave` on `_User` (e-mail required and lower-cased, username of at least 3 characters) and a `whoami` Cloud Function that needs a session.
- `auth-check.sh` — the whole flow from `curl`, with timings and the error codes for a wrong password (101), a duplicate username (202), a duplicate e-mail (203) and a revoked token (209).

## Findings from the run

- `POST /logout` revokes one session, the one that called it. The token from signup still worked after we logged out the token from a later login. "Log out everywhere" is a Cloud Function that deletes the user's `_Session` rows with the master key.
- `POST /verificationEmailRequest` answers `200 {}` and sends nothing until verification is switched on under Notifications → Email → Verification, which needs a validated card on the account. Password-reset e-mails need nothing.
- Password policy and account lockout exist in the dashboard (App Settings → Advanced Options) but are read-only on the free plan, so the rules live in the `beforeSave` hook.
- On a fresh backend the first Cloud Code deploy ships nothing. Deploy twice and prove it with a request: `ab` as a username must fail with code 142.

## Deploy your own

1. **Create a free backend.** Sign up at [https://www.back4app.com/signup](https://www.back4app.com/signup), then **New App → Build your Backend**. The free plan is enough for everything in this repo.
2. On the app's **Overview** page copy the App ID and, from the Keys dropdown, the **JavaScript key** (web) or **Client key** (Flutter). These are client keys; shipping them in a page or an app is expected. The Master key in the same dropdown never leaves a server.
3. **Cloud Code → main.js**: paste `cloud/main.js` and click **Deploy**. Edit the file and deploy a second time (see the last finding above).
4. Put the keys in `web/config.js` and `flutter/lib/config.dart` (both git-ignored, examples provided) and run the clients below.
5. Optional: **Notifications → Email → Verification** to turn on verification e-mails, and App Settings → Advanced Options for password policy and lockout on a paid plan.

## Run it

```bash
cp web/config.example.js web/config.js          # App ID + JavaScript key
python3 -m http.server 8095 --directory web     # open http://127.0.0.1:8095/

cp flutter/lib/config.example.dart flutter/lib/config.dart   # App ID + Client key
cd flutter && flutter test                      # signs up, logs out, logs in, fails a wrong password — for real
flutter run -d chrome

APP_ID=… JS_KEY=… ./auth-check.sh example.com   # the whole flow from curl, with timings
```

## What the backend gives you

A managed Parse Server (7.5.2 at the time of writing) with a database, the REST and GraphQL APIs, Cloud Code for server-side rules, a dashboard with a Database Browser, and the users, sessions, roles and e-mail features this repo relies on. Documentation: [https://www.back4app.com/docs](https://www.back4app.com/docs) · user registration guide: [https://www.back4app.com/docs/get-started/user-registration](https://www.back4app.com/docs/get-started/user-registration).

Next step once accounts work: locking down what a logged-in user may read and write, in the companion repo [lockdown-lab](https://github.com/templates-back4app/lockdown-lab).

## License

MIT
