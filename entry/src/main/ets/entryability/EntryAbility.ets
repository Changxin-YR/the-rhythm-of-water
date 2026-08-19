import { AbilityConstant, UIAbility, Want, ConfigurationConstant, Configuration } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { window } from '@kit.ArkUI'
import { DatabaseHelper as LedgerDatabaseHelper } from '../ledger/services/DatabaseHelper'

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'YuanQiYouShu', 'Ability onCreate')
    const colorMode = this.context.config.colorMode ?? ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
    AppStorage.setOrCreate('colorMode', colorMode)
    AppStorage.setOrCreate('ledgerDarkMode', colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
    AppStorage.setOrCreate('safeAreaTop', 0)
    AppStorage.setOrCreate('safeAreaBottom', 0)
  }

  onDestroy(): void {
    hilog.info(0x0000, 'YuanQiYouShu', 'Ability onDestroy')
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(0x0000, 'YuanQiYouShu', 'Ability onWindowStageCreate')

    try {
      await LedgerDatabaseHelper.getInstance().initDatabase(this.context)
    } catch (error) {
      hilog.error(0x0000, 'YuanQiYouShu', 'Ledger database initialization failed: %{public}s', JSON.stringify(error))
      return
    }

    windowStage.loadContent('pages/MainPage', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'YuanQiYouShu', 'Failed to load content: %{public}s', JSON.stringify(err))
        return
      }
      hilog.info(0x0000, 'YuanQiYouShu', 'Content loaded successfully')
    })
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'YuanQiYouShu', 'Ability onWindowStageDestroy')
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    const colorMode = newConfig.colorMode ?? ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
    AppStorage.setOrCreate('colorMode', colorMode)
    AppStorage.setOrCreate('ledgerDarkMode', colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
  }

  onForeground(): void {
    hilog.info(0x0000, 'YuanQiYouShu', 'Ability onForeground')
  }

  onBackground(): void {
    hilog.info(0x0000, 'YuanQiYouShu', 'Ability onBackground')
  }
}
