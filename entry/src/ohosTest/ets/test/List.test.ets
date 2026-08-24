import waterReminderRulesTest from './WaterReminderRules.test'
import ledgerRulesTest from './LedgerRules.test'

export default function testsuite(): void {
  waterReminderRulesTest()
  ledgerRulesTest()
}
