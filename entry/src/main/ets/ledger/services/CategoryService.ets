import relationalStore from '@ohos.data.relationalStore';
import { Category } from '../models/Category';
import { BillType } from '../models/BillRecord';
import { Constants } from '../common/Constants';
import { DatabaseHelper } from './DatabaseHelper';
import { DataChangeNotifier, LedgerDataChange } from '../common/DataChangeNotifier';

export class CategoryService {
  private getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getInstance().getStore();
  }

  async getAllCategories(): Promise<Category[]> {
    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_CATEGORY);
    predicates.orderByAsc('sortOrder');
    return await this.queryCategories(predicates);
  }

  async getCategoriesByType(type: BillType): Promise<Category[]> {
    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_CATEGORY);
    predicates.equalTo('type', type);
    predicates.orderByAsc('sortOrder');
    return await this.queryCategories(predicates);
  }

  async getCategoryById(id: string): Promise<Category | null> {
    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_CATEGORY);
    predicates.equalTo('id', id);
    const categories = await this.queryCategories(predicates);
    return categories.length > 0 ? categories[0] : null;
  }

  async addCategory(category: Category): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = {
      id: category.id,
      name: category.name,
      icon: category.icon,
      type: category.type,
      isCustom: category.isCustom ? 1 : 0,
      sortOrder: category.sortOrder,
      color: category.color
    };
    await this.getStore().insert(Constants.TABLE_CATEGORY, valueBucket);
    DataChangeNotifier.notify(LedgerDataChange.CategoryChanged);
  }

  async deleteCategory(id: string): Promise<void> {
    const category = await this.getCategoryById(id);
    if (!category) return;

    const fallbackId = category.type === BillType.EXPENSE ? 'exp_other' : 'inc_other';
    const billPredicates = new relationalStore.RdbPredicates(Constants.TABLE_BILL);
    billPredicates.equalTo('categoryId', id);
    const valueBucket: relationalStore.ValuesBucket = { categoryId: fallbackId };
    await this.getStore().update(valueBucket, billPredicates);

    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_CATEGORY);
    predicates.equalTo('id', id);
    await this.getStore().delete(predicates);
    DataChangeNotifier.notify(LedgerDataChange.BillChanged);
    DataChangeNotifier.notify(LedgerDataChange.CategoryChanged);
  }

  async getCategoryBillCount(id: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates(Constants.TABLE_BILL);
    predicates.equalTo('categoryId', id);
    const resultSet = await this.getStore().query(predicates, ['id']);
    let count = 0;
    try {
      count = resultSet.rowCount;
    } finally {
      resultSet.close();
    }
    return count;
  }

  private async queryCategories(predicates: relationalStore.RdbPredicates): Promise<Category[]> {
    const resultSet = await this.getStore().query(predicates,
      ['id', 'name', 'icon', 'type', 'isCustom', 'sortOrder', 'color']);
    const categories: Category[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const category: Category = {
          id: resultSet.getString(resultSet.getColumnIndex('id')),
          name: resultSet.getString(resultSet.getColumnIndex('name')),
          icon: resultSet.getString(resultSet.getColumnIndex('icon')),
          type: resultSet.getLong(resultSet.getColumnIndex('type')) as BillType,
          isCustom: resultSet.getLong(resultSet.getColumnIndex('isCustom')) === 1,
          sortOrder: resultSet.getLong(resultSet.getColumnIndex('sortOrder')),
          color: resultSet.getString(resultSet.getColumnIndex('color'))
        };
        categories.push(category);
      }
    } finally {
      resultSet.close();
    }
    return categories;
  }
}
