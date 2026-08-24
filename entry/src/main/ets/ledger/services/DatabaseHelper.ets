import relationalStore from '@ohos.data.relationalStore';
import { Constants } from '../common/Constants';
import { BillType } from '../models/BillRecord';
import { BillRecord } from '../models/BillRecord';
import { Category } from '../models/Category';
import { DataChangeNotifier, LedgerDataChange } from '../common/DataChangeNotifier';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: Constants.DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
};

const CREATE_BILL_TABLE = `CREATE TABLE IF NOT EXISTS ${Constants.TABLE_BILL} (
  id TEXT PRIMARY KEY,
  amount REAL NOT NULL,
  type INTEGER NOT NULL,
  categoryId TEXT NOT NULL,
  note TEXT,
  date TEXT NOT NULL,
  createTime INTEGER NOT NULL
)`;

const CREATE_CATEGORY_TABLE = `CREATE TABLE IF NOT EXISTS ${Constants.TABLE_CATEGORY} (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  type INTEGER NOT NULL,
  isCustom INTEGER NOT NULL DEFAULT 0,
  sortOrder INTEGER NOT NULL DEFAULT 0,
  color TEXT NOT NULL
)`;

const CREATE_INDEX_BILL_DATE = `CREATE INDEX IF NOT EXISTS idx_bill_date ON ${Constants.TABLE_BILL}(date)`;
const CREATE_INDEX_BILL_TYPE_DATE = `CREATE INDEX IF NOT EXISTS idx_bill_type_date ON ${Constants.TABLE_BILL}(type, date)`;
const CREATE_INDEX_BILL_CATEGORY = `CREATE INDEX IF NOT EXISTS idx_bill_category ON ${Constants.TABLE_BILL}(categoryId)`;
const INSERT_DEFAULT_CATEGORY = `INSERT OR IGNORE INTO ${Constants.TABLE_CATEGORY}
  (id, name, icon, type, isCustom, sortOrder, color) VALUES (?, ?, ?, ?, ?, ?, ?)`;
const CREATE_BUDGET_TABLE = `CREATE TABLE IF NOT EXISTS ${Constants.TABLE_BUDGET} (
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  amount REAL NOT NULL,
  PRIMARY KEY (year, month)
)`;
const CREATE_STREAK_TABLE = `CREATE TABLE IF NOT EXISTS ${Constants.TABLE_STREAK} (
  id INTEGER PRIMARY KEY,
  currentStreak INTEGER NOT NULL DEFAULT 0,
  longestStreak INTEGER NOT NULL DEFAULT 0,
  totalDays INTEGER NOT NULL DEFAULT 0,
  lastRecordDate TEXT NOT NULL DEFAULT ''
)`;
const INSERT_EMPTY_STREAK = `INSERT OR IGNORE INTO ${Constants.TABLE_STREAK}
  (id, currentStreak, longestStreak, totalDays, lastRecordDate) VALUES (1, 0, 0, 0, '')`;
const INSERT_BILL = `INSERT INTO ${Constants.TABLE_BILL}
  (id, amount, type, categoryId, note, date, createTime) VALUES (?, ?, ?, ?, ?, ?, ?)`;
const INSERT_CATEGORY = `INSERT INTO ${Constants.TABLE_CATEGORY}
  (id, name, icon, type, isCustom, sortOrder, color) VALUES (?, ?, ?, ?, ?, ?, ?)`;
const INSERT_BUDGET = `INSERT INTO ${Constants.TABLE_BUDGET}
  (year, month, amount) VALUES (?, ?, ?)`;

export interface LedgerBudget {
  year: number;
  month: number;
  amount: number;
}

export interface LedgerBackupData {
  bills: BillRecord[];
  categories: Category[];
  budgets: LedgerBudget[];
}

export class DatabaseHelper {
  private static instance: DatabaseHelper | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;

