export enum BillType {
  INCOME = 0,
  EXPENSE = 1
}

export interface BillRecord {
  id: string;
  amount: number;
  type: BillType;
  categoryId: string;
  note: string;
  date: string; // YYYY-MM-DD
  createTime: number;
}
