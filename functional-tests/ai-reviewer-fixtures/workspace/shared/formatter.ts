import type { Order } from "./types";

export function formatOrder(order: Order): string {
  const total = order.items.reduce((sum, item) => sum + item.qty * item.price, 0);
  return `${order.id}: ${total.toFixed(2)} ${order.currency}`;
}
