import { LedgerStatisticsPage } from '../../ledger/pages/LedgerStatisticsPage'

@Entry
@Component
struct LedgerStatisticsRoutePage {
  build() {
    Column() {
      LedgerStatisticsPage()
    }
    .width('100%')
    .height('100%')
  }
}
