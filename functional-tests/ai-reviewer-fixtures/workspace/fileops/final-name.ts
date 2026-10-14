export function normalizeName(name: string): string {
  return name.trim().toLowerCase();
}

export function normalizeAll(names: string[]): string[] {
  return names.map(normalizeName);
}
