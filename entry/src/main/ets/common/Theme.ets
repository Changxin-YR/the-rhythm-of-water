import { ConfigurationConstant } from '@kit.AbilityKit'

export type ThemeMode = 'system' | 'light' | 'dark'
export type ThemeColor = 'blue' | 'green' | 'purple' | 'orange' | 'pink' | 'teal'

export interface UiTokenValues {
  pageHorizontal: number
  cardRadius: number
  smallRadius: number
  buttonHeight: number
  recommendedTouchTargetSize: number
  minimumTouchTargetSize: number
  headerIconButtonSize: number
  colorPickerOptionSize: number
  bottomBarHeight: number
  bottomBarIconBoxHeight: number
  bottomBarLabelBoxHeight: number
  bottomBarIconSize: number
  bottomBarLabelSize: number
  sectionGap: number
  cardPadding: number
  primaryBlue: string
  textPrimary: string
  textSecondary: string
  background: string
  glassBorder: string
}

export const UiTokens: UiTokenValues = {
  pageHorizontal: 20,
  cardRadius: 16,
  smallRadius: 10,
  buttonHeight: 48,
  recommendedTouchTargetSize: 48,
  minimumTouchTargetSize: 40,
  headerIconButtonSize: 48,
  colorPickerOptionSize: 48,
  bottomBarHeight: 64,
  bottomBarIconBoxHeight: 26,
  bottomBarLabelBoxHeight: 18,
  bottomBarIconSize: 22,
  bottomBarLabelSize: 11,
  sectionGap: 12,
  cardPadding: 16,
  primaryBlue: '#007AFF',
  textPrimary: '#1D1D1F',
  textSecondary: '#5C5C63',
  background: '#F2F2F7',
  glassBorder: '#C6C6C8'
}

export function withAlpha(color: string, alpha: string): string {
  return '#' + alpha + color.substring(1)
}

export interface AppSettings {
  themeMode: ThemeMode
  themeColor: ThemeColor
  unit: 'ml' | 'oz'
  dailyResetHour: number
  schemaVersion: number
}

export const DEFAULT_APP_SETTINGS: AppSettings = {
  themeMode: 'system',
  themeColor: 'blue',
  unit: 'ml',
  dailyResetHour: 0,
  schemaVersion: 1
}

export function cloneAppSettings(settings: AppSettings): AppSettings {
  return {
    themeMode: 'system',
    themeColor: settings.themeColor,
    unit: settings.unit,
    dailyResetHour: settings.dailyResetHour,
    schemaVersion: settings.schemaVersion
  }
}

export interface ThemeColors {
  primary: string
  primaryDark: string
  primaryText: string
  secondary: string
  accent: string
  background: string
  card: string
  surface: string
  input: string
  divider: string
  progressTrack: string
  selectedSurface: string
  positiveSurface: string
  danger: string
  dialogOverlay: string
  systemBar: string
  systemBarContent: string
  textPrimary: string
  textSecondary: string
  success: string
  warning: string
  onPrimary: string
}

export interface ThemeColorOverride {
  primary: string
  primaryDark: string
  primaryText: string
  secondary: string
  accent: string
}

const LIGHT_BASE: ThemeColors = {
  primary: UiTokens.primaryBlue,
  primaryDark: '#005EC4',
  primaryText: '#0066CC',
  secondary: '#64D2FF',
  accent: '#30B0C7',
  background: UiTokens.background,
  card: '#FFFFFF',
  surface: '#E9E9EE',
  input: '#E9E9EE',
  divider: '#C6C6C8',
  progressTrack: '#D1D1D6',
  selectedSurface: '#E5F2FF',
  positiveSurface: '#E8F6EC',
  danger: '#D70015',
  dialogOverlay: '#66000000',
  systemBar: '#F2F2F7',
  systemBarContent: '#1D1D1F',
  textPrimary: UiTokens.textPrimary,
  textSecondary: UiTokens.textSecondary,
  success: '#217D37',
  warning: '#8A4B00',
  onPrimary: '#FFFFFF'
}

