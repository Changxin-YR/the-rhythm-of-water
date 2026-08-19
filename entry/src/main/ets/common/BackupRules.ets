import { parseJsonArray, parseJsonObject } from './JsonUtils'
import { Constants } from './Constants'

interface RawBackupPayload {
  version: number
  records: string
  profile: string
  settings: string
  beverages: string
  cups?: string
  achievements: string
  plants: string
  ledgerBills?: string
  ledgerCategories?: string
  ledgerBudgets?: string
}

export type JsonObject = Record<string, Object>

export function buildBackupFileName(timestamp: number): string {
  if (!Number.isFinite(timestamp) || timestamp < 0) return 'yuanqiyoushu_backup.json'
  return `yuanqiyoushu_backup_${Math.floor(timestamp)}.json`
}

function asObject(value: Object): JsonObject | null {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) return null
  return value as JsonObject
}

function isFiniteNumber(value: Object | undefined): boolean {
  return typeof value === 'number' && Number.isFinite(value as number)
}

function isNonNegativeNumber(value: Object | undefined): boolean {
  return isFiniteNumber(value) && (value as number) >= 0
}

function isPositiveNumber(value: Object | undefined): boolean {
  return isFiniteNumber(value) && (value as number) > 0
}

function isString(value: Object | undefined): boolean {
  return typeof value === 'string'
}

function isBoolean(value: Object | undefined): boolean {
  return typeof value === 'boolean'
}

function isOneOf(value: Object | undefined, values: string[]): boolean {
  return typeof value === 'string' && values.indexOf(value as string) >= 0
}

function isValidDrinkRecord(record: JsonObject): boolean {
  return isString(record.id) && (record.id as string).length > 0 &&
    isString(record.beverageId) && isString(record.beverageName) && isString(record.beverageIcon) &&
    isNonNegativeNumber(record.amountMl) && isNonNegativeNumber(record.hydrationMl) &&
    isNonNegativeNumber(record.happenedAt) && isNonNegativeNumber(record.createdAt) &&
    isNonNegativeNumber(record.updatedAt)
}

export function validateDrinkRecords(jsonStr: string): boolean {
  const records = parseJsonArray<Object>(jsonStr)
  if (!records) return false
  for (const item of records) {
    const record = asObject(item)
    if (!record || !isValidDrinkRecord(record)) return false
  }
  return true
}

export function isValidUserProfile(profile: JsonObject): boolean {
  const avatarIsValid = profile.avatarId === undefined || isString(profile.avatarId)
  return avatarIsValid && isString(profile.nickname) && isPositiveNumber(profile.weightKg) &&
    isOneOf(profile.activityLevel, ['sedentary', 'light', 'moderate', 'active', 'athlete']) &&
    isOneOf(profile.specialState, ['none', 'pregnant', 'breastfeeding', 'sick']) &&
    isOneOf(profile.climate, ['normal', 'hot', 'dry']) &&
    isPositiveNumber(profile.dailyGoalMl) && isBoolean(profile.isGoalAutoCalculated) &&
    isBoolean(profile.onboardingCompleted) && isNonNegativeNumber(profile.createdAt) &&
    isNonNegativeNumber(profile.updatedAt)
}

export function isValidAppSettings(settings: JsonObject): boolean {
  return isOneOf(settings.themeMode, ['system', 'light', 'dark']) &&
    isOneOf(settings.themeColor, ['blue', 'green', 'purple', 'orange', 'pink', 'teal']) &&
    isOneOf(settings.unit, ['ml', 'oz']) && isFiniteNumber(settings.dailyResetHour) &&
    Number.isInteger(settings.dailyResetHour as number) &&
    (settings.dailyResetHour as number) >= 0 && (settings.dailyResetHour as number) <= 23 &&
    isPositiveNumber(settings.schemaVersion)
}

function isValidBeverage(beverage: JsonObject): boolean {
  return isString(beverage.id) && (beverage.id as string).length > 0 &&
    isString(beverage.name) && isString(beverage.icon) &&
    isNonNegativeNumber(beverage.hydrationRate) && (beverage.hydrationRate as number) <= 1 &&
    isNonNegativeNumber(beverage.caffeinePerMl) && isBoolean(beverage.isCustom) &&
    isBoolean(beverage.isActive)
}

function isValidAchievement(achievement: JsonObject): boolean {
  return isString(achievement.id) && (achievement.id as string).length > 0 &&
    isString(achievement.title) && isString(achievement.description) &&
    isString(achievement.icon) &&
    isOneOf(achievement.category, ['streak', 'volume', 'consistency', 'milestone']) &&
    isPositiveNumber(achievement.targetValue) && isNonNegativeNumber(achievement.currentValue) &&
    isFiniteNumber(achievement.progress) && (achievement.progress as number) >= 0 &&
    (achievement.progress as number) <= 100 &&
    (achievement.unlockedAt === null || isNonNegativeNumber(achievement.unlockedAt))
}

