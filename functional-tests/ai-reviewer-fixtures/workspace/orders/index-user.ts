import { formatOrder } from "../shared";
import type { Order } from "../shared";

export function exportRow(order: Order): string[] {
  return [order.id, formatOrder(order)];
}
