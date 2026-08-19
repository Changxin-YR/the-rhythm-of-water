import { fileIo } from '@kit.CoreFileKit'
import { util } from '@kit.ArkTS'
import { DrinkService } from './DrinkService'
import { PreferencesService } from './PreferencesService'
import { AchievementService } from './AchievementService'
import { PlantService } from './PlantService'
import { BeverageRepository } from '../repositories/BeverageRepository'
import { PlantRepository } from '../repositories/PlantRepository'
import { AchievementRepository } from '../repositories/AchievementRepository'
import { Beverage } from '../models/Beverage'
import { Achievement } from '../models/Achievement'
import { Plant } from '../models/Plant'
import { DrinkRecord } from '../models/DrinkRecord'
import { UserProfile } from '../models/UserProfile'
import { BillRecord } from '../ledger/models/BillRecord'
import { Category } from '../ledger/models/Category'
import { AppSettings } from '../common/Theme'
import { parseJsonArray, parseJsonObject } from '../common/JsonUtils'
import { validateBackupPayload } from '../common/BackupRules'
import { Constants } from '../common/Constants'
import { DatabaseHelper, LedgerBackupData, LedgerBudget } from '../ledger/services/DatabaseHelper'

export interface BackupData {
  version: number
  exportedAt: number
  records: string
  profile: string
  settings: string
  beverages: string
  achievements: string
  plants: string
  ledgerBills?: string
  ledgerCategories?: string
  ledgerBudgets?: string
}

export class BackupService {
  private context: Context
  private drinkService: DrinkService
  private prefsService: PreferencesService
  private achievementService: AchievementService
  private plantService: PlantService
  private beverageRepo: BeverageRepository
  private plantRepo: PlantRepository
  private achievementRepo: AchievementRepository

  constructor(context: Context) {
    this.context = context
    this.drinkService = new DrinkService(context)
    this.prefsService = new PreferencesService(context)
    this.achievementService = new AchievementService(context)
    this.plantService = new PlantService(context)
    this.beverageRepo = new BeverageRepository(context)
    this.plantRepo = new PlantRepository(context)
    this.achievementRepo = new AchievementRepository(context)
  }

  async exportData(): Promise<string> {
    const records = await this.drinkService.exportData()
    const profile = JSON.stringify(await this.prefsService.getProfile())
    const settings = JSON.stringify(await this.prefsService.getSettings())
    const beverages = JSON.stringify(await this.beverageRepo.list())
    const achievements = JSON.stringify(await this.achievementRepo.list())
    const plants = JSON.stringify(await this.plantRepo.list())
    const ledger = await DatabaseHelper.getInstance().exportLedgerData()

    const backup: BackupData = {
      version: Constants.SCHEMA_VERSION,
      exportedAt: Date.now(),
      records,
      profile,
      settings,
      beverages,
      achievements,
      plants,
      ledgerBills: JSON.stringify(ledger.bills),
      ledgerCategories: JSON.stringify(ledger.categories),
      ledgerBudgets: JSON.stringify(ledger.budgets)
    }

    return JSON.stringify(backup, null, 2)
  }

  async writeToFile(fileUri: string, content: string): Promise<void> {
    let fd = -1
    try {
      const file = fileIo.openSync(
        fileUri,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC
      )
      fd = file.fd
      fileIo.writeSync(fd, content)
    } finally {
      if (fd >= 0) {
        try {
          fileIo.closeSync(fd)
        } catch (e) {
          console.error('BackupService: failed to close export file', JSON.stringify(e))
        }
      }
    }
  }

  async importFromFile(filePath: string): Promise<boolean> {
    let fd = -1
    try {
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
      fd = file.fd
      const stat = fileIo.statSync(filePath)
      const buffer = new ArrayBuffer(stat.size)
      fileIo.readSync(fd, buffer)

      const decoder = new util.TextDecoder()
      const content = decoder.decodeToString(new Uint8Array(buffer))
      return this.importData(content)
    } catch (e) {
      console.error('BackupService: import failed', JSON.stringify(e))
      return false
    } finally {
      if (fd >= 0) {
        try {
          fileIo.closeSync(fd)
        } catch (e) {
          console.error('BackupService: failed to close import file', JSON.stringify(e))
        }
      }
    }
  }

  async importData(jsonStr: string): Promise<boolean> {
    try {
      if (!validateBackupPayload(jsonStr)) return false
      const backup = parseJsonObject<BackupData>(jsonStr)
      if (!backup || !Number.isFinite(backup.version) || backup.version < 1 || !backup.records) return false

      const records = parseJsonArray<DrinkRecord>(backup.records)
      if (!records) return false

      const profile = backup.profile ? parseJsonObject<UserProfile>(backup.profile) : null
      if (backup.profile && !profile) return false

      const settings = backup.settings ? parseJsonObject<AppSettings>(backup.settings) : null
      if (backup.settings && !settings) return false

      let beverages: Beverage[] | null = null
      if (backup.beverages) {
        beverages = parseJsonArray<Beverage>(backup.beverages)
        if (!beverages) return false
      }

      let achievements: Achievement[] | null = null
      if (backup.achievements) {
        achievements = parseJsonArray<Achievement>(backup.achievements)
        if (!achievements) return false
      }

      let plants: Plant[] | null = null
      if (backup.plants) {
        plants = parseJsonArray<Plant>(backup.plants)
        if (!plants) return false
      }

      let ledger: LedgerBackupData | null = null
      if (backup.ledgerBills !== undefined || backup.ledgerCategories !== undefined ||
        backup.ledgerBudgets !== undefined) {
        if (backup.ledgerBills === undefined || backup.ledgerCategories === undefined ||
          backup.ledgerBudgets === undefined) return false
        const bills = parseJsonArray<BillRecord>(backup.ledgerBills)
        const categories = parseJsonArray<Category>(backup.ledgerCategories)
        const budgets = parseJsonArray<LedgerBudget>(backup.ledgerBudgets)
        if (!bills || !categories || !budgets) return false
        ledger = { bills, categories, budgets }
      }

      const importedCount = await this.drinkService.importData(JSON.stringify(records))
      if (importedCount !== records.length) return false

      if (profile) {
        await this.prefsService.saveProfile(profile)
      }
      if (settings) {
        await this.prefsService.saveSettings(settings)
      }
      if (beverages) {
        await this.beverageRepo.replaceAll(beverages)
      }
      if (achievements) {
        await this.achievementRepo.saveAll(achievements)
      }
      if (plants) {
        await this.plantRepo.replaceAll(plants)
      }
      if (ledger) {
        await DatabaseHelper.getInstance().restoreLedgerData(ledger)
      }

      return true
    } catch (e) {
      console.error('BackupService: import parsing failed', JSON.stringify(e))
      return false
    }
  }

  async resetAll(): Promise<void> {
    await this.drinkService.clearAll()
    await DatabaseHelper.getInstance().resetAll(this.context)
    await this.achievementService.reset()
    await this.plantService.reset()
    await this.prefsService.resetAll()
    await this.beverageRepo.reset()
  }
}
