import { window } from '@kit.ArkUI'
import { ThemeColors } from '../common/Theme'
import { resolveSystemBarAppearance } from '../common/SystemBarAppearance'
import { normalizeSafeAreaHeightPx } from '../common/SafeAreaRules'

export class SystemBarService {
  async apply(context: Context, colors: ThemeColors): Promise<void> {
    try {
      const activeWindow = await window.getLastWindow(context)
      const appearance = resolveSystemBarAppearance(colors)
      await activeWindow.setWindowLayoutFullScreen(appearance.useImmersiveLayout)
      await activeWindow.setWindowSystemBarProperties({
        statusBarColor: appearance.backgroundColor,
        navigationBarColor: appearance.backgroundColor,
        statusBarContentColor: appearance.contentColor,
        navigationBarContentColor: appearance.contentColor,
        isStatusBarLightIcon: appearance.lightIcons,
        isNavigationBarLightIcon: appearance.lightIcons
      })
      const avoidArea = activeWindow.getWindowAvoidAreaIgnoringVisibility(window.AvoidAreaType.TYPE_SYSTEM)
      const safeAreaTop = activeWindow.getUIContext().px2vp(normalizeSafeAreaHeightPx(avoidArea.topRect.height))
      const safeAreaBottom = activeWindow.getUIContext().px2vp(normalizeSafeAreaHeightPx(avoidArea.bottomRect.height))
      AppStorage.setOrCreate<number>('safeAreaTop', safeAreaTop)
      AppStorage.setOrCreate<number>('safeAreaBottom', safeAreaBottom)
      console.info('SystemBarService: applied', JSON.stringify(activeWindow.getWindowSystemBarProperties()))
    } catch (error) {
      console.error('SystemBarService: failed to apply system bar appearance', JSON.stringify(error))
    }
  }
}
