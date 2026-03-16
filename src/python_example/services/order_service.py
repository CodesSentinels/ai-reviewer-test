# order_service.py — Python 订单服务
#
# 测试 Case O: Python 点式相对导入
# from ..utils.calculator import calculate_total  → 解析为 ../utils/calculator
# from ..utils import format_price                → 解析为 ../utils → __init__.py
#
# 使用符号别名：from ..utils.calculator import calculate_total as calc_total

from ..utils.calculator import calculate_total as calc_total, calculate_tax
from ..utils.formatter import format_price


def create_order(items):
    """创建订单 — 使用点式相对导入 + 符号别名"""
    subtotal = calc_total(items)
    tax = calculate_tax(subtotal)
    total = subtotal + tax

    return {
        "items": items,
        "subtotal": format_price(subtotal),
        "tax": format_price(tax),
        "total": format_price(total),
    }


def get_order_summary(orders):
    """订单汇总 — 多次使用别名 calc_total"""
    total_revenue = sum(calc_total(order["items"]) for order in orders)
    return {
        "order_count": len(orders),
        "total_revenue": format_price(total_revenue),
    }
