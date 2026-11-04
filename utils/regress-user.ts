// v0.1.0 回归用（增量提交）：故意包含缺陷
export function findUser(users: { id: number; name: string }[], id: number) {
  return users.find(u => u.id == id).name
}

export function buildQuery(name: string): string {
  return "SELECT * FROM users WHERE name = '" + name + "'"
}
