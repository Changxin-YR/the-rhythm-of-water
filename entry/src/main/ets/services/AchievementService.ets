import { AchievementRepository } from '../repositories/AchievementRepository'
import { Achievement } from '../models/Achievement'
import { DrinkService } from './DrinkService'
import { DateUtils } from '../common/DateUtils'
import { AchievementProgressMetrics, reconcileAchievementProgress } from '../common/AchievementRules'

export class AchievementService {
  private repository: AchievementRepository
  private drinkService: DrinkService

  constructor(context: Context) {
    this.repository = new AchievementRepository(context)
    this.drinkService = new DrinkService(context)
  }

  async getAll(): Promise<Achievement[]> {
    return this.repository.list()
  }

  async getUnlocked(): Promise<Achievement[]> {
    return this.repository.getUnlocked()
  }

  async checkAndUpdate(goalMl: number): Promise<Achievement[]> {
    const achievements = await this.repository.list()
    const now = Date.now()

    const todayRecords = await this.drinkService.getTodayRecords()
    const totalVolume = await this.drinkService.getTotalVolume()
    const streak = await this.drinkService.getStreak(goalMl)
    const earlyDrinkStreak = await this.drinkService.getEarlyDrinkStreak()
    const todayTotal = todayRecords.reduce((sum, r) => sum + r.hydrationMl, 0)
    const todayCount = todayRecords.length
    const todayBeverages = new Set(todayRecords.map(r => r.beverageId)).size
    const metrics: AchievementProgressMetrics = {
      todayTotal,
      todayCount,
      totalVolume,
      streak,
      todayBeverages,
      hasEarlyDrink: earlyDrinkStreak > 0,
      earlyDrinkStreak
    }

    const refreshed = reconcileAchievementProgress(achievements, metrics, goalMl, now)
    await this.repository.saveAll(refreshed.achievements)
    return refreshed.achievements
  }

  async reset(): Promise<void> {
    await this.repository.reset()
  }
}
