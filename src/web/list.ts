export function renderList(items: string[]) {
  return items.map(i => `<li>${i}</li>`).join('')
}
