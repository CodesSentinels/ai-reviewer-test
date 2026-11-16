import type { Order } from "./types";

export interface FormatOptions {
  locale: string;
  showItems: boolean;
}

export function formatOrder(
  order: Order,
  options: FormatOptions,
): { text: string; total: number } {
  const total = order.items.reduce((sum, item) => sum + item.qty * item.price, 0);
  const text = `${order.id}: ${total.toLocaleString(options.locale)} ${order.currency}`;
  return { text, total };
}
