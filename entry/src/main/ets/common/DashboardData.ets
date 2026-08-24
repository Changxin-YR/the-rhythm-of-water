export function completionPercent(currentMl: number, goalMl: number): number {
  if (!Number.isFinite(currentMl) || !Number.isFinite(goalMl) || goalMl <= 0) return 0
  return Math.min(Math.max(Math.floor((currentMl / goalMl) * 100), 0), 100)
}

export function remainingGoalMl(currentMl: number, goalMl: number): number {
  if (!Number.isFinite(currentMl) || !Number.isFinite(goalMl)) return 0
  return Math.max(Math.round(goalMl - currentMl), 0)
}

export interface AchievementDisplayMetrics {
  totalVolume: number
  streak: number
}

export function getAchievementDisplayMetrics(totalVolume: number, streak: number, plantWaterReceived: number): AchievementDisplayMetrics {
  return { totalVolume, streak }
}
