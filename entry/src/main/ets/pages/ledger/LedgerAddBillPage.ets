import { LedgerAddBillPage } from '../../ledger/pages/LedgerAddBillPage'

@Entry
@Component
struct LedgerAddBillRoutePage {
  build() {
    Column() {
      LedgerAddBillPage()
    }
    .width('100%')
    .height('100%')
  }
}
