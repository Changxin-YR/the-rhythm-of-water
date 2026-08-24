import { ActivityLevel, SpecialState, ClimateType } from '../models/UserProfile'
import { Constants } from './Constants'

export class GoalCalculator {
  static calculate(
    weightKg: number,
    activityLevel: ActivityLevel,
    specialState: SpecialState,
    climate: ClimateType
  ): number {
    const safeWeightKg = Number.isFinite(weightKg) && weightKg > 0 ? weightKg : 0
    const base = safeWeightKg * 33

    const activityMultiplier = GoalCalculator.getActivityMultiplier(activityLevel)
    let goal = base * activityMultiplier

    goal += GoalCalculator.getSpecialStateAddition(specialState)
    goal += GoalCalculator.getClimateAddition(climate)

    goal = Math.round(goal / 50) * 50
    return Math.max(Constants.MIN_GOAL_ML, Math.min(Constants.MAX_GOAL_ML, goal))
  }

  private static getActivityMultiplier(level: ActivityLevel): number {
    switch (level) {
      case 'sedentary': return 1.0
      case 'light': return 1.1
      case 'moderate': return 1.2
      case 'active': return 1.3
      case 'athlete': return 1.5
      default: return 1.0
    }
  }

  private static getSpecialStateAddition(state: SpecialState): number {
    switch (state) {
      case 'pregnant': return 300
      case 'breastfeeding': return 500
      case 'sick': return 200
      default: return 0
    }
  }

  private static getClimateAddition(climate: ClimateType): number {
    switch (climate) {
      case 'hot': return 300
      case 'dry': return 200
      default: return 0
    }
  }
}
