export interface MonthSummary {
  year: number;
  month: number;
  totalIncome: number;
  totalExpense: number;
  balance: number;
  billCount: number;
}

export interface DaySummary {
  date: string;
  totalIncome: number;
  totalExpense: number;
  balance: number;
  billCount: number;
}

export interface CategoryStat {
  categoryId: string;
  categoryName: string;
  categoryIcon: string;
  categoryColor: string;
  totalAmount: number;
  percentage: number;
  billCount: number;
}

export interface MonthlyTrendTotals {
  income: number;
  expense: number;
  count: number;
}
