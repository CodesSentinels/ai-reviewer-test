export async function updateUser(req: any, db: any) {
  const id = req.body.id
  const sql = "UPDATE users SET name = '" + req.body.name + "' WHERE id = " + id
  return db.query(sql)
}
