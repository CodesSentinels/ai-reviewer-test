export interface Line {
  sku: string;
  total: number;
}

export function uniqueSkus(lines: Line[]): string[] {
  const result: string[] = [];
  for (const line of lines) {
    if (!result.includes(line.sku)) {
      result.push(line.sku);
    }
  }
  return result;
}

export function totalsBySku(lines: Line[]): Record<string, number> {
  const totals: Record<string, number> = {};
  for (const sku of uniqueSkus(lines)) {
    totals[sku] = lines
      .filter((line) => line.sku === sku)
      .reduce((sum, line) => sum + line.total, 0);
  }
  return totals;
}

export function sortedCopies(lines: Line[]): Line[][] {
  const copies: Line[][] = [];
  for (let i = 0; i < lines.length; i++) {
    copies.push([...lines].sort((a, b) => a.total - b.total));
  }
  return copies;
}
