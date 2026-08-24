import { DataChangeNotifier, LedgerDataChange, LedgerDataChangeListener } from '../ledger/common/DataChangeNotifier'
import { publishDataRefresh } from '../common/DataRefresh'

export class LedgerRefreshBridge {
  private static installed: boolean = false
  private static listener: LedgerDataChangeListener = (_change: LedgerDataChange): void => {
    publishDataRefresh()
  }

  static install(): void {
    if (LedgerRefreshBridge.installed) return
    DataChangeNotifier.subscribe(LedgerRefreshBridge.listener)
    LedgerRefreshBridge.installed = true
  }
}
