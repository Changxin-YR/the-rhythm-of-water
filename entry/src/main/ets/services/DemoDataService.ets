import { DrinkService } from './DrinkService'
import { PlantService } from './PlantService'
import { AchievementService } from './AchievementService'
import { PreferencesService } from './PreferencesService'
import { DrinkRecordPayload } from '../models/DrinkRecord'
import { buildDemoRecords } from '../common/DemoData'
import { Plant } from '../models/Plant'
import { UserProfile } from '../models/UserProfile'

export function shouldSeedDemoData(recordCount: number, profileUpdatedAt: number, plantCount: number): boolean {
  return recordCount === 0 && profileUpdatedAt === 0 && plantCount === 0
}

export function shouldRepairDemoData(recordCount: number, profile: UserProfile, plants: Plant[]): boolean {
  return recordCount === 0 &&
    profile.updatedAt > 0 &&
    profile.dailyGoalMl === 2200 &&
    profile.onboardingCompleted &&
    plants.some((plant: Plant) => plant.name === '我的向日葵')
}

export class DemoDataService {
  private drinkService: DrinkService
  private plantService: PlantService
  private achievementService: AchievementService
  private prefsService: PreferencesService

  constructor(context: Context) {
    this.drinkService = new DrinkService(context)
    this.plantService = new PlantService(context)
    this.achievementService = new AchievementService(context)
    this.prefsService = new PreferencesService(context)
  }

  async ensureSeeded(): Promise<void> {
    const profile = await this.prefsService.getProfile()
    const records = await this.drinkService.getTodayRecords()
    const plants = await this.plantService.getAllPlants()
    const seed = shouldSeedDemoData(records.length, profile.updatedAt, plants.length)
    const repair = shouldRepairDemoData(records.length, profile, plants)
    if (!seed && !repair) return

    const demoRecords = buildDemoRecords(Date.now())
    for (const source of demoRecords) {
      const payload: DrinkRecordPayload = {
        id: source.id,
        beverageId: source.beverageId,
        beverageName: source.beverageName,
        beverageIcon: source.beverageIcon,
        amountMl: source.amountMl,
        hydrationRate: source.amountMl > 0 ? source.hydrationMl / source.amountMl : 1,
        happenedAt: source.happenedAt
      }
      await this.drinkService.addRecord(payload)
    }

    const demoPlant = plants.find((plant: Plant) => plant.name === '我的向日葵')
    if (!demoPlant) {
      await this.plantService.createPlant('sunflower', '我的向日葵')
      await this.plantService.waterPlant(3450)
    } else if (demoPlant.waterReceived < 3450) {
      await this.plantService.waterPlant(3450 - demoPlant.waterReceived)
    }

    profile.dailyGoalMl = 2200
    profile.isGoalAutoCalculated = true
    profile.onboardingCompleted = true
    await this.prefsService.saveProfile(profile)
    await this.achievementService.checkAndUpdate(2200)
  }
}
