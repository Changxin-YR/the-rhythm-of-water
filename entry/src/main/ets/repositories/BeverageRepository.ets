import { preferences } from '@kit.ArkData'
import { Beverage, DEFAULT_BEVERAGES, cloneBeverages } from '../models/Beverage'
import { Constants } from '../common/Constants'
import { parseJsonArray } from '../common/JsonUtils'
import { validateBeveragesJson } from '../common/BackupRules'

export class BeverageRepository {
  private store: preferences.Preferences | null = null
  private context: Context

  constructor(context: Context) {
    this.context = context
  }

  private async getStore(): Promise<preferences.Preferences> {
    if (!this.store) {
      this.store = await preferences.getPreferences(this.context, Constants.PREFERENCES_BEVERAGES)
    }
    return this.store
  }

  async list(): Promise<Beverage[]> {
    const store = await this.getStore()
    const raw = await store.get('beverages', '') as string
    if (!raw) {
      await this.initDefaults()
      return cloneBeverages(DEFAULT_BEVERAGES)
    }
    if (!validateBeveragesJson(raw)) {
      await this.initDefaults()
      return cloneBeverages(DEFAULT_BEVERAGES)
    }
    return parseJsonArray<Beverage>(raw) ?? cloneBeverages(DEFAULT_BEVERAGES)
  }

  async getActive(): Promise<Beverage[]> {
    const all = await this.list()
    return all.filter(b => b.isActive)
  }

  async save(beverage: Beverage): Promise<void> {
    const beverages = await this.list()
    const index = beverages.findIndex(b => b.id === beverage.id)
    if (index >= 0) {
      beverages[index] = beverage
    } else {
      beverages.push(beverage)
    }
    const store = await this.getStore()
    await store.put('beverages', JSON.stringify(beverages))
    await store.flush()
  }

  async remove(id: string): Promise<void> {
    const beverages = await this.list()
    const filtered = beverages.filter(b => b.id !== id)
    const store = await this.getStore()
    await store.put('beverages', JSON.stringify(filtered))
    await store.flush()
  }

  async replaceAll(beverages: Beverage[]): Promise<void> {
    const store = await this.getStore()
    await store.put('beverages', JSON.stringify(beverages))
    await store.flush()
  }

  async get(id: string): Promise<Beverage | null> {
    const beverages = await this.list()
    return beverages.find(b => b.id === id) ?? null
  }

  private async initDefaults(): Promise<void> {
    const store = await this.getStore()
    await store.put('beverages', JSON.stringify(cloneBeverages(DEFAULT_BEVERAGES)))
    await store.flush()
  }

  async reset(): Promise<void> {
    await this.initDefaults()
  }
}
