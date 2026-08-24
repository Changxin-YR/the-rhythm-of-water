import { DEFAULT_AVATAR_ID, normalizeAvatarId } from '../common/AvatarOptions'

export type ActivityLevel = 'sedentary' | 'light' | 'moderate' | 'active' | 'athlete'
export type SpecialState = 'none' | 'pregnant' | 'breastfeeding' | 'sick'
export type ClimateType = 'normal' | 'hot' | 'dry'

export interface UserProfile {
  nickname: string
  avatarId: string
  weightKg: number
  activityLevel: ActivityLevel
  specialState: SpecialState
  climate: ClimateType
  dailyGoalMl: number
  isGoalAutoCalculated: boolean
  onboardingCompleted: boolean
  createdAt: number
  updatedAt: number
}

export const DEFAULT_PROFILE: UserProfile = {
  nickname: '',
  avatarId: DEFAULT_AVATAR_ID,
  weightKg: 60,
  activityLevel: 'light',
  specialState: 'none',
  climate: 'normal',
  dailyGoalMl: 2000,
  isGoalAutoCalculated: true,
  onboardingCompleted: false,
  createdAt: 0,
  updatedAt: 0
}

export function cloneUserProfile(profile: UserProfile): UserProfile {
  return {
    nickname: profile.nickname,
    avatarId: normalizeAvatarId(profile.avatarId),
    weightKg: profile.weightKg,
    activityLevel: profile.activityLevel,
    specialState: profile.specialState,
    climate: profile.climate,
    dailyGoalMl: profile.dailyGoalMl,
    isGoalAutoCalculated: profile.isGoalAutoCalculated,
    onboardingCompleted: profile.onboardingCompleted,
    createdAt: profile.createdAt,
    updatedAt: profile.updatedAt
  }
}
