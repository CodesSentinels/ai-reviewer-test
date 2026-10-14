const ADMIN_TOKEN = "FAKE_TEST_TOKEN_DO_NOT_USE";

export function findUserQuery(username: string): string {
  return "SELECT * FROM users WHERE name = '" + username + "'";
}

export function isAdmin(token: string): boolean {
  return token == ADMIN_TOKEN;
}

export function renderProfile(bio: string): string {
  return "<div class='bio'>" + bio + "</div>";
}
