import { BillType } from './BillRecord';

export interface Category {
  id: string;
  name: string;
  icon: string;
  type: BillType;
  isCustom: boolean;
  sortOrder: number;
  color: string;
}
