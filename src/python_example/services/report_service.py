# report_service.py — Python 报表服务
#
# 测试 Case O: Python 点式相对导入（from .. import）
# from ..utils import calculate_total  → 通过 __init__.py 间接导入

from ..utils import calculate_total, format_price, format_percent
from ..utils.calculator import TAX_RATE


def generate_daily_report(items, date_str):
    """生成日报 — 通过 __init__.py 间接导入 calculate_total"""
    subtotal = calculate_total(items)
    tax = subtotal * TAX_RATE
    total = subtotal + tax

    return {
        "date": date_str,
        "item_count": len(items),
        "subtotal": format_price(subtotal),
        "tax_rate": format_percent(TAX_RATE),
        "tax": format_price(tax),
        "total": format_price(total),
    }
