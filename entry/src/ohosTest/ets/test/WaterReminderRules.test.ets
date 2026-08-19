import { describe, expect, it } from '@ohos/hypium'
import { clampGoal, normalizeDrinkPayload, parsePositiveWholeMl, resolveSelectedId, shouldHideProgressIndicator } from '../../../main/ets/common/WaterReminderRules'
import { AVATAR_OPTIONS, avatarGlyph, DEFAULT_AVATAR_ID, normalizeAvatarId } from '../../../main/ets/common/AvatarOptions'
import { Plant } from '../../../main/ets/models/Plant'
import { normalizePlantWaterAmount, revertPlantWater } from '../../../main/ets/common/PlantRules'
import { Achievement, ACHIEVEMENT_DEFINITIONS, cloneAchievements } from '../../../main/ets/models/Achievement'
import { calculateAchievementProgress, AchievementProgressMetrics, reconcileAchievementProgress } from '../../../main/ets/common/AchievementRules'
import { parseJsonArray, parseJsonObject } from '../../../main/ets/common/JsonUtils'
import { cloneUserProfile, UserProfile } from '../../../main/ets/models/UserProfile'
import { GoalCalculator } from '../../../main/ets/common/GoalCalculator'
import { Constants } from '../../../main/ets/common/Constants'
import { completionPercent, remainingGoalMl, getAchievementDisplayMetrics } from '../../../main/ets/common/DashboardData'
import { buildDemoRecords, buildDemoPlant } from '../../../main/ets/common/DemoData'
import { shouldSeedDemoData, shouldRepairDemoData } from '../../../main/ets/services/DemoDataService'
import { getThemeColors, isSystemDarkMode, ThemeColor, UiTokens, withAlpha } from '../../../main/ets/common/Theme'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { buildBackupFileName, validateBackupPayload, validateUserProfileJson } from '../../../main/ets/common/BackupRules'
import { DateUtils } from '../../../main/ets/common/DateUtils'
import { Beverage, DEFAULT_BEVERAGES, cloneBeverages } from '../../../main/ets/models/Beverage'
import { ACHIEVEMENT_TAB_INDEX, LEDGER_TAB_INDEX, SETTINGS_TAB_INDEX, WATER_TAB_INDEX, nextRefreshRevision, shouldRefreshAchievementOnTabSelection } from '../../../main/ets/common/DataRefresh'
import { resolveSystemBarAppearance } from '../../../main/ets/common/SystemBarAppearance'
import { minimumBottomControlInsetVp, normalizeSafeAreaHeightPx } from '../../../main/ets/common/SafeAreaRules'
import { contrastRatio, contrastRatioOverSurface, hasMinimumIconOrTitleContrast, hasMinimumTextContrast } from '../../../main/ets/common/ColorContrast'
import { MIN_READABLE_FONT_SIZE_FP } from '../../../main/ets/common/TypographyRules'
import { completionPercent as overviewCompletionPercent, formatBalance } from '../../../main/ets/common/OverviewData'

