import { LedgerBudgetPage } from '../../ledger/pages/LedgerBudgetPage'

@Entry
@Component
struct LedgerBudgetRoutePage {
  build() {
    Column() {
      LedgerBudgetPage()
    }
    .width('100%')
    .height('100%')
  }
}
