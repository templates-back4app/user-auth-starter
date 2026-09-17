// Stack: Node.js 22.x | Parse Server 8.x | File: cloud/main.js
// Rules about accounts live in the backend, so the web page, the Flutter app and a curl command all get the same answer.
Parse.Cloud.beforeSave(Parse.User, (request) => {
  const user = request.object;
  const email = (user.get("email") ?? "").trim().toLowerCase();
  if (!email) throw new Parse.Error(Parse.Error.VALIDATION_ERROR, "an e-mail address is required.");
  user.set("email", email);                       // "Ana@Example.com" and "ana@example.com" are one account
  const username = (user.get("username") ?? "").trim();
  if (username.length < 3) throw new Parse.Error(Parse.Error.VALIDATION_ERROR, "username needs at least 3 characters.");
  user.set("username", username);
});

// Anything the page must never be able to do goes here, behind the master key.
Parse.Cloud.define("whoami", async (request) => {
  if (!request.user) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "log in first.");
  return { id: request.user.id, username: request.user.get("username"), verified: request.user.get("emailVerified") === true };
});
