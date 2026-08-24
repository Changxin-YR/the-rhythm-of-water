import { describe, expect, it } from '@ohos/hypium'
import { DateUtils } from '../../../main/ets/ledger/common/DateUtils'
import { NumberUtils } from '../../../main/ets/ledger/common/NumberUtils'
import { LedgerBreakpoint, ResponsiveUtils } from '../../../main/ets/ledger/common/ResponsiveUtils'
import { validateLedgerBillsJson, validateLedgerBudgetsJson, validateLedgerCategoriesJson } from '../../../main/ets/common/BackupRules'

export default function ledgerRulesTest(): void {
  describe('LedgerRules', (): void => {
    it('formatsMonthBoundariesAndAmountsForLedgerViews', 0, (): void => {
      expect(DateUtils.getMonthRange(2026, 2).end).assertEqual('2026-02-28')
      expect(DateUtils.getMonthRange(2024, 2).end).assertEqual('2024-02-29')
      expect(NumberUtils.formatSimpleAmount(1234.5)).assertEqual('1,234.50')
    })

    it('selectsLayoutBreakpointsFromViewportUnits', 0, (): void => {
      const pxToVp = (value: number): number => value / 3
      expect(ResponsiveUtils.fromAreaWidth(1320, pxToVp)).assertEqual(LedgerBreakpoint.COMPACT)
      expect(ResponsiveUtils.fromAreaWidth(1800, pxToVp)).assertEqual(LedgerBreakpoint.MEDIUM)
      expect(ResponsiveUtils.fromAreaWidth(2520, pxToVp)).assertEqual(LedgerBreakpoint.EXPANDED)
    })

    it('usesTheAvailableWidthOnCompactScreens', 0, (): void => {
      expect(ResponsiveUtils.getContentMaxWidth(LedgerBreakpoint.COMPACT)).assertEqual('100%')
    })

    it('validatesLedgerBackupRowsBeforeDatabaseRestore', 0, (): void => {
      expect(validateLedgerBillsJson(JSON.stringify([{
        id: 'bill-1', amount: 12.5, type: 1, categoryId: 'exp_food', note: '午餐',
        date: '2026-08-14', createTime: 1786700000000
      }]))).assertTrue()
      expect(validateLedgerBillsJson(JSON.stringify([{
        id: 'bill-1', amount: 12.5, type: 3, categoryId: 'exp_food', note: '午餐',
        date: '2026-08-14', createTime: 1786700000000
      }]))).assertFalse()
      expect(validateLedgerCategoriesJson(JSON.stringify([{
        id: 'custom-food', name: '工作餐', icon: '🍱', type: 1,
        isCustom: true, sortOrder: 20, color: '#FF8800'
      }]))).assertTrue()
      expect(validateLedgerBudgetsJson(JSON.stringify([
        { year: 2026, month: 8, amount: 3000 }
      ]))).assertTrue()
    })

  })
}
