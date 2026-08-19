import { preferences } from '@kit.ArkData'
import { Achievement, ACHIEVEMENT_DEFINITIONS, cloneAchievements } from '../models/Achievement'
import { Constants } from '../common/Constants'
import { parseJsonArray } from '../common/JsonUtils'
import { validateAchievementsJson } from '../common/BackupRules'

export class AchievementRepository {
  private store: preferences.Preferences | null = null
  private context: Context

  constructor(context: Context) {
    this.context = context
  }

  private async getStore(): Promise<preferences.Preferences> {
    if (!this.store) {
      this.store = await preferences.getPreferences(this.context, Constants.STORE_ACHIEVEMENTS)
    }
    return this.store
  }

  async list(): Promise<Achievement[]> {
    const store = await this.getStore()
    const raw = await store.get('achievements', '') as string
    if (!raw) {
      await this.initDefaults()
      return cloneAchievements(ACHIEVEMENT_DEFINITIONS)
    }
    if (!validateAchievementsJson(raw)) {
      await this.initDefaults()
      return cloneAchievements(ACHIEVEMENT_DEFINITIONS)
    }
    return parseJsonArray<Achievement>(raw) ?? cloneAchievements(ACHIEVEMENT_DEFINITIONS)
  }

  async save(achievement: Achievement): Promise<void> {
    const achievements = await this.list()
    const index = achievements.findIndex(a => a.id === achievement.id)
    if (index >= 0) {
      achievements[index] = achievement
    } else {
      achievements.push(achievement)
    }
    const store = await this.getStore()
    await store.put('achievements', JSON.stringify(achievements))
    await store.flush()
  }

  async saveAll(achievements: Achievement[]): Promise<void> {
    const store = await this.getStore()
    await store.put('achievements', JSON.stringify(achievements))
    await store.flush()
  }

  async get(id: string): Promise<Achievement | null> {
    const achievements = await this.list()
    return achievements.find(a => a.id === id) ?? null
  }

  async getUnlocked(): Promise<Achievement[]> {
    const achievements = await this.list()
    return achievements.filter(a => a.unlockedAt !== null)
  }

  private async initDefaults(): Promise<void> {
    const store = await this.getStore()
    await store.put('achievements', JSON.stringify(cloneAchievements(ACHIEVEMENT_DEFINITIONS)))
    await store.flush()
  }

  async reset(): Promise<void> {
    await this.initDefaults()
  }
}
