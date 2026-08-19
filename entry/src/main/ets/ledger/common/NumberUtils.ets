import intl from '@ohos.intl';

export class NumberUtils {
  static formatAmount(amount: number): string {
    const formatter = new intl.NumberFormat('zh-CN', {
      style: 'currency',
      currency: 'CNY',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
    return formatter.format(amount);
  }

  static formatAmountWithSign(amount: number, isExpense: boolean): string {
    const formatter = new intl.NumberFormat('zh-CN', {
      style: 'currency',
      currency: 'CNY',
      signDisplay: 'always',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
    const signedAmount = isExpense ? -Math.abs(amount) : Math.abs(amount);
    return formatter.format(signedAmount);
  }

  static formatPercent(value: number): string {
    const formatter = new intl.NumberFormat('zh-CN', {
      style: 'percent',
      minimumFractionDigits: 1,
      maximumFractionDigits: 1
    });
    return formatter.format(value);
  }

  static formatSimpleAmount(amount: number): string {
    if (Math.abs(amount) >= 10000) {
      const compactFormatter = new intl.NumberFormat('zh-CN', {
        notation: 'compact',
        minimumFractionDigits: 1,
        maximumFractionDigits: 1
      });
      return compactFormatter.format(amount);
    }
    const decimalFormatter = new intl.NumberFormat('zh-CN', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
    return decimalFormatter.format(amount);
  }
}
