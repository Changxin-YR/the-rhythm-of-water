import { LedgerEditBillPage } from '../../ledger/pages/LedgerEditBillPage'

@Entry
@Component
struct LedgerEditBillRoutePage {
  build() {
    Column() {
      LedgerEditBillPage()
    }
    .width('100%')
    .height('100%')
  }
}
