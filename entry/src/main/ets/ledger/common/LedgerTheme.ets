/**
 * The ledger module historically resolved its palette only from resource
 * qualifiers.  The unified app also supports an in-app theme preference, so
 * ledger surfaces use this semantic palette instead of assuming the device's
 * system color mode.
 */
export function setLedgerDarkMode(isDark: boolean): void {
  AppStorage.setOrCreate('ledgerDarkMode', isDark)
}

function isDark(): boolean {
  return AppStorage.get<boolean>('ledgerDarkMode') === true
}

export function ledgerColor(name: string): string {
  const dark = isDark()
  switch (name) {
    case 'ledger_canvas': return dark ? '#000000' : '#F2F2F7'
    case 'ledger_surface': return dark ? '#1C1C1E' : '#FFFFFF'
    case 'ledger_card_divider': return dark ? '#38383A' : '#C6C6C8'
    case 'ledger_card_text_primary': return '#FFFFFF'
    case 'ledger_card_text_secondary': return dark ? '#F5F5F7' : '#FFFFFF'
    case 'ledger_card_text_hint': return dark ? '#D1D1D6' : '#FFFFFF'
    case 'ledger_primary_color': return dark ? '#0A84FF' : '#007AFF'
    case 'ledger_primary_light': return dark ? '#102A43' : '#E5F2FF'
    case 'ledger_primary_surface': return dark ? '#153A5F' : '#DDEEFF'
    case 'ledger_accent': return dark ? '#64D2FF' : '#30B0C7'
    case 'ledger_income_green': return dark ? '#30D158' : '#217D37'
    case 'ledger_income_green_light': return dark ? '#15351F' : '#E8F6EC'
    case 'ledger_expense_red': return dark ? '#FF453A' : '#D70015'
    case 'ledger_expense_red_light': return dark ? '#401513' : '#FCE8EA'
    case 'ledger_expense_soft': return dark ? '#401513' : '#FCE8EA'
    case 'ledger_income_soft': return dark ? '#15351F' : '#E8F6EC'
    case 'ledger_ink': return dark ? '#F5F5F7' : '#1D1D1F'
    case 'ledger_text_secondary': return dark ? '#D1D1D6' : '#5C5C63'
    case 'ledger_muted': return dark ? '#AEAEB2' : '#5C5C63'
    case 'ledger_tab_inactive': return dark ? '#AEAEB2' : '#5C5C63'
    case 'ledger_divider': return dark ? '#38383A' : '#C6C6C8'
    case 'ledger_card_shadow': return '#00000000'
    case 'ledger_shadow': return '#00000000'
    case 'ledger_streak_gold': return dark ? '#FFD60A' : '#8A4B00'
    case 'ledger_category_fallback': return dark ? '#0A84FF' : '#007AFF'
    case 'ledger_category_bg': return dark ? '#102A43' : '#E5F2FF'
    case 'ledger_category_unselected_bg': return dark ? '#2C2C2E' : '#E9E9EE'
    case 'ledger_progress_bg': return dark ? '#3A3A3C' : '#D1D1D6'
    case 'ledger_progress_danger': return dark ? '#FF453A' : '#D70015'
    case 'ledger_progress_warning': return dark ? '#FF9F0A' : '#8A4B00'
    case 'ledger_progress_safe': return dark ? '#30D158' : '#217D37'
    case 'ledger_keyboard_bg': return dark ? '#1C1C1E' : '#FFFFFF'
    case 'ledger_keyboard_key_bg': return dark ? '#2C2C2E' : '#E9E9EE'
    case 'ledger_dialog_overlay': return dark ? '#99000000' : '#66000000'
    default: return dark ? '#1C1C1E' : '#FFFFFF'
  }
}
