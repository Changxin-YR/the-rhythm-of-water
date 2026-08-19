import { DrinkRecord } from '../models/DrinkRecord'
import { Plant } from '../models/Plant'

function atLocalTime(now: number, hour: number, minute: number): number {
  const date = new Date(now)
  date.setHours(hour, minute, 0, 0)
  return date.getTime()
}

export function buildDemoRecords(now: number): DrinkRecord[] {
  const earlyTime = atLocalTime(now, 5, 56)
  const lateTime = atLocalTime(now, 6, 18)
  return [
    {
      id: 'demo-record-early',
      beverageId: 'water',
      beverageName: '白水',
      beverageIcon: '💧',
      amountMl: 600,
      hydrationMl: 600,
      happenedAt: earlyTime,
      createdAt: earlyTime,
      updatedAt: earlyTime
    },
    {
      id: 'demo-record-late',
      beverageId: 'water',
      beverageName: '白水',
      beverageIcon: '💧',
      amountMl: 250,
      hydrationMl: 250,
      happenedAt: lateTime,
      createdAt: lateTime,
      updatedAt: lateTime
    }
  ]
}

export function buildDemoPlant(now: number): Plant {
  return {
    id: 'demo-plant-sunflower',
    species: 'sunflower',
    name: '我的向日葵',
    growthStage: 1,
    waterReceived: 3450,
    waterNeeded: 3000,
    isActive: true,
    isWilting: false,
    wiltStartDay: null,
    createdAt: now,
    completedAt: null
  }
}
