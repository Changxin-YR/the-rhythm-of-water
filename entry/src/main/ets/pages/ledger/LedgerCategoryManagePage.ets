import { LedgerCategoryManagePage } from '../../ledger/pages/LedgerCategoryManagePage'

@Entry
@Component
struct LedgerCategoryManageRoutePage {
  build() {
    Column() {
      LedgerCategoryManagePage()
    }
    .width('100%')
    .height('100%')
  }
}
