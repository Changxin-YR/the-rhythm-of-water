export interface Beverage {
  id: string
  name: string
  icon: string
  hydrationRate: number
  caffeinePerMl: number
  isCustom: boolean
  isActive: boolean
}

export const DEFAULT_BEVERAGES: Beverage[] = [
  { id: 'water', name: '白水', icon: '💧', hydrationRate: 1.0, caffeinePerMl: 0, isCustom: false, isActive: true },
  { id: 'tea', name: '茶', icon: '🍵', hydrationRate: 0.9, caffeinePerMl: 0.03, isCustom: false, isActive: true },
  { id: 'coffee', name: '咖啡', icon: '☕', hydrationRate: 0.8, caffeinePerMl: 0.06, isCustom: false, isActive: true },
  { id: 'milk', name: '牛奶', icon: '🥛', hydrationRate: 0.9, caffeinePerMl: 0, isCustom: false, isActive: true },
  { id: 'juice', name: '果汁', icon: '🧃', hydrationRate: 0.85, caffeinePerMl: 0, isCustom: false, isActive: true },
  { id: 'soup', name: '汤', icon: '🍲', hydrationRate: 0.9, caffeinePerMl: 0, isCustom: false, isActive: true },
  { id: 'sports', name: '运动饮料', icon: '🏃', hydrationRate: 0.95, caffeinePerMl: 0, isCustom: false, isActive: true },
  { id: 'sparkling', name: '气泡水', icon: '✨', hydrationRate: 1.0, caffeinePerMl: 0, isCustom: false, isActive: true },
  { id: 'soda', name: '碳酸饮料', icon: '🥤', hydrationRate: 0.7, caffeinePerMl: 0.01, isCustom: false, isActive: true },
  { id: 'coconut', name: '椰子水', icon: '🥥', hydrationRate: 0.95, caffeinePerMl: 0, isCustom: false, isActive: true }
]

export const BEVERAGE_ICON_OPTIONS: string[] = ['🥤', '🍹', '🧋', '🍺', '🥃', '🫗']

export function cloneBeverages(beverages: Beverage[]): Beverage[] {
  return beverages.map((beverage: Beverage): Beverage => ({
    id: beverage.id,
    name: beverage.name,
    icon: beverage.icon,
    hydrationRate: beverage.hydrationRate,
    caffeinePerMl: beverage.caffeinePerMl,
    isCustom: beverage.isCustom,
    isActive: beverage.isActive
  }))
}