  private constructor() {
  }

  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper();
    }
    return DatabaseHelper.instance;
  }

  async initDatabase(context: Context): Promise<void> {
    this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
    await this.rdbStore.executeSql(CREATE_BILL_TABLE);
    await this.rdbStore.executeSql(CREATE_CATEGORY_TABLE);
    await this.rdbStore.executeSql(CREATE_INDEX_BILL_DATE);
    await this.rdbStore.executeSql(CREATE_INDEX_BILL_TYPE_DATE);
    await this.rdbStore.executeSql(CREATE_INDEX_BILL_CATEGORY);
    await this.rdbStore.executeSql(CREATE_BUDGET_TABLE);
    await this.rdbStore.executeSql(CREATE_STREAK_TABLE);
    await this.rdbStore.executeSql(INSERT_EMPTY_STREAK);
    await this.insertDefaultCategories(context);
  }

  getStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('Database not initialized. Call initDatabase() first.');
    }
    return this.rdbStore;
  }

  async exportLedgerData(): Promise<LedgerBackupData> {
    return {
      bills: await this.queryAllBills(),
      categories: await this.queryAllCategories(),
      budgets: await this.queryAllBudgets()
    };
  }

  async restoreLedgerData(data: LedgerBackupData): Promise<void> {
    const store = this.getStore();
    let transactionStarted = false;
    try {
      store.beginTransaction();
      transactionStarted = true;
      await store.executeSql(`DELETE FROM ${Constants.TABLE_BILL}`);
      await store.executeSql(`DELETE FROM ${Constants.TABLE_CATEGORY}`);
      await store.executeSql(`DELETE FROM ${Constants.TABLE_BUDGET}`);
      await store.executeSql(`DELETE FROM ${Constants.TABLE_STREAK}`);

      for (const category of data.categories) {
        await store.executeSql(INSERT_CATEGORY, [
          category.id,
          category.name,
          category.icon,
          category.type,
          category.isCustom ? 1 : 0,
          category.sortOrder,
          category.color
        ]);
      }
      for (const bill of data.bills) {
        await store.executeSql(INSERT_BILL, [
          bill.id,
          bill.amount,
          bill.type,
          bill.categoryId,
          bill.note,
          bill.date,
          bill.createTime
        ]);
      }
      for (const budget of data.budgets) {
        await store.executeSql(INSERT_BUDGET, [budget.year, budget.month, budget.amount]);
      }

      await store.executeSql(INSERT_EMPTY_STREAK);
      store.commit();
      transactionStarted = false;
    } catch (error) {
      if (transactionStarted) {
        try {
          store.rollBack();
        } catch (rollbackError) {
          console.error('DatabaseHelper: ledger restore rollback failed', JSON.stringify(rollbackError));
        }
      }
      console.error('DatabaseHelper: ledger restore failed', JSON.stringify(error));
      throw new Error('Ledger data restore failed.');
    }

    DataChangeNotifier.notify(LedgerDataChange.BillChanged);
    DataChangeNotifier.notify(LedgerDataChange.CategoryChanged);
  }

  async resetAll(context: Context): Promise<void> {
    const store = this.getStore();
    try {
      await store.delete(new relationalStore.RdbPredicates(Constants.TABLE_BILL));
      await store.delete(new relationalStore.RdbPredicates(Constants.TABLE_BUDGET));
      await store.delete(new relationalStore.RdbPredicates(Constants.TABLE_CATEGORY));
      await store.delete(new relationalStore.RdbPredicates(Constants.TABLE_STREAK));
      await store.executeSql(INSERT_EMPTY_STREAK);
      await this.insertDefaultCategories(context);
    } catch (error) {
      console.error('DatabaseHelper: ledger reset failed', JSON.stringify(error));
      throw new Error('Ledger data reset failed.');
    }
    DataChangeNotifier.notify(LedgerDataChange.BillChanged);
    DataChangeNotifier.notify(LedgerDataChange.CategoryChanged);
  }

  private async queryAllBills(): Promise<BillRecord[]> {
    const resultSet = await this.getStore().querySql(
      `SELECT id, amount, type, categoryId, note, date, createTime
       FROM ${Constants.TABLE_BILL} ORDER BY date DESC, createTime DESC`
    );
    const bills: BillRecord[] = [];
    try {
      while (resultSet.goToNextRow()) {
        bills.push({
          id: resultSet.getString(resultSet.getColumnIndex('id')),
          amount: resultSet.getDouble(resultSet.getColumnIndex('amount')),
          type: resultSet.getLong(resultSet.getColumnIndex('type')) as BillType,
          categoryId: resultSet.getString(resultSet.getColumnIndex('categoryId')),
          note: resultSet.getString(resultSet.getColumnIndex('note')),
          date: resultSet.getString(resultSet.getColumnIndex('date')),
          createTime: resultSet.getLong(resultSet.getColumnIndex('createTime'))
        });
      }
    } finally {
      resultSet.close();
    }
    return bills;
  }

  private async queryAllCategories(): Promise<Category[]> {
    const resultSet = await this.getStore().querySql(
      `SELECT id, name, icon, type, isCustom, sortOrder, color
       FROM ${Constants.TABLE_CATEGORY} ORDER BY sortOrder ASC`
    );
    const categories: Category[] = [];
    try {
      while (resultSet.goToNextRow()) {
        categories.push({
          id: resultSet.getString(resultSet.getColumnIndex('id')),
          name: resultSet.getString(resultSet.getColumnIndex('name')),
          icon: resultSet.getString(resultSet.getColumnIndex('icon')),
          type: resultSet.getLong(resultSet.getColumnIndex('type')) as BillType,
          isCustom: resultSet.getLong(resultSet.getColumnIndex('isCustom')) === 1,
          sortOrder: resultSet.getLong(resultSet.getColumnIndex('sortOrder')),
          color: resultSet.getString(resultSet.getColumnIndex('color'))
        });
      }
    } finally {
      resultSet.close();
    }
    return categories;
  }

  private async queryAllBudgets(): Promise<LedgerBudget[]> {
    const resultSet = await this.getStore().querySql(
      `SELECT year, month, amount FROM ${Constants.TABLE_BUDGET}
       ORDER BY year DESC, month DESC`
    );
    const budgets: LedgerBudget[] = [];
    try {
      while (resultSet.goToNextRow()) {
        budgets.push({
          year: resultSet.getLong(resultSet.getColumnIndex('year')),
          month: resultSet.getLong(resultSet.getColumnIndex('month')),
          amount: resultSet.getDouble(resultSet.getColumnIndex('amount'))
        });
      }
    } finally {
      resultSet.close();
    }
    return budgets;
  }

  private async insertDefaultCategories(context: Context): Promise<void> {
    const store = this.getStore();
    const expenseCategories: Array<[string, Resource, string]> = [
      ['exp_food', $r('app.string.ledger_category_exp_food'), '🍜'],
      ['exp_transport', $r('app.string.ledger_category_exp_transport'), '🚌'],
      ['exp_shopping', $r('app.string.ledger_category_exp_shopping'), '🛒'],
      ['exp_housing', $r('app.string.ledger_category_exp_housing'), '🏠'],
      ['exp_entertainment', $r('app.string.ledger_category_exp_entertainment'), '🎮'],
      ['exp_medical', $r('app.string.ledger_category_exp_medical'), '💊'],
      ['exp_education', $r('app.string.ledger_category_exp_education'), '📚'],
      ['exp_communication', $r('app.string.ledger_category_exp_communication'), '📱'],
      ['exp_clothing', $r('app.string.ledger_category_exp_clothing'), '👔'],
      ['exp_sports', $r('app.string.ledger_category_exp_sports'), '⚽'],
      ['exp_social', $r('app.string.ledger_category_exp_social'), '👥'],
      ['exp_other', $r('app.string.ledger_category_exp_other'), '📦']
    ];

    const incomeCategories: Array<[string, Resource, string]> = [
      ['inc_salary', $r('app.string.ledger_category_inc_salary'), '💰'],
      ['inc_bonus', $r('app.string.ledger_category_inc_bonus'), '🎁'],
      ['inc_parttime', $r('app.string.ledger_category_inc_parttime'), '💼'],
      ['inc_investment', $r('app.string.ledger_category_inc_investment'), '📈'],
      ['inc_redpacket', $r('app.string.ledger_category_inc_redpacket'), '🧧'],
      ['inc_other', $r('app.string.ledger_category_inc_other'), '💎']
    ];

    const colors = Constants.CATEGORY_COLORS;

    for (let i = 0; i < expenseCategories.length; i++) {
      const cat = expenseCategories[i];
      await store.executeSql(INSERT_DEFAULT_CATEGORY, [
        cat[0],
        context.resourceManager.getStringSync(cat[1]),
        cat[2],
        BillType.EXPENSE,
        0,
        i,
        this.getResourceColorString(context, colors[i % colors.length])
      ]);
    }

    for (let i = 0; i < incomeCategories.length; i++) {
      const cat = incomeCategories[i];
      await store.executeSql(INSERT_DEFAULT_CATEGORY, [
        cat[0],
        context.resourceManager.getStringSync(cat[1]),
        cat[2],
        BillType.INCOME,
        0,
        i,
        this.getResourceColorString(context, colors[(i + expenseCategories.length) % colors.length])
      ]);
    }
  }

  private getResourceColorString(context: Context, resource: Resource): string {
    const colorValue = context.resourceManager.getColorSync(resource);
    const rgb = (colorValue & 0x00FFFFFF).toString(16).toUpperCase();
    return `#${'000000'.substring(rgb.length)}${rgb}`;
  }
}
