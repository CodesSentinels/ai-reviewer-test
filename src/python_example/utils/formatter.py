# formatter.py — Python 格式化工具

def format_price(amount):
    """格式化价格"""
    return f"¥{amount:.2f}"


def format_percent(value):
    """格式化百分比"""
    return f"{value * 100:.0f}%"
