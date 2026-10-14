import { formatOrder } from "~/functional-tests/ai-reviewer-fixtures/workspace/shared/formatter";
import type { Order } from "~/functional-tests/ai-reviewer-fixtures/workspace/shared/types";

export function receiptLine(order: Order): string {
  return `Receipt -> ${formatOrder(order)}`;
}
