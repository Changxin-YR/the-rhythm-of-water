import { UserProfile } from '../models/UserProfile'
import { GoalCalculator } from '../common/GoalCalculator'
import { clampGoal } from '../common/WaterReminderRules'
import { PreferencesService } from './PreferencesService'

export class GoalService {
  private prefsService: PreferencesService

  constructor(context: Context) {
    this.prefsService = new PreferencesService(context)
  }

  async calculateAndSaveGoal(): Promise<number> {
    const profile = await this.prefsService.getProfile()
    if (!profile.isGoalAutoCalculated) {
      return profile.dailyGoalMl
    }
    const goal = GoalCalculator.calculate(
      profile.weightKg,
      profile.activityLevel,
      profile.specialState,
      profile.climate
    )
    profile.dailyGoalMl = goal
    await this.prefsService.saveProfile(profile)
    return goal
  }

  async getGoal(): Promise<number> {
    const profile = await this.prefsService.getProfile()
    return profile.dailyGoalMl
  }

  async setManualGoal(goalMl: number): Promise<void> {
    const profile = await this.prefsService.getProfile()
    profile.dailyGoalMl = clampGoal(goalMl)
    profile.isGoalAutoCalculated = false
    await this.prefsService.saveProfile(profile)
  }

  async setAutoGoal(): Promise<number> {
    const profile = await this.prefsService.getProfile()
    profile.isGoalAutoCalculated = true
    await this.prefsService.saveProfile(profile)
    return this.calculateAndSaveGoal()
  }
}
