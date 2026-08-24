import { preferences } from '@kit.ArkData'
import { UserProfile, DEFAULT_PROFILE, cloneUserProfile } from '../models/UserProfile'
import { AppSettings, DEFAULT_APP_SETTINGS, cloneAppSettings } from '../common/Theme'
import { Constants } from '../common/Constants'
import { parseJsonObject, parseJsonArray } from '../common/JsonUtils'
import {
  validateAppSettingsJson,
  validateUserProfileJson
} from '../common/BackupRules'

export class PreferencesService {
  private context: Context
  private profileStore: preferences.Preferences | null = null
  private settingsStore: preferences.Preferences | null = null

  constructor(context: Context) {
    this.context = context
  }

  private async getProfileStore(): Promise<preferences.Preferences> {
    if (!this.profileStore) {
      this.profileStore = await preferences.getPreferences(this.context, Constants.PREFERENCES_USER_PROFILE)
    }
    return this.profileStore
  }

  private async getSettingsStore(): Promise<preferences.Preferences> {
    if (!this.settingsStore) {
      this.settingsStore = await preferences.getPreferences(this.context, Constants.PREFERENCES_APP_SETTINGS)
    }
    return this.settingsStore
  }

  // User Profile
  async getProfile(): Promise<UserProfile> {
    const store = await this.getProfileStore()
    const raw = await store.get('profile', '') as string
    if (!raw) return cloneUserProfile(DEFAULT_PROFILE)
    if (!validateUserProfileJson(raw)) {
      const fallback = cloneUserProfile(DEFAULT_PROFILE)
      await store.put('profile', JSON.stringify(fallback))
      await store.flush()
      return fallback
    }
    const profile = parseJsonObject<UserProfile>(raw)
    return profile ? cloneUserProfile(profile) : cloneUserProfile(DEFAULT_PROFILE)
  }

  async saveProfile(profile: UserProfile): Promise<void> {
    profile.updatedAt = Date.now()
    const store = await this.getProfileStore()
    await store.put('profile', JSON.stringify(cloneUserProfile(profile)))
    await store.flush()
  }

  // App Settings
  async getSettings(): Promise<AppSettings> {
    const store = await this.getSettingsStore()
    const raw = await store.get('settings', '') as string
    if (!raw) return cloneAppSettings(DEFAULT_APP_SETTINGS)
    if (!validateAppSettingsJson(raw)) {
      const fallback = cloneAppSettings(DEFAULT_APP_SETTINGS)
      await store.put('settings', JSON.stringify(fallback))
      await store.flush()
      return fallback
    }
    return cloneAppSettings(parseJsonObject<AppSettings>(raw) ?? DEFAULT_APP_SETTINGS)
  }

  async saveSettings(settings: AppSettings): Promise<void> {
    const store = await this.getSettingsStore()
    await store.put('settings', JSON.stringify(settings))
    await store.flush()
  }

  async resetAll(): Promise<void> {
    const profileStore = await this.getProfileStore()
    const settingsStore = await this.getSettingsStore()
    await profileStore.clear()
    await settingsStore.clear()
    await profileStore.flush()
    await settingsStore.flush()
  }
}
