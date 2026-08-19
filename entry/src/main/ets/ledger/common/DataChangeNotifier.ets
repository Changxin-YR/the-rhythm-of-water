export enum LedgerDataChange {
  BillChanged,
  CategoryChanged
}

export type LedgerDataChangeListener = (change: LedgerDataChange) => void;

export class DataChangeNotifier {
  private static listeners: LedgerDataChangeListener[] = [];

  static subscribe(listener: LedgerDataChangeListener): void {
    if (DataChangeNotifier.listeners.indexOf(listener) < 0) {
      DataChangeNotifier.listeners.push(listener);
    }
  }

  static unsubscribe(listener: LedgerDataChangeListener): void {
    const index = DataChangeNotifier.listeners.indexOf(listener);
    if (index >= 0) {
      DataChangeNotifier.listeners.splice(index, 1);
    }
  }

  static notify(change: LedgerDataChange): void {
    const currentListeners = DataChangeNotifier.listeners.slice();
    for (const listener of currentListeners) {
      listener(change);
    }
  }
}
