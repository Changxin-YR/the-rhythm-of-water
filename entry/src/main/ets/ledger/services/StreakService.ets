import { DateUtils } from '../common/DateUtils';
import relationalStore from '@ohos.data.relationalStore';
import { Constants } from '../common/Constants';
import { DatabaseHelper } from './DatabaseHelper';

export interface StreakInfo {
  currentStreak: number;
  longestStreak: number;
  totalDays: number;
  lastRecordDate: string;
}

export class StreakService {
  private getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getInstance().getStore();
  }

  async getStreakInfo(context: Context): Promise<StreakInfo> {
    const recordDates = await this.getRecordDates();
    return this.calculateStreakInfo(recordDates);
  }

  async recordToday(context: Context): Promise<StreakInfo> {
    return await this.getStreakInfo(context);
  }

  private async getRecordDates(): Promise<string[]> {
    const resultSet = await this.getStore().querySql(
      `SELECT DISTINCT date FROM ${Constants.TABLE_BILL} ORDER BY date DESC`
    );
    const recordDates: string[] = [];
    try {
      while (resultSet.goToNextRow()) {
        recordDates.push(resultSet.getString(resultSet.getColumnIndex('date')));
      }
    } finally {
      resultSet.close();
    }
    return recordDates;
  }

  private calculateStreakInfo(recordDates: string[]): StreakInfo {
    if (recordDates.length === 0) {
      return { currentStreak: 0, longestStreak: 0, totalDays: 0, lastRecordDate: '' };
    }

    const recordedDateSet = new Set<string>(recordDates);
    let currentStreak = 0;
    let currentDate = DateUtils.getToday();
    while (recordedDateSet.has(currentDate)) {
      currentStreak++;
      currentDate = this.getYesterday(currentDate);
    }

    const orderedDates = recordDates.slice().sort((left: string, right: string) => left.localeCompare(right));
    let longestStreak = 1;
    let consecutiveDays = 1;
    for (let index = 1; index < orderedDates.length; index++) {
      if (this.getYesterday(orderedDates[index]) === orderedDates[index - 1]) {
        consecutiveDays++;
      } else {
        consecutiveDays = 1;
      }
      if (consecutiveDays > longestStreak) {
        longestStreak = consecutiveDays;
      }
    }

    return {
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalDays: recordDates.length,
      lastRecordDate: recordDates[0]
    };
  }

  async clearStreak(context: Context): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_STREAK);
    predicates.equalTo('id', 1);
    await this.getStore().update({
      currentStreak: 0,
      longestStreak: 0,
      totalDays: 0,
      lastRecordDate: ''
    }, predicates);
  }

  private getYesterday(dateStr: string): string {
    const date = new Date(dateStr);
    date.setDate(date.getDate() - 1);
    return DateUtils.formatDate(date);
  }
}
