export const LEDGER_TAB_INDEX: number = 2
export const WATER_TAB_INDEX: number = 1
export const ACHIEVEMENT_TAB_INDEX: number = WATER_TAB_INDEX
export const SETTINGS_TAB_INDEX: number = 3

export function nextRefreshRevision(current: number | undefined): number {
  if (!Number.isFinite(current) || current === undefined || current < 0) return 1
  return Math.floor(current) + 1
}

export function shouldRefreshAchievementOnTabSelection(currentIndex: number, nextIndex: number): boolean {
  return nextIndex === ACHIEVEMENT_TAB_INDEX
}

export function publishDataRefresh(): void {
  const current = AppStorage.get<number>('refreshSignal')
  AppStorage.setOrCreate('refreshSignal', nextRefreshRevision(current))
}
