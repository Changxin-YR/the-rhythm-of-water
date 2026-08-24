export const MIN_BOTTOM_CONTROL_CLEARANCE_VP: number = 28

export function normalizeSafeAreaHeightPx(heightPx: number): number {
  if (!Number.isFinite(heightPx) || heightPx < 0) return 0
  return heightPx
}

export function minimumBottomControlInsetVp(safeAreaBottomVp: number): number {
  return Math.max(MIN_BOTTOM_CONTROL_CLEARANCE_VP, normalizeSafeAreaHeightPx(safeAreaBottomVp))
}
