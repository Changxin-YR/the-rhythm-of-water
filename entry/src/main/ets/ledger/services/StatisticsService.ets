import { BillType } from '../models/BillRecord';
import { MonthSummary, DaySummary, CategoryStat, MonthlyTrendTotals } from '../models/Statistics';
import { Constants } from '../common/Constants';
import { DatabaseHelper } from './DatabaseHelper';
import { DateUtils } from '../common/DateUtils';
import relationalStore from '@ohos.data.relationalStore';

export class StatisticsService {
  private getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getInstance().getStore();
  }

  private async getBillCountInRange(start: string, end: string): Promise<number> {
    const resultSet = await this.getStore().querySql(
      `SELECT id FROM ${Constants.TABLE_BILL} WHERE date >= ? AND date <= ?`,
      [start, end]
    );
    let billCount = 0;
    try {
      while (resultSet.goToNextRow()) {
        billCount++;
      }
    } finally {
      resultSet.close();
    }
    return billCount;
  }

  async getMonthSummary(year: number, month: number): Promise<MonthSummary> {
    const monthStr = month < 10 ? `0${month}` : `${month}`;
    const start = `${year}-${monthStr}-01`;
    const lastDay = new Date(year, month, 0).getDate();
    const end = `${year}-${monthStr}-${lastDay}`;

    const sql = `SELECT type, SUM(amount) as total
      FROM ${Constants.TABLE_BILL}
      WHERE date >= ? AND date <= ?
      GROUP BY type`;

    const billCount = await this.getBillCountInRange(start, end);
    const resultSet = await this.getStore().querySql(sql, [start, end]);
    let totalIncome = 0;
    let totalExpense = 0;

    try {
      while (resultSet.goToNextRow()) {
        const type = resultSet.getLong(resultSet.getColumnIndex('type'));
        const total = resultSet.getDouble(resultSet.getColumnIndex('total'));
        if (type === BillType.INCOME) {
          totalIncome = total;
        } else {
          totalExpense = total;
        }
      }
    } finally {
      resultSet.close();
    }

    return {
      year: year,
      month: month,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      billCount: billCount
    };
  }

  async getDaySummary(date: string): Promise<DaySummary> {
    const sql = `SELECT type, SUM(amount) as total
      FROM ${Constants.TABLE_BILL}
      WHERE date = ?
      GROUP BY type`;

    const billCount = await this.getBillCountInRange(date, date);
    const resultSet = await this.getStore().querySql(sql, [date]);
    let totalIncome = 0;
    let totalExpense = 0;

    try {
      while (resultSet.goToNextRow()) {
        const type = resultSet.getLong(resultSet.getColumnIndex('type'));
        const total = resultSet.getDouble(resultSet.getColumnIndex('total'));
        if (type === BillType.INCOME) {
          totalIncome = total;
        } else {
          totalExpense = total;
        }
      }
    } finally {
      resultSet.close();
    }

    return {
      date: date,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      billCount: billCount
    };
  }

  async getCategoryStats(year: number, month: number, type: BillType): Promise<CategoryStat[]> {
    const monthStr = month < 10 ? `0${month}` : `${month}`;
    const start = `${year}-${monthStr}-01`;
    const lastDay = new Date(year, month, 0).getDate();
    const end = `${year}-${monthStr}-${lastDay}`;

    const fallbackId = type === BillType.EXPENSE ? 'exp_other' : 'inc_other';
    const sql = `SELECT b.categoryId,
      COALESCE(c.name, fallback.name, '') as categoryName,
      COALESCE(c.icon, fallback.icon, '') as categoryIcon,
      COALESCE(c.color, fallback.color, '') as categoryColor,
      SUM(b.amount) as totalAmount, COUNT(*) as billCount
      FROM ${Constants.TABLE_BILL} b
      LEFT JOIN ${Constants.TABLE_CATEGORY} c ON b.categoryId = c.id
      LEFT JOIN ${Constants.TABLE_CATEGORY} fallback ON fallback.id = ?
      WHERE b.date >= ? AND b.date <= ? AND b.type = ?
      GROUP BY b.categoryId
      ORDER BY totalAmount DESC`;

    const resultSet = await this.getStore().querySql(sql, [fallbackId, start, end, type]);
    const stats: CategoryStat[] = [];
    let grandTotal = 0;

    try {
      while (resultSet.goToNextRow()) {
        const totalAmount = resultSet.getDouble(resultSet.getColumnIndex('totalAmount'));
        grandTotal += totalAmount;
        stats.push({
          categoryId: resultSet.getString(resultSet.getColumnIndex('categoryId')),
          categoryName: resultSet.getString(resultSet.getColumnIndex('categoryName')) || '',
          categoryIcon: resultSet.getString(resultSet.getColumnIndex('categoryIcon')) || '',
          categoryColor: resultSet.getString(resultSet.getColumnIndex('categoryColor')) || '',
          totalAmount: totalAmount,
          percentage: 0,
          billCount: resultSet.getLong(resultSet.getColumnIndex('billCount'))
        });
      }
    } finally {
      resultSet.close();
    }

    if (grandTotal > 0) {
      for (const stat of stats) {
        stat.percentage = stat.totalAmount / grandTotal;
      }
    }

    return stats;
  }

  async getDailyTrend(year: number, month: number): Promise<DaySummary[]> {
    const monthStr = month < 10 ? `0${month}` : `${month}`;
    const start = `${year}-${monthStr}-01`;
    const lastDay = new Date(year, month, 0).getDate();
    const end = `${year}-${monthStr}-${lastDay}`;
    const sql = `SELECT date, type, SUM(amount) as total, COUNT(*) as cnt
      FROM ${Constants.TABLE_BILL}
      WHERE date >= ? AND date <= ?
      GROUP BY date, type
      ORDER BY date`;
    const resultSet = await this.getStore().querySql(sql, [start, end]);
    const dayMap = new Map<string, MonthlyTrendTotals>();

    try {
      while (resultSet.goToNextRow()) {
        const date = resultSet.getString(resultSet.getColumnIndex('date'));
        const type = resultSet.getLong(resultSet.getColumnIndex('type')) as BillType;
        const total = resultSet.getDouble(resultSet.getColumnIndex('total'));
        const count = resultSet.getLong(resultSet.getColumnIndex('cnt'));
        const totals: MonthlyTrendTotals = dayMap.get(date) || { income: 0, expense: 0, count: 0 };
        if (type === BillType.INCOME) {
          totals.income = total;
        } else {
          totals.expense = total;
        }
        totals.count += count;
        dayMap.set(date, totals);
      }
    } finally {
      resultSet.close();
    }

    const days: DaySummary[] = [];
    const dates = Array.from(dayMap.keys()).sort((left: string, right: string) => left.localeCompare(right));
    for (const date of dates) {
      const totals = dayMap.get(date);
      if (!totals) {
        continue;
      }
      days.push({
        date: date,
        totalIncome: totals.income,
        totalExpense: totals.expense,
        balance: totals.income - totals.expense,
        billCount: totals.count
      });
    }
    return days;
  }

  async getMonthlyTrend(year: number): Promise<MonthSummary[]> {
    const start = `${year}-01-01`;
    const end = `${year}-12-31`;

    const sql = `SELECT SUBSTR(date, 6, 2) as m, type, SUM(amount) as total, COUNT(*) as cnt
      FROM ${Constants.TABLE_BILL}
      WHERE date >= ? AND date <= ?
      GROUP BY m, type
      ORDER BY m`;

    const resultSet = await this.getStore().querySql(sql, [start, end]);
    const monthMap = new Map<number, MonthlyTrendTotals>();

    try {
      while (resultSet.goToNextRow()) {
        const m = parseInt(resultSet.getString(resultSet.getColumnIndex('m')));
        const type = resultSet.getLong(resultSet.getColumnIndex('type'));
        const total = resultSet.getDouble(resultSet.getColumnIndex('total'));
        const cnt = resultSet.getLong(resultSet.getColumnIndex('cnt'));

        const existing: MonthlyTrendTotals = monthMap.get(m) || { income: 0, expense: 0, count: 0 };
        if (type === BillType.INCOME) {
          existing.income = total;
        } else {
          existing.expense = total;
        }
        existing.count += cnt;
        monthMap.set(m, existing);
      }
    } finally {
      resultSet.close();
    }

    const currentMonth = year === DateUtils.getCurrentYear() ? DateUtils.getCurrentMonth() : 12;
    const trends: MonthSummary[] = [];

    for (let month = 1; month <= currentMonth; month++) {
      const data: MonthlyTrendTotals = monthMap.get(month) || { income: 0, expense: 0, count: 0 };
      trends.push({
        year: year,
        month: month,
        totalIncome: data.income,
        totalExpense: data.expense,
        balance: data.income - data.expense,
        billCount: data.count
      });
    }

    return trends;
  }
}
