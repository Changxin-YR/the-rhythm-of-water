export interface Achievement {
  id: string
  title: string
  description: string
  icon: string
  category: AchievementCategory
  targetValue: number
  currentValue: number
  progress: number
  unlockedAt: number | null
}

export type AchievementCategory = 'streak' | 'volume' | 'consistency' | 'milestone'

export const ACHIEVEMENT_DEFINITIONS: Achievement[] = [
  { id: 'first_drink', title: '第一口水', description: '记录第一杯水', icon: '🌱', category: 'milestone', targetValue: 1, currentValue: 0, progress: 0, unlockedAt: null },
  { id: 'first_goal', title: '初次达标', description: '首次完成每日饮水目标', icon: '🎯', category: 'milestone', targetValue: 1, currentValue: 0, progress: 0, unlockedAt: null },
  { id: 'streak_7', title: '一周坚持', description: '连续7天达成饮水目标', icon: '🔥', category: 'streak', targetValue: 7, currentValue: 0, progress: 0, unlockedAt: null },
  { id: 'streak_30', title: '月度达人', description: '连续30天达成饮水目标', icon: '⭐', category: 'streak', targetValue: 30, currentValue: 0, progress: 0, unlockedAt: null },
  { id: 'streak_100', title: '百日征程', description: '连续100天达成饮水目标', icon: '👑', category: 'streak', targetValue: 100, currentValue: 0, progress: 0, unlockedAt: null },
  { id: 'streak_365', title: '年度冠军', description: '连续365天达成饮水目标', icon: '🏆', category: 'streak', targetValue: 365, currentValue: 0, progress: 0, unlockedAt: null },
  { id: 'volume_10l', title: '涓涓细流', description: '累计饮水达到10升', icon: '💧', category: 'volume', targetValue: 10000, currentValue: 0, progress: 0, unlockedAt: null },
  { id: 'volume_100l', title: '汇流成河', description: '累计饮水达到100升', icon: '🌊', category: 'volume', targetValue: 100000, currentValue: 0, progress: 0, unlockedAt: null },
  { id: 'volume_500l', title: '碧波万顷', description: '累计饮水达到500升', icon: '🌏', category: 'volume', targetValue: 500000, currentValue: 0, progress: 0, unlockedAt: null },
  { id: 'volume_1000l', title: '海纳百川', description: '累计饮水达到1000升', icon: '🐳', category: 'volume', targetValue: 1000000, currentValue: 0, progress: 0, unlockedAt: null },
  { id: 'early_bird', title: '早起之星', description: '早上8点前完成第一杯水（连续7天）', icon: '🌅', category: 'consistency', targetValue: 7, currentValue: 0, progress: 0, unlockedAt: null },
  { id: 'variety', title: '品味多样', description: '一天内饮用5种不同饮品', icon: '🎨', category: 'milestone', targetValue: 5, currentValue: 0, progress: 0, unlockedAt: null },
  { id: 'eight_cups', title: '八杯水达人', description: '一天记录8次以上饮水', icon: '8️⃣', category: 'milestone', targetValue: 8, currentValue: 0, progress: 0, unlockedAt: null },
  { id: 'overachiever', title: '超额完成', description: '单日饮水量达到目标的150%', icon: '💪', category: 'milestone', targetValue: 150, currentValue: 0, progress: 0, unlockedAt: null }
]

export function cloneAchievements(achievements: Achievement[]): Achievement[] {
  return achievements.map((achievement: Achievement): Achievement => ({
    id: achievement.id,
    title: achievement.title,
    description: achievement.description,
    icon: achievement.icon,
    category: achievement.category,
    targetValue: achievement.targetValue,
    currentValue: achievement.currentValue,
    progress: achievement.progress,
    unlockedAt: achievement.unlockedAt
  }))
}

export type UserLevel = 'drop' | 'stream' | 'river' | 'lake' | 'ocean'

export interface LevelInfo {
  level: UserLevel
  name: string
  icon: string
  minVolumeMl: number
}

export const LEVEL_THRESHOLDS: LevelInfo[] = [
  { level: 'drop', name: '水滴', icon: '💧', minVolumeMl: 0 },
  { level: 'stream', name: '溪流', icon: '🏞️', minVolumeMl: 50000 },
  { level: 'river', name: '河流', icon: '🌊', minVolumeMl: 200000 },
  { level: 'lake', name: '湖泊', icon: '🏖️', minVolumeMl: 500000 },
  { level: 'ocean', name: '海洋', icon: '🐋', minVolumeMl: 1000000 }
]
