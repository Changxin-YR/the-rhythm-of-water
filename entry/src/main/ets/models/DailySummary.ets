export interface DailySummary {
  date: string
  totalMl: number
  hydrationMl: number
  goalMl: number
  completionRate: number
  recordCount: number
  beverageBreakdown: Record<string, number>
  streakDay: number
}

export interface WeeklyStats {
  days: DailySummary[]
  avgMl: number
  goalDays: number
  totalDays: number
}

export interface MonthlyStats {
  days: DailySummary[]
  avgMl: number
  goalDays: number
  totalDays: number
}

export interface PeriodBreakdown {
  morning: number
  afternoon: number
  evening: number
}