export default function waterReminderRulesTest(): void {
  describe('WaterReminderRules', (): void => {
    it('usesTheCurrentSystemColorModeForAppearance', 0, (): void => {
      expect(isSystemDarkMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)).assertFalse()
      expect(isSystemDarkMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)).assertTrue()
    })

    it('writesArkUiAlphaBeforeRgbChannels', 0, (): void => {
      expect(withAlpha('#007AFF', '20')).assertEqual('#20007AFF')
      expect(withAlpha('#1C1C1E', 'F2')).assertEqual('#F21C1C1E')
    })

    it('usesContrastingSystemBarIconsForEachTheme', 0, (): void => {
      const dark = resolveSystemBarAppearance(getThemeColors(true, 'blue'))
      expect(dark.backgroundColor).assertEqual('#000000')
      expect(dark.lightIcons).assertTrue()
      expect(dark.useImmersiveLayout).assertTrue()
      expect(dark.paintSystemSafeAreas).assertTrue()

      const light = resolveSystemBarAppearance(getThemeColors(false, 'blue'))
      expect(light.backgroundColor).assertEqual('#F2F2F7')
      expect(light.lightIcons).assertFalse()
      expect(light.useImmersiveLayout).assertTrue()
      expect(light.paintSystemSafeAreas).assertTrue()
    })

    it('keepsValidSystemInsetsAndRejectsUnsafeValues', 0, (): void => {
      expect(normalizeSafeAreaHeightPx(137)).assertEqual(137)
      expect(normalizeSafeAreaHeightPx(-1)).assertEqual(0)
      expect(normalizeSafeAreaHeightPx(Number.NaN)).assertEqual(0)
      expect(normalizeSafeAreaHeightPx(Number.POSITIVE_INFINITY)).assertEqual(0)
    })

    it('keepsBottomControlsAtLeast28VpAboveSystemNavigation', 0, (): void => {
      expect(minimumBottomControlInsetVp(0)).assertEqual(28)
      expect(minimumBottomControlInsetVp(36)).assertEqual(36)
    })

    it('rejectsLowContrastTextColors', 0, (): void => {
      expect(hasMinimumTextContrast('#5C5C63', '#F2F2F7')).assertTrue()
      expect(hasMinimumTextContrast('#8E8E93', '#F2F2F7')).assertFalse()
    })

    it('usesContrastSafeSemanticTextAndActions', 0, (): void => {
      const light = getThemeColors(false, 'blue')
      const dark = getThemeColors(true, 'blue')
      expect(hasMinimumTextContrast(light.textPrimary, light.background)).assertTrue()
      expect(hasMinimumTextContrast(light.textSecondary, light.background)).assertTrue()
      expect(hasMinimumIconOrTitleContrast('#FFFFFF', light.primary)).assertTrue()
      expect(hasMinimumTextContrast(light.success, light.background)).assertTrue()
      expect(hasMinimumTextContrast(dark.textPrimary, dark.background)).assertTrue()
      expect(hasMinimumTextContrast(dark.textSecondary, dark.background)).assertTrue()
    })

    it('usesReadablePrimaryForegroundsForEveryTheme', 0, (): void => {
      const themeColors: ThemeColor[] = ['blue', 'green', 'purple', 'orange', 'pink', 'teal']
      for (const themeColor of themeColors) {
        const light = getThemeColors(false, themeColor)
        const dark = getThemeColors(true, themeColor)
        expect(hasMinimumTextContrast(light.primaryText, light.background)).assertTrue()
        expect(hasMinimumTextContrast(light.primaryText, light.card)).assertTrue()
        expect(hasMinimumTextContrast(light.primaryText, light.selectedSurface)).assertTrue()
        expect(hasMinimumTextContrast(light.primaryText, light.positiveSurface)).assertTrue()
        expect(hasMinimumTextContrast(light.primaryText, light.surface)).assertTrue()
        expect(hasMinimumTextContrast(light.primaryText, light.input)).assertTrue()
        expect(hasMinimumTextContrast(dark.primaryText, dark.background)).assertTrue()
        expect(hasMinimumTextContrast(dark.primaryText, dark.card)).assertTrue()
        expect(hasMinimumIconOrTitleContrast('#FFFFFF', light.primary)).assertTrue()
        expect(hasMinimumIconOrTitleContrast('#FFFFFF', dark.primary)).assertTrue()
      }
    })

    it('compositesAlphaColorsAndUsesTheIconThreshold', 0, (): void => {
      const halfBlackOnWhite = contrastRatio('#00000080', '#FFFFFF')
      expect(halfBlackOnWhite > 3.9 && halfBlackOnWhite < 4.1).assertTrue()
      expect(contrastRatioOverSurface('#4FC3F7', '#1B2838B8', '#0D1B2A') > 4.5).assertTrue()
      expect(hasMinimumIconOrTitleContrast('#0E8C9E', '#FFFFFF')).assertTrue()
      expect(hasMinimumIconOrTitleContrast('#26C6DA', '#FFFFFF')).assertFalse()
    })

    it('uses10FpAsTheMinimumReadableFontSize', 0, (): void => {
      expect(MIN_READABLE_FONT_SIZE_FP).assertEqual(10)
    })

    it('alwaysChangesTheRefreshRevision', 0, (): void => {
      expect(nextRefreshRevision(0)).assertEqual(1)
      expect(nextRefreshRevision(41)).assertEqual(42)
      expect(nextRefreshRevision(-1)).assertEqual(1)
    })

    it('formatsOverviewProgressAndBalance', 0, (): void => {
      expect(overviewCompletionPercent(500, 1000)).assertEqual(50)
      expect(overviewCompletionPercent(1200, 1000)).assertEqual(100)
      expect(overviewCompletionPercent(0, 0)).assertEqual(0)
      expect(formatBalance(12.5)).assertEqual('¥12.50')
      expect(formatBalance(-3)).assertEqual('-¥3.00')
    })

    it('forcesAchievementRefreshWheneverTheAchievementTabIsSelected', 0, (): void => {
      expect(LEDGER_TAB_INDEX).assertEqual(2)
      expect(WATER_TAB_INDEX).assertEqual(1)
      expect(ACHIEVEMENT_TAB_INDEX).assertEqual(1)
      expect(SETTINGS_TAB_INDEX).assertEqual(3)
      expect(shouldRefreshAchievementOnTabSelection(0, 1)).assertTrue()
      expect(shouldRefreshAchievementOnTabSelection(2, 1)).assertTrue()
      expect(shouldRefreshAchievementOnTabSelection(1, 1)).assertTrue()
      expect(shouldRefreshAchievementOnTabSelection(1, 2)).assertFalse()
    })

    it('usesDarkSemanticSurfacesWithoutLightFallbacks', 0, (): void => {
      const colors = getThemeColors(true, 'blue')
      expect(colors.card).assertEqual('#1C1C1E')
      expect(colors.input).assertEqual('#2C2C2E')
      expect(colors.divider).assertEqual('#38383A')
      expect(colors.systemBar).assertEqual('#000000')
    })

    it('usesLightSemanticSurfacesWithoutDarkFallbacks', 0, (): void => {
      const colors = getThemeColors(false, 'blue')
      expect(colors.card).assertEqual('#FFFFFF')
      expect(colors.input).assertEqual('#E9E9EE')
      expect(colors.divider).assertEqual('#C6C6C8')
      expect(colors.systemBar).assertEqual('#F2F2F7')
    })

    it('fallsBackToDefaultAvatarForMissingOrUnknownIds', 0, (): void => {
      expect(normalizeAvatarId('avatar_sun')).assertEqual('avatar_sun')
      expect(normalizeAvatarId('')).assertEqual(DEFAULT_AVATAR_ID)
      expect(normalizeAvatarId('removed_avatar')).assertEqual(DEFAULT_AVATAR_ID)
    })

    it('exposesSixBuiltInAvatarGlyphs', 0, (): void => {
      expect(AVATAR_OPTIONS.length).assertEqual(6)
      expect(avatarGlyph('avatar_star')).assertEqual('⭐')
      expect(avatarGlyph('removed_avatar')).assertEqual('☀️')
    })

    it('normalizesMissingAndUnknownProfileAvatarsWhenCloning', 0, (): void => {
      const legacyProfile = parseJsonObject<UserProfile>(JSON.stringify({
        nickname: '', weightKg: 60, heightCm: 170, age: 25, gender: 'male',
        activityLevel: 'light', specialState: 'none', climate: 'normal', dailyGoalMl: 2200,
        isGoalAutoCalculated: true, onboardingCompleted: true, createdAt: 1, updatedAt: 2
      }))
      expect(legacyProfile === null).assertFalse()
      const normalizedLegacy = cloneUserProfile(legacyProfile!)
      expect(normalizedLegacy.avatarId).assertEqual(DEFAULT_AVATAR_ID)

      normalizedLegacy.avatarId = 'removed_avatar'
      expect(cloneUserProfile(normalizedLegacy).avatarId).assertEqual(DEFAULT_AVATAR_ID)
    })

    it('acceptsCurrentAndLegacyProfilesButNormalizesUnusedFieldsAway', 0, (): void => {
      const currentProfile: UserProfile = {
        nickname: '测试用户',
        avatarId: DEFAULT_AVATAR_ID,
        weightKg: 60,
        activityLevel: 'light',
        specialState: 'none',
        climate: 'normal',
        dailyGoalMl: 2200,
        isGoalAutoCalculated: true,
        onboardingCompleted: true,
        createdAt: 1,
        updatedAt: 2
      }
      expect(validateUserProfileJson(JSON.stringify(currentProfile))).assertTrue()

      const legacyProfile = parseJsonObject<UserProfile>(JSON.stringify({
        nickname: '旧用户',
        avatarId: DEFAULT_AVATAR_ID,
        weightKg: 60,
        heightCm: 170,
        age: 25,
        gender: 'male',
        activityLevel: 'light',
        specialState: 'none',
        climate: 'normal',
        dailyGoalMl: 2200,
        isGoalAutoCalculated: true,
        onboardingCompleted: true,
        createdAt: 1,
        updatedAt: 2
      }))
      expect(legacyProfile === null).assertFalse()
      expect(validateUserProfileJson(JSON.stringify(legacyProfile))).assertTrue()

      const normalized = JSON.stringify(cloneUserProfile(legacyProfile!))
      expect(normalized.includes('"age"')).assertFalse()
      expect(normalized.includes('"gender"')).assertFalse()
      expect(normalized.includes('"heightCm"')).assertFalse()
    })

    it('hidesProgressIndicatorOnlyNearWaterDropAnchor', 0, (): void => {
      expect(shouldHideProgressIndicator(100)).assertTrue()
      expect(shouldHideProgressIndicator(98)).assertTrue()
      expect(shouldHideProgressIndicator(97)).assertTrue()
      expect(shouldHideProgressIndicator(86)).assertFalse()
    })

    it('normalizesNegativeDrinkAmountsBeforeCalculatingHydration', 0, (): void => {
      const normalized = normalizeDrinkPayload(-250, 0.9)
      expect(normalized.amountMl).assertEqual(0)
      expect(normalized.hydrationMl).assertEqual(0)
    })

    it('clampsManualGoalsToSupportedBounds', 0, (): void => {
      expect(clampGoal(1000)).assertEqual(1500)
      expect(clampGoal(5000)).assertEqual(4500)
      expect(clampGoal(2500)).assertEqual(2500)
    })

    it('rejectsNonFiniteDrinkValuesAndGoals', 0, (): void => {
      const normalized = normalizeDrinkPayload(Number.POSITIVE_INFINITY, 0.9)
      expect(normalized.amountMl).assertEqual(0)
      expect(normalized.hydrationMl).assertEqual(0)
      expect(clampGoal(Number.NaN)).assertEqual(1500)
    })

    it('rejectsMalformedManualDrinkAmounts', 0, (): void => {
      expect(parsePositiveWholeMl('250')).assertEqual(250)
      expect(parsePositiveWholeMl('')).assertEqual(null)
      expect(parsePositiveWholeMl('12.5')).assertEqual(null)
      expect(parsePositiveWholeMl('12abc')).assertEqual(null)
      expect(parsePositiveWholeMl('0')).assertEqual(null)
      expect(parsePositiveWholeMl('5001')).assertEqual(null)
    })

    it('repairsSelectionsWhenTheSelectedBeverageIsNoLongerAvailable', 0, (): void => {
      expect(resolveSelectedId('water', ['water', 'tea'])).assertEqual('water')
      expect(resolveSelectedId('water', ['tea'])).assertEqual('tea')
      expect(resolveSelectedId(null, ['tea'])).assertEqual('tea')
      expect(resolveSelectedId('water', [])).assertEqual(null)
    })

    it('keepsDefaultBeveragesIsolatedFromUserSelections', 0, (): void => {
      const cloned: Beverage[] = cloneBeverages(DEFAULT_BEVERAGES)
      cloned[0].isActive = false
      expect(DEFAULT_BEVERAGES[0].isActive).assertTrue()

    })

    it('normalizesUnsafePlantWaterAmounts', 0, (): void => {
      expect(normalizePlantWaterAmount(250)).assertEqual(250)
      expect(normalizePlantWaterAmount(-1)).assertEqual(0)
      expect(normalizePlantWaterAmount(Number.NaN)).assertEqual(0)
      expect(normalizePlantWaterAmount(Number.POSITIVE_INFINITY)).assertEqual(0)
    })

    it('parsesCalendarDatesWithoutUtcDayShift', 0, (): void => {
      const parsed = DateUtils.parseLocalDate('2026-08-05')
      expect(parsed === null).assertFalse()
      expect(DateUtils.formatDate(parsed!)).assertEqual('2026-08-05')
      expect(DateUtils.parseLocalDate('2026-02-30') === null).assertTrue()
    })

    it('revertsPlantWaterAndGrowthWhenADrinkIsRemoved', 0, (): void => {
      const plant: Plant = {
        id: 'plant-1',
        species: 'sunflower',
        name: 'Test',
        growthStage: 1,
        waterReceived: 3200,
        waterNeeded: 3000,
        isActive: true,
        isWilting: false,
        wiltStartDay: null,
        createdAt: 1,
        completedAt: null
      }
      const reverted = revertPlantWater(plant, 500)
      expect(reverted.waterReceived).assertEqual(2700)
      expect(reverted.growthStage).assertEqual(0)
      expect(reverted.isActive).assertTrue()
      expect(reverted.completedAt).assertEqual(null)
    })

    it('recomputesAchievementProgressAfterRecordsChange', 0, (): void => {
      const achievement: Achievement = {
        id: 'first_drink',
        title: 'First',
        description: 'First',
        icon: 'x',
        category: 'milestone',
        targetValue: 1,
        currentValue: 1,
        progress: 100,
        unlockedAt: null
      }
      const metrics: AchievementProgressMetrics = {
        todayTotal: 0,
        todayCount: 0,
        totalVolume: 0,
        streak: 0,
        todayBeverages: 0,
        hasEarlyDrink: false,
        earlyDrinkStreak: 0
      }
      expect(calculateAchievementProgress(achievement, metrics, 2000)).assertEqual(0)
    })

    it('refreshesAchievementSnapshotsFromTheLatestDrinkMetrics', 0, (): void => {
      const staleAchievement: Achievement = {
        id: 'volume_10l',
        title: 'Volume',
        description: 'Volume',
        icon: 'x',
        category: 'volume',
        targetValue: 10000,
        currentValue: 2500,
        progress: 25,
        unlockedAt: null
      }
      const metrics: AchievementProgressMetrics = {
        todayTotal: 2500,
        todayCount: 3,
        totalVolume: 12500,
        streak: 2,
        todayBeverages: 1,
        hasEarlyDrink: true,
        earlyDrinkStreak: 1
      }

      const refreshed = reconcileAchievementProgress([staleAchievement], metrics, 2200, 123)

      expect(refreshed.achievements[0].currentValue).assertEqual(12500)
      expect(refreshed.achievements[0].progress).assertEqual(100)
      expect(refreshed.achievements[0].unlockedAt).assertEqual(123)
      expect(refreshed.newlyUnlocked.length).assertEqual(1)
      expect(staleAchievement.currentValue).assertEqual(2500)
    })

    it('usesEarlyDrinkStreakForEarlyBirdProgress', 0, (): void => {
      const achievement: Achievement = {
        id: 'early_bird',
        title: 'Early bird',
        description: 'Early bird',
        icon: 'x',
        category: 'consistency',
        targetValue: 7,
        currentValue: 0,
        progress: 0,
        unlockedAt: null
      }
      const metrics: AchievementProgressMetrics = {
        todayTotal: 2000,
        todayCount: 2,
        totalVolume: 20000,
        streak: 7,
        todayBeverages: 1,
        hasEarlyDrink: true,
        earlyDrinkStreak: 3
      }
      expect(calculateAchievementProgress(achievement, metrics, 2000)).assertEqual(3)
    })

    it('clonesAchievementDefinitionsBeforeUpdatingProgress', 0, (): void => {
      const cloned = cloneAchievements(ACHIEVEMENT_DEFINITIONS)
      cloned[0].currentValue = 1
      cloned[0].progress = 100
      cloned[0].unlockedAt = 1
      expect(ACHIEVEMENT_DEFINITIONS[0].currentValue).assertEqual(0)
      expect(ACHIEVEMENT_DEFINITIONS[0].progress).assertEqual(0)
      expect(ACHIEVEMENT_DEFINITIONS[0].unlockedAt).assertEqual(null)
    })

    it('returnsSafeDefaultsForMalformedStoredJson', 0, (): void => {
      expect(parseJsonArray<number>('{bad')).assertEqual(null)
      expect(parseJsonArray<number>('{}')).assertEqual(null)
      expect(parseJsonObject<UserProfile>('[1]')).assertEqual(null)
      expect(parseJsonObject<UserProfile>('{}') === null).assertFalse()
    })

    it('clampsNonFiniteCalculatedGoals', 0, (): void => {
      expect(GoalCalculator.calculate(Number.NaN, 'moderate', 'none', 'normal')).assertEqual(Constants.MIN_GOAL_ML)
      expect(GoalCalculator.calculate(Number.POSITIVE_INFINITY, 'moderate', 'none', 'normal')).assertEqual(Constants.MIN_GOAL_ML)
    })

    it('matchesReferenceDashboardNumbers', 0, (): void => {
      expect(completionPercent(850, 2200)).assertEqual(38)
      expect(remainingGoalMl(850, 2200)).assertEqual(1350)
      expect(completionPercent(2400, 2200)).assertEqual(100)
    })

    it('buildsReferenceDemoState', 0, (): void => {
      const records = buildDemoRecords(new Date('2026-08-04T12:00:00+08:00').getTime())
      expect(records.length).assertEqual(2)
      expect(records[0].amountMl + records[1].amountMl).assertEqual(850)

      const plant = buildDemoPlant(new Date('2026-08-04T12:00:00+08:00').getTime())
      expect(plant.species).assertEqual('sunflower')
      expect(plant.growthStage).assertEqual(1)
      expect(plant.waterReceived).assertEqual(3450)
    })

    it('usesLiveAchievementMetricsInsteadOfPlantWaterReceived', 0, (): void => {
      const demoMetrics = getAchievementDisplayMetrics(850, 0, 3450)
      expect(demoMetrics.totalVolume).assertEqual(850)
      expect(demoMetrics.streak).assertEqual(0)

      const realMetrics = getAchievementDisplayMetrics(1250, 0, 3450)
      expect(realMetrics.totalVolume).assertEqual(1250)
      expect(realMetrics.streak).assertEqual(0)
    })

    it('seedsOnlyEmptyFirstLaunch', 0, (): void => {
      expect(shouldSeedDemoData(0, 0, 0)).assertTrue()
    })

    it('preservesExistingUserData', 0, (): void => {
      expect(shouldSeedDemoData(1, 0, 0)).assertFalse()
      expect(shouldSeedDemoData(0, 1, 0)).assertFalse()
      expect(shouldSeedDemoData(0, 0, 1)).assertFalse()
    })

    it('repairsInterruptedDemoSeedingWithoutSeedingOverRealData', 0, (): void => {
      const demoProfile: UserProfile = {
        nickname: '',
        avatarId: 'avatar_sun',
        weightKg: 60,
        activityLevel: 'light',
        specialState: 'none',
        climate: 'normal',
        dailyGoalMl: 2200,
        isGoalAutoCalculated: true,
        onboardingCompleted: true,
        createdAt: 1,
        updatedAt: 2
      }
      const partialPlant = buildDemoPlant(1)
      expect(shouldRepairDemoData(0, demoProfile, [partialPlant])).assertTrue()
      expect(shouldRepairDemoData(1, demoProfile, [partialPlant])).assertFalse()
      const realProfile: UserProfile = {
        nickname: demoProfile.nickname,
        avatarId: demoProfile.avatarId,
        weightKg: demoProfile.weightKg,
        activityLevel: demoProfile.activityLevel,
        specialState: demoProfile.specialState,
        climate: demoProfile.climate,
        dailyGoalMl: 2000,
        isGoalAutoCalculated: demoProfile.isGoalAutoCalculated,
        onboardingCompleted: demoProfile.onboardingCompleted,
        createdAt: demoProfile.createdAt,
        updatedAt: demoProfile.updatedAt
      }
      expect(shouldRepairDemoData(0, realProfile, [partialPlant])).assertFalse()
    })

    it('keepsReferenceVisualTokens', 0, (): void => {
      expect(UiTokens.primaryBlue).assertEqual('#007AFF')
      expect(UiTokens.cardRadius).assertEqual(16)
      expect(UiTokens.pageHorizontal).assertEqual(20)
      expect(UiTokens.bottomBarHeight).assertEqual(64)
      expect(UiTokens.recommendedTouchTargetSize).assertEqual(48)
      expect(UiTokens.minimumTouchTargetSize).assertEqual(40)
    })

    it('buildsStableTimestampedBackupFileNames', 0, (): void => {
      expect(buildBackupFileName(1786090000123)).assertEqual('yuanqiyoushu_backup_1786090000123.json')
      expect(buildBackupFileName(Number.NaN)).assertEqual('yuanqiyoushu_backup.json')
    })

    it('acceptsCompleteBackupPayloadsAndRejectsIncompleteOnes', 0, (): void => {
      const profile = JSON.stringify({
        nickname: '', avatarId: 'avatar_sun', weightKg: 60, heightCm: 170, age: 25, gender: 'male',
        activityLevel: 'light', specialState: 'none', climate: 'normal', dailyGoalMl: 2200,
        isGoalAutoCalculated: true, onboardingCompleted: true, createdAt: 1, updatedAt: 2
      })
      const valid = JSON.stringify({
        version: 1,
        records: '[]',
        profile: profile,
        settings: JSON.stringify({
          themeMode: 'system', themeColor: 'blue', unit: 'ml', dailyResetHour: 0, schemaVersion: 1
        }),
         beverages: '[]',
         cups: '[]',
         achievements: '[]',
         plants: '[]',
         ledgerBills: '[]',
         ledgerCategories: '[]',
         ledgerBudgets: '[]'
       })
       expect(validateBackupPayload(valid)).assertTrue()
       expect(validateBackupPayload(valid.replace('"ledgerBills":"[]"', '"ledgerBills":"not-json"'))).assertFalse()
       const backupWithoutCupData = valid.replace('"cups":"[]",', '')
      expect(validateBackupPayload(backupWithoutCupData)).assertTrue()
      expect(validateUserProfileJson(profile)).assertTrue()
      const invalidProfile = profile.replace('"avatarId":"avatar_sun"', '"avatarId":123')
      expect(validateUserProfileJson(invalidProfile)).assertFalse()
      const legacyProfile = JSON.stringify({
        nickname: '', weightKg: 60, heightCm: 170, age: 25, gender: 'male',
        activityLevel: 'light', specialState: 'none', climate: 'normal', dailyGoalMl: 2200,
        isGoalAutoCalculated: true, onboardingCompleted: true, createdAt: 1, updatedAt: 2
      })
      expect(validateUserProfileJson(legacyProfile)).assertTrue()
      expect(validateBackupPayload('{bad')).assertFalse()
      expect(validateBackupPayload(JSON.stringify({ version: 1, records: '' }))).assertFalse()
      expect(validateBackupPayload(JSON.stringify({
        version: 1,
        records: '[]',
        profile: '{}',
        settings: '{}',
        beverages: '[]',
        cups: '[]',
        achievements: '[]',
        plants: '[]'
      }))).assertFalse()
      expect(validateBackupPayload(valid.replace('"version":1', '"version":2'))).assertFalse()
    })
  })
}
