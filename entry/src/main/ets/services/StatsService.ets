import { DailySummary, WeeklyStats, MonthlyStats, PeriodBreakdown } from '../models/DailySummary'
import { DrinkService } from './DrinkService'
import { DateUtils } from '../common/DateUtils'

export class StatsService {
  private drinkService: DrinkService

  constructor(context: Context) {
    this.drinkService = new DrinkService(context)
  }

  async getWeeklyStats(goalMl: number): Promise<WeeklyStats> {
    const today = new Date()
    const weekStart = DateUtils.getWeekStart(today)
    const startStr = DateUtils.formatDate(weekStart)
    const weekEnd = new Date(weekStart)
    weekEnd.setDate(weekStart.getDate() + 6)
    const endStr = DateUtils.formatDate(weekEnd)
    const days = await this.drinkService.getDailySummaries(startStr, endStr, goalMl)
    const totalMl = days.reduce((sum, d) => sum + d.hydrationMl, 0)
    const goalDays = days.filter(d => d.completionRate >= 100).length

    return {
      days,
      avgMl: days.length > 0 ? Math.round(totalMl / days.length) : 0,
      goalDays,
      totalDays: days.length
    }
  }

  async getMonthlyStats(goalMl: number): Promise<MonthlyStats> {
    const today = new Date()
    const monthStart = DateUtils.getMonthStart(today)
    const startStr = DateUtils.formatDate(monthStart)
    const endStr = DateUtils.formatDate(today)
    const days = await this.drinkService.getDailySummaries(startStr, endStr, goalMl)
    const totalMl = days.reduce((sum, d) => sum + d.hydrationMl, 0)
    const goalDays = days.filter(d => d.completionRate >= 100).length

    return {
      days,
      avgMl: days.length > 0 ? Math.round(totalMl / days.length) : 0,
      goalDays,
      totalDays: days.length
    }
  }

  async getYearlyStats(goalMl: number): Promise<MonthlyStats> {
    const today = new Date()
    const yearStart = DateUtils.getYearStart(today)
    const startStr = DateUtils.formatDate(yearStart)
    const endStr = DateUtils.formatDate(today)
    const days = await this.drinkService.getDailySummaries(startStr, endStr, goalMl)
    const totalMl = days.reduce((sum, d) => sum + d.hydrationMl, 0)
    const goalDays = days.filter(d => d.completionRate >= 100).length

    return {
      days,
      avgMl: days.length > 0 ? Math.round(totalMl / days.length) : 0,
      goalDays,
      totalDays: days.length
    }
  }

  async getPeriodBreakdown(date: string): Promise<PeriodBreakdown> {
    const records = await this.drinkService.getRecordsByDate(date)
    const breakdown: PeriodBreakdown = { morning: 0, afternoon: 0, evening: 0 }
    for (const r of records) {
      const period = DateUtils.getPeriod(r.happenedAt)
      if (period === 'morning') {
        breakdown.morning += r.hydrationMl
      } else if (period === 'afternoon') {
        breakdown.afternoon += r.hydrationMl
      } else {
        breakdown.evening += r.hydrationMl
      }
    }
    return breakdown
  }

  async getBeverageBreakdown(date: string): Promise<Record<string, number>> {
    const records = await this.drinkService.getRecordsByDate(date)
    const breakdown: Record<string, number> = {}
    for (const r of records) {
      const key = r.beverageName
      breakdown[key] = (breakdown[key] ?? 0) + r.amountMl
    }
    return breakdown
  }
}
