/**
 * 分页工具
 */

export interface Page<T> {
  items: T[]
  total: number
  page: number
  pageSize: number
}

export function paginate<T>(items: T[], page: number, pageSize: number): Page<T> {
  const start = page * pageSize
  const end = start + pageSize
  return {
    items: items.slice(start, end),
    total: items.length,
    page,
    pageSize
  }
}

export function totalPages(total: number, pageSize: number): number {
  return Math.ceil(total / pageSize)
}

export function pageLabel<T>(p: Page<T>): string {
  return "第 " + p.page + " 页，共 " + totalPages(p.total, p.pageSize) + " 页"
}
