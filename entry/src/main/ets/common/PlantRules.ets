import { Plant, PLANT_SPECIES_LIST, MAX_GROWTH_STAGE } from '../models/Plant'

export function normalizePlantWaterAmount(amountMl: number): number {
  return Number.isFinite(amountMl) && amountMl > 0 ? amountMl : 0
}

export function revertPlantWater(plant: Plant, amountMl: number): Plant {
  const safeAmount = normalizePlantWaterAmount(amountMl)
  const existingWater = Number.isFinite(plant.waterReceived) && plant.waterReceived > 0
    ? plant.waterReceived
    : 0
  const speciesInfo = PLANT_SPECIES_LIST.find(s => s.species === plant.species)
  const waterPerStage = speciesInfo?.waterPerStage ?? 3000
  const waterReceived = Math.max(0, existingWater - safeAmount)
  const growthStage = Math.min(MAX_GROWTH_STAGE, Math.floor(waterReceived / waterPerStage))

  const reverted: Plant = {
    id: plant.id,
    species: plant.species,
    name: plant.name,
    growthStage,
    waterReceived,
    waterNeeded: waterPerStage,
    isActive: growthStage < MAX_GROWTH_STAGE,
    isWilting: growthStage < MAX_GROWTH_STAGE ? false : plant.isWilting,
    wiltStartDay: growthStage < MAX_GROWTH_STAGE ? null : plant.wiltStartDay,
    createdAt: plant.createdAt,
    completedAt: growthStage < MAX_GROWTH_STAGE ? null : plant.completedAt
  }
  return reverted
}
