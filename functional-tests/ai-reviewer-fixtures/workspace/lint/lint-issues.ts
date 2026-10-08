export function lintTarget(items: string[], flag: any) {
  const unused = 42;
  console.log("debug", items);
  if (flag == null) {
    return [];
  }
  items.map((item) => {
    if (item) {
      return item.trim();
    }
  });
  return items;
}
