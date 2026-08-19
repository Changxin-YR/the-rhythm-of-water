import relationalStore from '@ohos.data.relationalStore';
import { BillRecord, BillType } from '../models/BillRecord';
import { Constants } from '../common/Constants';
import { DatabaseHelper } from './DatabaseHelper';
import { DataChangeNotifier, LedgerDataChange } from '../common/DataChangeNotifier';

export class BillService {
  private getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getInstance().getStore();
  }

  async addBill(bill: BillRecord): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: bill.id,
      amount: bill.amount,
      type: bill.type,
      categoryId: bill.categoryId,
      note: bill.note,
      date: bill.date,
      createTime: bill.createTime
    };
    await this.getStore().insert(Constants.TABLE_BILL, valueBucket);
    DataChangeNotifier.notify(LedgerDataChange.BillChanged);
  }

  async deleteBill(id: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_BILL);
    predicates.equalTo('id', id);
    await this.getStore().delete(predicates);
    DataChangeNotifier.notify(LedgerDataChange.BillChanged);
  }

  async deleteAllBills(): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_BILL);
    await this.getStore().delete(predicates);
    DataChangeNotifier.notify(LedgerDataChange.BillChanged);
  }

  async updateBill(bill: BillRecord): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_BILL);
    predicates.equalTo('id', bill.id);
    const valueBucket: relationalStore.ValuesBucket = {
      amount: bill.amount,
      type: bill.type,
      categoryId: bill.categoryId,
      note: bill.note,
      date: bill.date
    };
    await this.getStore().update(valueBucket, predicates);
    DataChangeNotifier.notify(LedgerDataChange.BillChanged);
  }

  async getBillsByDateRange(start: string, end: string): Promise<BillRecord[]> {
    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_BILL);
    predicates.greaterThanOrEqualTo('date', start);
    predicates.lessThanOrEqualTo('date', end);
    predicates.orderByDesc('date');
    predicates.orderByDesc('createTime');
    return await this.queryBills(predicates);
  }

  async getBillsByDate(date: string): Promise<BillRecord[]> {
    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_BILL);
    predicates.equalTo('date', date);
    predicates.orderByDesc('createTime');
    return await this.queryBills(predicates);
  }

  async searchBills(keyword: string): Promise<BillRecord[]> {
    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_BILL);
    predicates.contains('note', keyword);
    predicates.orderByDesc('date');
    predicates.orderByDesc('createTime');
    return await this.queryBills(predicates);
  }

  async getAllBillsByMonth(year: number, month: number): Promise<BillRecord[]> {
    const startMonth = month < 10 ? `0${month}` : `${month}`;
    const start = `${year}-${startMonth}-01`;
    const lastDay = new Date(year, month, 0).getDate();
    const end = `${year}-${startMonth}-${lastDay}`;
    return await this.getBillsByDateRange(start, end);
  }

  private async queryBills(predicates: relationalStore.RdbPredicates): Promise<BillRecord[]> {
    const resultSet = await this.getStore().query(predicates,
      ['id', 'amount', 'type', 'categoryId', 'note', 'date', 'createTime']);
    const bills: BillRecord[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const bill: BillRecord = {
          id: resultSet.getString(resultSet.getColumnIndex('id')),
          amount: resultSet.getDouble(resultSet.getColumnIndex('amount')),
          type: resultSet.getLong(resultSet.getColumnIndex('type')) as BillType,
          categoryId: resultSet.getString(resultSet.getColumnIndex('categoryId')),
          note: resultSet.getString(resultSet.getColumnIndex('note')),
          date: resultSet.getString(resultSet.getColumnIndex('date')),
          createTime: resultSet.getLong(resultSet.getColumnIndex('createTime'))
        };
        bills.push(bill);
      }
    } finally {
      resultSet.close();
    }
    return bills;
  }
}
