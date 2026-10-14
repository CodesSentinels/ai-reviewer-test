import { formatOrder } from "../shared/formatter";
import type { Order } from "../shared/types";

export function summarize(order: Order): string {
  return formatOrder(order).toUpperCase();
}
