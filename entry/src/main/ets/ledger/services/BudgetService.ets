import { StatisticsService } from './StatisticsService';
import relationalStore from '@ohos.data.relationalStore';
import { Constants } from '../common/Constants';
import { DatabaseHelper } from './DatabaseHelper';

export interface BudgetProgress {
  budget: number;
  spent: number;
  remaining: number;
  percent: number;
}

export class BudgetService {
  private statisticsService: StatisticsService = new StatisticsService();

  private getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getInstance().getStore();
  }

  async setBudget(context: Context, year: number, month: number, amount: number): Promise<void> {
    const existing = await this.queryBudget(year, month);
    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_BUDGET);
    predicates.equalTo('year', year).and().equalTo('month', month);
    if (existing === null) {
      await this.getStore().insert(Constants.TABLE_BUDGET, { year: year, month: month, amount: amount });
    } else {
      await this.getStore().update({ amount: amount }, predicates);
    }
  }

  async getBudget(context: Context, year: number, month: number): Promise<number> {
    const amount = await this.queryBudget(year, month);
    return amount === null ? 0 : amount;
  }

  async getBudgetProgress(context: Context, year: number, month: number): Promise<BudgetProgress> {
    const budget = await this.getBudget(context, year, month);
    const summary = await this.statisticsService.getMonthSummary(year, month);
    const spent = summary.totalExpense;
    const remaining = budget - spent;
    const percent = budget > 0 ? spent / budget : 0;

    return {
      budget: budget,
      spent: spent,
      remaining: remaining,
      percent: percent
    };
  }

  private async queryBudget(year: number, month: number): Promise<number | null> {
    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_BUDGET);
    predicates.equalTo('year', year).and().equalTo('month', month);
    const resultSet = await this.getStore().query(predicates, ['amount']);
    try {
      if (!resultSet.goToNextRow()) {
        return null;
      }
      return resultSet.getDouble(resultSet.getColumnIndex('amount'));
    } finally {
      resultSet.close();
    }
  }
}
