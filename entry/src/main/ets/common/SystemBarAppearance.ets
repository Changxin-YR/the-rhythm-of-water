import { ThemeColors } from './Theme'
import { contrastRatio } from './ColorContrast'

export interface SystemBarAppearance {
  backgroundColor: string
  contentColor: string
  lightIcons: boolean
  useImmersiveLayout: boolean
  paintSystemSafeAreas: boolean
}

export function resolveSystemBarAppearance(colors: ThemeColors): SystemBarAppearance {
  return {
    backgroundColor: colors.systemBar,
    contentColor: colors.systemBarContent,
    lightIcons: contrastRatio(colors.systemBarContent, '#000000') > contrastRatio(colors.systemBarContent, '#FFFFFF'),
    useImmersiveLayout: true,
    paintSystemSafeAreas: true
  }
}
