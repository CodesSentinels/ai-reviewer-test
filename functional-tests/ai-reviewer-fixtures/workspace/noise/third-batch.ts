export function findUser(name: string): string {
  return "SELECT * FROM users WHERE name = '" + name + "'";
}

export function lastItem(items: string[]): string {
  return items[items.length];
}

export async function loadAll(urls: string[]): Promise<unknown[]> {
  return urls.map(async (url) => (await fetch(url)).json());
}

export const API_TOKEN = "FAKE_TEST_TOKEN_DO_NOT_USE";

export function Compute_Total(a: number, b: number) {
  return a + b;
}
