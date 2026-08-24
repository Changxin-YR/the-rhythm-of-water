export interface DrinkRecord {
  id: string
  beverageId: string
  beverageName: string
  beverageIcon: string
  amountMl: number
  hydrationMl: number
  happenedAt: number
  createdAt: number
  updatedAt: number
}

export interface DrinkRecordPayload {
  id?: string
  beverageId: string
  beverageName: string
  beverageIcon: string
  amountMl: number
  hydrationRate: number
  happenedAt: number
}
