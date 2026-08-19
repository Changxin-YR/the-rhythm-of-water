import { PlantRepository } from '../repositories/PlantRepository'
import { Plant, PlantSpecies, PlantSpeciesInfo, PLANT_SPECIES_LIST, MAX_GROWTH_STAGE, WILT_DAYS_THRESHOLD } from '../models/Plant'
import { IdGenerator } from '../common/IdGenerator'
import { DateUtils } from '../common/DateUtils'
import { normalizePlantWaterAmount, revertPlantWater } from '../common/PlantRules'

export class PlantService {
  private repository: PlantRepository

  constructor(context: Context) {
    this.repository = new PlantRepository(context)
  }

  async getActivePlant(): Promise<Plant | null> {
    return this.repository.getActive()
  }

  async getGarden(): Promise<Plant[]> {
    return this.repository.getCompleted()
  }

  async getAllPlants(): Promise<Plant[]> {
    return this.repository.list()
  }

  async createPlant(species: PlantSpecies, name: string): Promise<Plant> {
    const speciesInfo = PLANT_SPECIES_LIST.find(s => s.species === species)
    const plant: Plant = {
      id: IdGenerator.generate(),
      species,
      name: name || speciesInfo?.name || '我的植物',
      growthStage: 0,
      waterReceived: 0,
      waterNeeded: speciesInfo?.waterPerStage ?? 3000,
      isActive: true,
      isWilting: false,
      wiltStartDay: null,
      createdAt: Date.now(),
      completedAt: null
    }

    const currentActive = await this.repository.getActive()
    if (currentActive) {
      currentActive.isActive = false
      await this.repository.save(currentActive)
    }

    await this.repository.save(plant)
    return plant
  }

  async waterPlant(amountMl: number): Promise<Plant | null> {
    const plant = await this.repository.getActive()
    if (!plant) return null

    const existingWater = Number.isFinite(plant.waterReceived) && plant.waterReceived > 0
      ? plant.waterReceived
      : 0
    plant.waterReceived = existingWater + normalizePlantWaterAmount(amountMl)
    plant.isWilting = false
    plant.wiltStartDay = null

    const speciesInfo = PLANT_SPECIES_LIST.find(s => s.species === plant.species)
    const waterPerStage = speciesInfo?.waterPerStage ?? 3000
    const newStage = Math.min(MAX_GROWTH_STAGE, Math.floor(plant.waterReceived / waterPerStage))

    if (newStage > plant.growthStage) {
      plant.growthStage = newStage
    }

    if (plant.growthStage >= MAX_GROWTH_STAGE) {
      plant.isActive = false
      plant.completedAt = Date.now()
    }

    await this.repository.save(plant)
    return plant
  }

  async removeWater(amountMl: number): Promise<Plant | null> {
    const plants = await this.repository.list()
    const completed = plants
      .filter(p => !p.isActive && p.completedAt !== null)
      .sort((a, b) => (b.completedAt ?? 0) - (a.completedAt ?? 0))
    const plant = plants.find(p => p.isActive) ?? completed[0]
    if (!plant) return null

    const reverted = revertPlantWater(plant, amountMl)
    await this.repository.save(reverted)
    return reverted
  }

  async checkWilting(consecutiveMissedDays: number): Promise<void> {
    const plant = await this.repository.getActive()
    if (!plant) return

    if (consecutiveMissedDays >= WILT_DAYS_THRESHOLD) {
      plant.isWilting = true
      if (!plant.wiltStartDay) {
        plant.wiltStartDay = DateUtils.getToday()
      }
      await this.repository.save(plant)
    }
  }

  async reset(): Promise<void> {
    await this.repository.clear()
  }

  getSpeciesList(): PlantSpeciesInfo[] {
    return PLANT_SPECIES_LIST.slice()
  }
}
