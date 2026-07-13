/** 字符串工具集合。 */
export function capitalize(input: string): string {
  if (input.length === 0) {
    return input
  }
  return input[0].toUpperCase() + input.slice(1)
}

export function truncate(input: string, max: number): string {
  return input.length > max ? `${input.slice(0, max)}…` : input
}

export function slugify(input: string): string {
  return input
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}
