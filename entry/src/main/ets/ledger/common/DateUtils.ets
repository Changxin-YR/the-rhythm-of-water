import intl from '@ohos.intl';

export interface DateRange {
  start: string;
  end: string;
}

export class DateUtils {
  static formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = DateUtils.padZero(date.getMonth() + 1);
    const day = DateUtils.padZero(date.getDate());
    return `${year}-${month}-${day}`;
  }

  static formatDisplayDate(dateStr: string): string {
    const date = DateUtils.parseLocalDate(dateStr);
    if (!date) {
      return dateStr;
    }
    const formatter = new intl.DateTimeFormat('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
    return formatter.format(date);
  }

  static formatMonthDisplay(year: number, month: number): string {
    const formatter = new intl.DateTimeFormat('zh-CN', {
      year: 'numeric',
      month: 'long'
    });
    return formatter.format(new Date(year, month - 1, 1));
  }

  static getToday(): string {
    return DateUtils.formatDate(new Date());
  }

  static getMonthRange(year: number, month: number): DateRange {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0);
    return {
      start: DateUtils.formatDate(startDate),
      end: DateUtils.formatDate(endDate)
    };
  }

  static getDayOfWeek(dateStr: string): string {
    const date = DateUtils.parseLocalDate(dateStr);
    if (!date) {
      return '';
    }
    const formatter = new intl.DateTimeFormat('zh-CN', { weekday: 'short' });
    return formatter.format(date);
  }

  static isToday(dateStr: string): boolean {
    return dateStr === DateUtils.getToday();
  }

  static isYesterday(dateStr: string): boolean {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return dateStr === DateUtils.formatDate(yesterday);
  }

  static getRelativeDate(dateStr: string): string {
    const relativeFormatter = new intl.RelativeTimeFormat('zh-CN', { numeric: 'auto' });
    if (DateUtils.isToday(dateStr)) {
      return relativeFormatter.format(0, 'day');
    }
    if (DateUtils.isYesterday(dateStr)) {
      return relativeFormatter.format(-1, 'day');
    }
    return DateUtils.formatDisplayDate(dateStr);
  }

  static getCurrentYear(): number {
    return new Date().getFullYear();
  }

  static getCurrentMonth(): number {
    return new Date().getMonth() + 1;
  }

  private static parseLocalDate(dateStr: string): Date | null {
    const parts = dateStr.split('-');
    if (parts.length !== 3) {
      return null;
    }
    const year = parseInt(parts[0]);
    const month = parseInt(parts[1]);
    const day = parseInt(parts[2]);
    const date = new Date(year, month - 1, day);
    if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) {
      return null;
    }
    return date;
  }

  private static padZero(num: number): string {
    return num < 10 ? `0${num}` : `${num}`;
  }
}