function isValidPlant(plant: JsonObject): boolean {
  return isString(plant.id) && (plant.id as string).length > 0 && isString(plant.species) &&
    isOneOf(plant.species, ['sunflower', 'lavender', 'cactus', 'succulent', 'mint', 'sakura']) &&
    isString(plant.name) && isFiniteNumber(plant.growthStage) &&
    Number.isInteger(plant.growthStage as number) && (plant.growthStage as number) >= 0 &&
    (plant.growthStage as number) <= 5 && isNonNegativeNumber(plant.waterReceived) &&
    isPositiveNumber(plant.waterNeeded) && isBoolean(plant.isActive) &&
    isBoolean(plant.isWilting) && (plant.wiltStartDay === null || isString(plant.wiltStartDay)) &&
    isNonNegativeNumber(plant.createdAt) &&
    (plant.completedAt === null || isNonNegativeNumber(plant.completedAt))
}

function isValidBillType(value: Object | undefined): boolean {
  return value === 0 || value === 1
}

function isValidLedgerBill(bill: JsonObject): boolean {
  return isString(bill.id) && (bill.id as string).length > 0 &&
    isNonNegativeNumber(bill.amount) && isValidBillType(bill.type) &&
    isString(bill.categoryId) && (bill.categoryId as string).length > 0 &&
    isString(bill.note) && isString(bill.date) && (bill.date as string).length > 0 &&
    isNonNegativeNumber(bill.createTime)
}

function isValidLedgerCategory(category: JsonObject): boolean {
  return isString(category.id) && (category.id as string).length > 0 &&
    isString(category.name) && isString(category.icon) && isValidBillType(category.type) &&
    isBoolean(category.isCustom) && isNonNegativeNumber(category.sortOrder) &&
    Number.isInteger(category.sortOrder as number) && isString(category.color)
}

function isValidLedgerBudget(budget: JsonObject): boolean {
  return isFiniteNumber(budget.year) && Number.isInteger(budget.year as number) &&
    (budget.year as number) > 0 && isFiniteNumber(budget.month) &&
    Number.isInteger(budget.month as number) && (budget.month as number) >= 1 &&
    (budget.month as number) <= 12 && isNonNegativeNumber(budget.amount)
}

export function validateUserProfileJson(jsonStr: string): boolean {
  return isValidObjectString(jsonStr, isValidUserProfile)
}

export function validateAppSettingsJson(jsonStr: string): boolean {
  return isValidObjectString(jsonStr, isValidAppSettings)
}

export function validateBeveragesJson(jsonStr: string): boolean {
  return isValidObjectArray(jsonStr, isValidBeverage)
}

export function validateAchievementsJson(jsonStr: string): boolean {
  return isValidObjectArray(jsonStr, isValidAchievement)
}

export function validatePlantsJson(jsonStr: string): boolean {
  return isValidObjectArray(jsonStr, isValidPlant)
}

export function validateLedgerBillsJson(jsonStr: string): boolean {
  return isValidObjectArray(jsonStr, isValidLedgerBill)
}

export function validateLedgerCategoriesJson(jsonStr: string): boolean {
  return isValidObjectArray(jsonStr, isValidLedgerCategory)
}

export function validateLedgerBudgetsJson(jsonStr: string): boolean {
  return isValidObjectArray(jsonStr, isValidLedgerBudget)
}

function isValidObjectString(jsonStr: string, validator: (value: JsonObject) => boolean): boolean {
  const parsed = parseJsonObject<Object>(jsonStr)
  const object = parsed === null ? null : asObject(parsed)
  return object !== null && validator(object)
}

function isValidObjectArray(jsonStr: string, validator: (value: JsonObject) => boolean): boolean {
  const parsed = parseJsonArray<Object>(jsonStr)
  if (!parsed) return false
  for (const item of parsed) {
    const object = asObject(item)
    if (!object || !validator(object)) return false
  }
  return true
}

export function validateBackupPayload(jsonStr: string): boolean {
  const backup = parseJsonObject<RawBackupPayload>(jsonStr)
  if (!backup || !Number.isFinite(backup.version) || !Number.isInteger(backup.version) ||
    backup.version !== Constants.SCHEMA_VERSION ||
    typeof backup.records !== 'string' || typeof backup.profile !== 'string' ||
    typeof backup.settings !== 'string' || typeof backup.beverages !== 'string' ||
    (backup.cups !== undefined && typeof backup.cups !== 'string') ||
    typeof backup.achievements !== 'string' || typeof backup.plants !== 'string') {
    return false
  }

  const hasLedgerBackup = backup.ledgerBills !== undefined || backup.ledgerCategories !== undefined ||
    backup.ledgerBudgets !== undefined
  if (hasLedgerBackup && (typeof backup.ledgerBills !== 'string' ||
    typeof backup.ledgerCategories !== 'string' || typeof backup.ledgerBudgets !== 'string')) {
    return false
  }

  return validateDrinkRecords(backup.records) &&
    validateUserProfileJson(backup.profile) && validateAppSettingsJson(backup.settings) &&
    validateBeveragesJson(backup.beverages) &&
    validateAchievementsJson(backup.achievements) &&
    validatePlantsJson(backup.plants) &&
    (!hasLedgerBackup || (validateLedgerBillsJson(backup.ledgerBills as string) &&
      validateLedgerCategoriesJson(backup.ledgerCategories as string) &&
      validateLedgerBudgetsJson(backup.ledgerBudgets as string)))
}
