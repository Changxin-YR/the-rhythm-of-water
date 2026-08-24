export function completionPercent(currentMl: number, goalMl: number): number {
  if (!Number.isFinite(currentMl) || !Number.isFinite(goalMl) || goalMl <= 0) return 0
  if (currentMl <= 0) return 0
  return Math.min(100, Math.max(0, Math.round((currentMl / goalMl) * 100)))
}

export function formatBalance(amount: number): string {
  const safeAmount = Number.isFinite(amount) ? amount : 0
  const absolute = Math.abs(safeAmount).toFixed(2)
  return safeAmount < 0 ? `-¥${absolute}` : `¥${absolute}`
}
