export interface Plant {
  id: string
  species: PlantSpecies
  name: string
  growthStage: number
  waterReceived: number
  waterNeeded: number
  isActive: boolean
  isWilting: boolean
  wiltStartDay: string | null
  createdAt: number
  completedAt: number | null
}

export type PlantSpecies = 'sunflower' | 'lavender' | 'cactus' | 'succulent' | 'mint' | 'sakura'

export interface PlantSpeciesInfo {
  species: PlantSpecies
  name: string
  icon: string
  stageIcons: string[]
  waterPerStage: number
}

export const PLANT_SPECIES_LIST: PlantSpeciesInfo[] = [
  {
    species: 'sunflower',
    name: '向日葵',
    icon: '🌻',
    stageIcons: ['🫘', '🌱', '🪴', '🌿', '🌼', '🌻'],
    waterPerStage: 3000
  },
  {
    species: 'lavender',
    name: '薰衣草',
    icon: '💜',
    stageIcons: ['🫘', '🌱', '🪴', '🌿', '💐', '💜'],
    waterPerStage: 2500
  },
  {
    species: 'cactus',
    name: '仙人掌',
    icon: '🌵',
    stageIcons: ['🫘', '🌱', '🪴', '🌿', '🌵', '🏜️'],
    waterPerStage: 2000
  },
  {
    species: 'succulent',
    name: '多肉',
    icon: '🪴',
    stageIcons: ['🫘', '🌱', '🌿', '🪴', '🍀', '🌺'],
    waterPerStage: 2000
  },
  {
    species: 'mint',
    name: '薄荷',
    icon: '🌿',
    stageIcons: ['🫘', '🌱', '☘️', '🌿', '🍃', '🌿'],
    waterPerStage: 2500
  },
  {
    species: 'sakura',
    name: '樱花树',
    icon: '🌸',
    stageIcons: ['🫘', '🌱', '🪴', '🌳', '🌸', '🎋'],
    waterPerStage: 4000
  }
]

export const MAX_GROWTH_STAGE = 5
export const WILT_DAYS_THRESHOLD = 3
