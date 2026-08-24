import { Achievement } from '../models/Achievement'

export interface AchievementProgressMetrics {
  todayTotal: number
  todayCount: number
  totalVolume: number
  streak: number
  todayBeverages: number
  hasEarlyDrink: boolean
  earlyDrinkStreak: number
}

export interface AchievementRefreshResult {
  achievements: Achievement[]
  newlyUnlocked: Achievement[]
}

export function calculateAchievementProgress(
  achievement: Achievement,
  metrics: AchievementProgressMetrics,
  goalMl: number
): number {
  switch (achievement.id) {
    case 'first_drink':
      return metrics.todayCount > 0 ? 1 : 0
    case 'first_goal':
      return metrics.todayTotal >= goalMl ? 1 : 0
    case 'streak_7':
    case 'streak_30':
    case 'streak_100':
    case 'streak_365':
      return metrics.streak
    case 'volume_10l':
    case 'volume_100l':
    case 'volume_500l':
    case 'volume_1000l':
      return metrics.totalVolume
    case 'early_bird':
      return Math.min(metrics.earlyDrinkStreak, achievement.targetValue)
    case 'variety':
      return metrics.todayBeverages
    case 'eight_cups':
      return metrics.todayCount
    case 'overachiever':
      return goalMl > 0 ? Math.round((metrics.todayTotal / goalMl) * 100) : 0
    default:
      return 0
  }
}

export function reconcileAchievementProgress(
  achievements: Achievement[],
  metrics: AchievementProgressMetrics,
  goalMl: number,
  updatedAt: number
): AchievementRefreshResult {
  const refreshed: Achievement[] = []
  const newlyUnlocked: Achievement[] = []

  for (const achievement of achievements) {
    const currentValue = calculateAchievementProgress(achievement, metrics, goalMl)
    const unlockedNow = achievement.unlockedAt === null && currentValue >= achievement.targetValue
    const refreshedAchievement: Achievement = {
      id: achievement.id,
      title: achievement.title,
      description: achievement.description,
      icon: achievement.icon,
      category: achievement.category,
      targetValue: achievement.targetValue,
      currentValue: currentValue,
      progress: achievement.targetValue > 0
        ? Math.min(Math.round((currentValue / achievement.targetValue) * 100), 100)
        : 0,
      unlockedAt: unlockedNow ? updatedAt : achievement.unlockedAt
    }
    refreshed.push(refreshedAchievement)
    if (unlockedNow) newlyUnlocked.push(refreshedAchievement)
  }

  return { achievements: refreshed, newlyUnlocked: newlyUnlocked }
}
