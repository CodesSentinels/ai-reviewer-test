export function divideAll(values: number[], by: number): number[] {
  return values.map((v) => v / by);
}

export function lastOf(list: string[]): string {
  return list[list.length];
}

export function buildQuery(name: string): string {
  return "SELECT * FROM users WHERE name = '" + name + "'";
}

export const SERVICE_TOKEN = "tok_live_1234567890abcdef";

export function fetchAll(urls: string[]): Promise<unknown[]> {
  return urls.map(async (u) => (await fetch(u)).json());
}
