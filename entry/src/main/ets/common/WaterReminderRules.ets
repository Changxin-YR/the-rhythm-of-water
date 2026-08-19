import { Constants } from './Constants'

export interface NormalizedDrinkPayload {
  amountMl: number
  hydrationMl: number
}

export function shouldHideProgressIndicator(progress: number): boolean {
  return Number.isFinite(progress) && progress >= 97
}

export function normalizeDrinkPayload(amountMl: number, hydrationRate: number): NormalizedDrinkPayload {
  const normalizedAmountMl = Number.isFinite(amountMl) && amountMl > 0 ? amountMl : 0
  const normalizedHydrationRate = Number.isFinite(hydrationRate) && hydrationRate > 0 ? hydrationRate : 0
  return {
    amountMl: normalizedAmountMl,
    hydrationMl: Math.max(0, Math.round(normalizedAmountMl * normalizedHydrationRate))
  }
}

export function parsePositiveWholeMl(raw: string, maxAmountMl: number = 5000): number | null {
  const trimmed = raw.trim()
  if (!/^\d+$/.test(trimmed)) return null

  const amount = Number(trimmed)
  if (!Number.isFinite(amount) || amount <= 0 || amount > maxAmountMl || Math.floor(amount) !== amount) {
    return null
  }
  return amount
}

export function resolveSelectedId(selectedId: string | null, availableIds: string[]): string | null {
  if (selectedId !== null && availableIds.indexOf(selectedId) >= 0) return selectedId
  return availableIds.length > 0 ? availableIds[0] : null
}

export function clampGoal(goalMl: number): number {
  if (!Number.isFinite(goalMl)) return Constants.MIN_GOAL_ML
  return Math.min(Math.max(goalMl, Constants.MIN_GOAL_ML), Constants.MAX_GOAL_ML)
}
