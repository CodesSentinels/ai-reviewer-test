export interface OrderItem {
  sku: string;
  qty: number;
  price: number;
}

export interface Order {
  id: string;
  items: OrderItem[];
  currency: string;
}
