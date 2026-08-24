import { preferences } from '@kit.ArkData'
import { DrinkRecord } from '../models/DrinkRecord'
import { Constants } from '../common/Constants'
import { DateUtils } from '../common/DateUtils'
import { parseJsonArray } from '../common/JsonUtils'
import { validateDrinkRecords } from '../common/BackupRules'

export class DrinkRepository {
  private store: preferences.Preferences | null = null
  private context: Context

  constructor(context: Context) {
    this.context = context
  }

  private async getStore(): Promise<preferences.Preferences> {
    if (!this.store) {
      this.store = await preferences.getPreferences(this.context, Constants.STORE_DRINK_RECORDS)
    }
    return this.store
  }

  async list(): Promise<DrinkRecord[]> {
    const store = await this.getStore()
    const raw = await store.get('records', '[]') as string
    if (!validateDrinkRecords(raw)) {
      await store.put('records', '[]')
      await store.flush()
      return []
    }
    const records = parseJsonArray<DrinkRecord>(raw) ?? []
    return records.sort((a, b) => b.happenedAt - a.happenedAt)
  }

  async getByDate(date: string): Promise<DrinkRecord[]> {
    const all = await this.list()
    const localDate = DateUtils.parseLocalDate(date)
    if (!localDate) return []
    const dayStart = DateUtils.getStartOfDay(localDate)
    const dayEnd = DateUtils.getEndOfDay(localDate)
    return all.filter(r => r.happenedAt >= dayStart && r.happenedAt <= dayEnd)
  }

  async getByDateRange(startDate: string, endDate: string): Promise<DrinkRecord[]> {
    const all = await this.list()
    const localStartDate = DateUtils.parseLocalDate(startDate)
    const localEndDate = DateUtils.parseLocalDate(endDate)
    if (!localStartDate || !localEndDate) return []
    const start = DateUtils.getStartOfDay(localStartDate)
    const end = DateUtils.getEndOfDay(localEndDate)
    return all.filter(r => r.happenedAt >= start && r.happenedAt <= end)
  }

  async save(record: DrinkRecord): Promise<void> {
    const records = await this.list()
    const index = records.findIndex(r => r.id === record.id)
    if (index >= 0) {
      records[index] = record
    } else {
      records.push(record)
    }
    const store = await this.getStore()
    await store.put('records', JSON.stringify(records))
    await store.flush()
  }

  async remove(id: string): Promise<void> {
    const records = await this.list()
    const filtered = records.filter(r => r.id !== id)
    const store = await this.getStore()
    await store.put('records', JSON.stringify(filtered))
    await store.flush()
  }

  async get(id: string): Promise<DrinkRecord | null> {
    const records = await this.list()
    return records.find(r => r.id === id) ?? null
  }

  async getTotalVolume(): Promise<number> {
    const records = await this.list()
    return records.reduce((sum, r) => sum + r.hydrationMl, 0)
  }

  async clear(): Promise<void> {
    const store = await this.getStore()
    await store.put('records', '[]')
    await store.flush()
  }

  async exportAll(): Promise<string> {
    const records = await this.list()
    return JSON.stringify(records, null, 2)
  }

  async importRecords(jsonStr: string): Promise<number> {
    if (!validateDrinkRecords(jsonStr)) return 0
    const imported = parseJsonArray<DrinkRecord>(jsonStr)
    if (!imported) return 0
    const store = await this.getStore()
    await store.put('records', JSON.stringify(imported))
    await store.flush()
    return imported.length
  }
}
