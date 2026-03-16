# calculator.py — Python 价格计算工具
#
# 测试 Case O: Python 跨文件依赖分析
# 修改 calculate_total 的签名后，消费者文件应被检测到

TAX_RATE = 0.08


def calculate_total(items):
    """计算购物车总价"""
    return sum(item["price"] * item["quantity"] for item in items)


# Case O: 修改后的版本
# def calculate_total(items, coupon=None):
#     """计算购物车总价（支持优惠券）"""
#     subtotal = sum(item["price"] * item["quantity"] for item in items)
#     if coupon:
#         return subtotal * (1 - coupon["discount"])
#     return subtotal


def calculate_tax(amount):
    """计算税额"""
    return amount * TAX_RATE


def _internal_round(value, decimals=2):
    """内部辅助函数（下划线开头，不导出）"""
    factor = 10 ** decimals
    return round(value * factor) / factor
