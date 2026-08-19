export class DateUtils {
  static getToday(): string {
    const now = new Date()
    return DateUtils.formatDate(now)
  }

  static formatDate(date: Date): string {
    const y = date.getFullYear()
    const m = String(date.getMonth() + 1).padStart(2, '0')
    const d = String(date.getDate()).padStart(2, '0')
    return `${y}-${m}-${d}`
  }

  static parseLocalDate(dateStr: string): Date | null {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateStr)
    if (!match) return null

    const year = Number(match[1])
    const month = Number(match[2])
    const day = Number(match[3])
    const date = new Date(year, month - 1, day)
    if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) {
      return null
    }
    return date
  }

  static formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const h = String(date.getHours()).padStart(2, '0')
    const m = String(date.getMinutes()).padStart(2, '0')
    return `${h}:${m}`
  }

  static formatDateTime(timestamp: number): string {
    const date = new Date(timestamp)
    return `${DateUtils.formatDate(date)} ${DateUtils.formatTime(timestamp)}`
  }

  static getWeekday(date: Date): string {
    const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    return days[date.getDay()]
  }

  static getWeekdayToday(): string {
    return DateUtils.getWeekday(new Date())
  }

  static getStartOfDay(date: Date): number {
    const d = new Date(date.getFullYear(), date.getMonth(), date.getDate())
    return d.getTime()
  }

  static getEndOfDay(date: Date): number {
    const d = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59, 999)
    return d.getTime()
  }

  static getDaysAgo(days: number): Date {
    const d = new Date()
    d.setDate(d.getDate() - days)
    return d
  }

  static getDateRange(startDate: Date, endDate: Date): string[] {
    const dates: string[] = []
    const current = new Date(startDate)
    while (current <= endDate) {
      dates.push(DateUtils.formatDate(current))
      current.setDate(current.getDate() + 1)
    }
    return dates
  }

  static getWeekStart(date: Date): Date {
    const d = new Date(date)
    const day = d.getDay()
    const diff = day === 0 ? 6 : day - 1
    d.setDate(d.getDate() - diff)
    return new Date(d.getFullYear(), d.getMonth(), d.getDate())
  }

  static getMonthStart(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), 1)
  }

  static getYearStart(date: Date): Date {
    return new Date(date.getFullYear(), 0, 1)
  }

  static isToday(dateStr: string): boolean {
    return dateStr === DateUtils.getToday()
  }

  static isWeekend(date: Date): boolean {
    const day = date.getDay()
    return day === 0 || day === 6
  }

  static daysBetween(date1: string, date2: string): number {
    const first = DateUtils.parseLocalDate(date1)
    const second = DateUtils.parseLocalDate(date2)
    if (!first || !second) return 0
    const d1 = first.getTime()
    const d2 = second.getTime()
    return Math.round(Math.abs(d2 - d1) / (1000 * 60 * 60 * 24))
  }

  static getPeriod(timestamp: number): 'morning' | 'afternoon' | 'evening' {
    const hour = new Date(timestamp).getHours()
    if (hour < 12) return 'morning'
    if (hour < 18) return 'afternoon'
    return 'evening'
  }
}
