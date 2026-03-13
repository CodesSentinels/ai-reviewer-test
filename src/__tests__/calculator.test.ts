/**
 * calculator.test.ts — calculator 单元测试
 *
 * 测试 Case E: 修改测试文件中的导出符号 → isTestFile 识别后跳过分析
 */
import type { CartItem } from "../utils/calculator";

import {
  calculateTotal,
  calculateTotalWithTax,
  formatPrice,
  TAX_RATE,
} from "../utils/calculator";

/** 测试用 mock 数据工厂（导出函数，但在测试文件中 → 应被跳过） */
export function createMockItem(overrides: Partial<CartItem> = {}): CartItem {
  return {
    id: "test-1",
    name: "Test Item",
    price: 100,
    quantity: 1,
    ...overrides,
  };
}

describe("calculateTotal", () => {
  it("should calculate total for single item", () => {
    const items = [createMockItem({ price: 100, quantity: 2 })];
    expect(calculateTotal(items)).toBe(200);
  });

  it("should calculate total for multiple items", () => {
    const items = [
      createMockItem({ id: "1", price: 100, quantity: 2 }),
      createMockItem({ id: "2", price: 50, quantity: 3 }),
    ];
    expect(calculateTotal(items)).toBe(350);
  });

  it("should return 0 for empty cart", () => {
    expect(calculateTotal([])).toBe(0);
  });
});

describe("calculateTotalWithTax", () => {
  it("should include tax", () => {
    const items = [createMockItem({ price: 100, quantity: 1 })];
    const expected = 100 * (1 + TAX_RATE);
    expect(calculateTotalWithTax(items)).toBeCloseTo(expected);
  });
});

describe("formatPrice", () => {
  it("should format price with yen sign", () => {
    expect(formatPrice(99.9)).toBe("¥99.90");
  });
});