const DARK_BASE: ThemeColors = {
  primary: '#0A84FF',
  primaryDark: '#0066CC',
  primaryText: '#0A84FF',
  secondary: '#30B0C7',
  accent: '#64D2FF',
  background: '#000000',
  card: '#1C1C1E',
  surface: '#2C2C2E',
  input: '#2C2C2E',
  divider: '#38383A',
  progressTrack: '#3A3A3C',
  selectedSurface: '#102A43',
  positiveSurface: '#15351F',
  danger: '#FF453A',
  dialogOverlay: '#99000000',
  systemBar: '#000000',
  systemBarContent: '#F5F5F7',
  textPrimary: '#F5F5F7',
  textSecondary: '#AEAEB2',
  success: '#30D158',
  warning: '#FF9F0A',
  onPrimary: '#FFFFFF'
}

function getThemeColorOverride(themeColor: ThemeColor, isDark: boolean): ThemeColorOverride {
  switch (themeColor) {
    case 'blue': return { primary: isDark ? '#0A84FF' : UiTokens.primaryBlue, primaryDark: isDark ? '#0066CC' : '#005EC4', primaryText: isDark ? '#0A84FF' : '#0066CC', secondary: isDark ? '#30B0C7' : '#64D2FF', accent: isDark ? '#64D2FF' : '#30B0C7' }
    case 'green': return { primary: '#248A3D', primaryDark: '#1E6F32', primaryText: isDark ? '#30D158' : '#1E6F32', secondary: '#63DA7B', accent: isDark ? '#30D158' : '#248A3D' }
    case 'purple': return { primary: '#7B1FA2', primaryDark: '#6A1B9A', primaryText: isDark ? '#BF5AF2' : '#6A1B9A', secondary: '#D8A8EF', accent: isDark ? '#BF5AF2' : '#7B1FA2' }
    case 'orange': return { primary: '#9A4C00', primaryDark: '#7A3C00', primaryText: isDark ? '#FF9F0A' : '#7A3C00', secondary: '#FFD28A', accent: isDark ? '#FF9F0A' : '#9A4C00' }
    case 'pink': return { primary: '#C2185B', primaryDark: '#880E4F', primaryText: isDark ? '#FF375F' : '#880E4F', secondary: '#F7A7BE', accent: isDark ? '#FF375F' : '#C2185B' }
    case 'teal': return { primary: '#00796B', primaryDark: '#00665B', primaryText: isDark ? '#64D2FF' : '#00665B', secondary: '#8FE3EA', accent: isDark ? '#64D2FF' : '#00796B' }
  }
}

export function getThemeColors(isDark: boolean, themeColor: ThemeColor): ThemeColors {
  const source = isDark ? DARK_BASE : LIGHT_BASE
  const base: ThemeColors = {
    primary: source.primary,
    primaryDark: source.primaryDark,
    primaryText: source.primaryText,
    secondary: source.secondary,
    accent: source.accent,
    background: source.background,
    card: source.card,
    surface: source.surface,
    input: source.input,
    divider: source.divider,
    progressTrack: source.progressTrack,
    selectedSurface: source.selectedSurface,
    positiveSurface: source.positiveSurface,
    danger: source.danger,
    dialogOverlay: source.dialogOverlay,
    systemBar: source.systemBar,
    systemBarContent: source.systemBarContent,
    textPrimary: source.textPrimary,
    textSecondary: source.textSecondary,
    success: source.success,
    warning: source.warning,
    onPrimary: source.onPrimary
  }
  const colorOverride = getThemeColorOverride(themeColor, isDark)
  base.primary = colorOverride.primary
  base.primaryDark = colorOverride.primaryDark
  base.primaryText = colorOverride.primaryText
  base.secondary = colorOverride.secondary
  base.accent = colorOverride.accent
  return base
}

export function isSystemDarkMode(colorMode: ConfigurationConstant.ColorMode): boolean {
  return colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
}
