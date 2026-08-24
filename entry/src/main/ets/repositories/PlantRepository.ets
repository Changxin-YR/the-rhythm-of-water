import { preferences } from '@kit.ArkData'
import { Plant } from '../models/Plant'
import { Constants } from '../common/Constants'
import { parseJsonArray } from '../common/JsonUtils'
import { validatePlantsJson } from '../common/BackupRules'

export class PlantRepository {
  private store: preferences.Preferences | null = null
  private context: Context

  constructor(context: Context) {
    this.context = context
  }

  private async getStore(): Promise<preferences.Preferences> {
    if (!this.store) {
      this.store = await preferences.getPreferences(this.context, Constants.STORE_PLANTS)
    }
    return this.store
  }

  async list(): Promise<Plant[]> {
    const store = await this.getStore()
    const raw = await store.get('plants', '[]') as string
    if (!validatePlantsJson(raw)) {
      await store.put('plants', '[]')
      await store.flush()
      return []
    }
    return parseJsonArray<Plant>(raw) ?? []
  }

  async getActive(): Promise<Plant | null> {
    const plants = await this.list()
    return plants.find(p => p.isActive) ?? null
  }

  async getCompleted(): Promise<Plant[]> {
    const plants = await this.list()
    return plants.filter(p => !p.isActive && p.completedAt !== null)
  }

  async save(plant: Plant): Promise<void> {
    const plants = await this.list()
    const index = plants.findIndex(p => p.id === plant.id)
    if (index >= 0) {
      plants[index] = plant
    } else {
      plants.push(plant)
    }
    const store = await this.getStore()
    await store.put('plants', JSON.stringify(plants))
    await store.flush()
  }

  async remove(id: string): Promise<void> {
    const plants = await this.list()
    const filtered = plants.filter(p => p.id !== id)
    const store = await this.getStore()
    await store.put('plants', JSON.stringify(filtered))
    await store.flush()
  }

  async clear(): Promise<void> {
    const store = await this.getStore()
    await store.put('plants', '[]')
    await store.flush()
  }

  async replaceAll(plants: Plant[]): Promise<void> {
    const store = await this.getStore()
    await store.put('plants', JSON.stringify(plants))
    await store.flush()
  }
}
