import { DrinkRepository } from '../repositories/DrinkRepository'
import { DrinkRecord, DrinkRecordPayload } from '../models/DrinkRecord'
import { DailySummary } from '../models/DailySummary'
import { IdGenerator } from '../common/IdGenerator'
import { DateUtils } from '../common/DateUtils'
import { normalizeDrinkPayload } from '../common/WaterReminderRules'

export class DrinkService {
  private repository: DrinkRepository

  constructor(context: Context) {
    this.repository = new DrinkRepository(context)
  }

  async addRecord(payload: DrinkRecordPayload): Promise<DrinkRecord> {
    const now = Date.now()
    const normalized = normalizeDrinkPayload(payload.amountMl, payload.hydrationRate)
    const record: DrinkRecord = {
      id: payload.id ?? IdGenerator.generate(),
      beverageId: payload.beverageId,
      beverageName: payload.beverageName,
      beverageIcon: payload.beverageIcon,
      amountMl: normalized.amountMl,
      hydrationMl: normalized.hydrationMl,
      happenedAt: payload.happenedAt,
      createdAt: now,
      updatedAt: now
    }

    const existing = payload.id ? await this.repository.get(payload.id) : null
    if (existing) {
      record.createdAt = existing.createdAt
    }

    await this.repository.save(record)
    return record
  }

  async removeRecord(id: string): Promise<void> {
    await this.repository.remove(id)
  }

  async getRecord(id: string): Promise<DrinkRecord | null> {
    return this.repository.get(id)
  }

  async getTodayRecords(): Promise<DrinkRecord[]> {
    return this.repository.getByDate(DateUtils.getToday())
  }

  async getRecordsByDate(date: string): Promise<DrinkRecord[]> {
    return this.repository.getByDate(date)
  }

  async getRecordsByRange(start: string, end: string): Promise<DrinkRecord[]> {
    return this.repository.getByDateRange(start, end)
  }

  async getTodaySummary(goalMl: number): Promise<DailySummary> {
    const records = await this.getTodayRecords()
    return this.buildSummary(DateUtils.getToday(), records, goalMl)
  }

  async getDailySummary(date: string, goalMl: number): Promise<DailySummary> {
    const records = await this.getRecordsByDate(date)
    return this.buildSummary(date, records, goalMl)
  }

  async getDailySummaries(startDate: string, endDate: string, goalMl: number): Promise<DailySummary[]> {
    const localStartDate = DateUtils.parseLocalDate(startDate)
    const localEndDate = DateUtils.parseLocalDate(endDate)
    if (!localStartDate || !localEndDate) return []
    const dates = DateUtils.getDateRange(localStartDate, localEndDate)
    const allRecords = await this.repository.getByDateRange(startDate, endDate)
    const summaries: DailySummary[] = []

    for (const date of dates) {
      const localDate = DateUtils.parseLocalDate(date)
      if (!localDate) continue
      const dayStart = DateUtils.getStartOfDay(localDate)
      const dayEnd = DateUtils.getEndOfDay(localDate)
      const dayRecords = allRecords.filter(r => r.happenedAt >= dayStart && r.happenedAt <= dayEnd)
      summaries.push(this.buildSummary(date, dayRecords, goalMl))
    }
    return summaries
  }

  async getTotalVolume(): Promise<number> {
    return this.repository.getTotalVolume()
  }

  async getStreak(goalMl: number): Promise<number> {
    if (!Number.isFinite(goalMl) || goalMl <= 0) return 0
    let streak = 0
    const today = new Date()
    let checkDate = new Date(today)

    while (true) {
      const dateStr = DateUtils.formatDate(checkDate)
      const records = await this.repository.getByDate(dateStr)
      const totalMl = records.reduce((sum, r) => sum + r.hydrationMl, 0)

      if (totalMl >= goalMl) {
        streak++
        checkDate.setDate(checkDate.getDate() - 1)
      } else {
        if (dateStr === DateUtils.getToday()) {
          checkDate.setDate(checkDate.getDate() - 1)
          continue
        }
        break
      }

      if (streak > 1000) break
    }
    return streak
  }

  async getEarlyDrinkStreak(): Promise<number> {
    let streak = 0
    const today = new Date()
    let checkDate = new Date(today)

    while (true) {
      const dateStr = DateUtils.formatDate(checkDate)
      const records = await this.repository.getByDate(dateStr)
      const hasEarlyDrink = records.some((record: DrinkRecord) => new Date(record.happenedAt).getHours() < 8)

      if (hasEarlyDrink) {
        streak++
        checkDate.setDate(checkDate.getDate() - 1)
      } else {
        if (dateStr === DateUtils.getToday()) {
          checkDate.setDate(checkDate.getDate() - 1)
          continue
        }
        break
      }

      if (streak > 1000) break
    }
    return streak
  }

  async clearAll(): Promise<void> {
    await this.repository.clear()
  }

  async exportData(): Promise<string> {
    return this.repository.exportAll()
  }

  async importData(jsonStr: string): Promise<number> {
    return this.repository.importRecords(jsonStr)
  }

  private buildSummary(date: string, records: DrinkRecord[], goalMl: number): DailySummary {
    const totalMl = records.reduce((sum, r) => sum + r.amountMl, 0)
    const hydrationMl = records.reduce((sum, r) => sum + r.hydrationMl, 0)
    const breakdown: Record<string, number> = {}
    for (const r of records) {
      breakdown[r.beverageId] = (breakdown[r.beverageId] ?? 0) + r.amountMl
    }

    return {
      date,
      totalMl,
      hydrationMl,
      goalMl,
      completionRate: goalMl > 0 ? Math.min(Math.round((hydrationMl / goalMl) * 100), 999) : 0,
      recordCount: records.length,
      beverageBreakdown: breakdown,
      streakDay: 0
    }
  }
}
