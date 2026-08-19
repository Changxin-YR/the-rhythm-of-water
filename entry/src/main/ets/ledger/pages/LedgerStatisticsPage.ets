import { BillType } from '../models/BillRecord';
import { MonthSummary, CategoryStat } from '../models/Statistics';
import { StatisticsService } from '../services/StatisticsService';
import { SummaryCard } from '../components/SummaryCard';
import { PieChart } from '../components/PieChart';
import { LedgerIcon } from '../components/LedgerIcon';
import { Constants } from '../common/Constants';
import { DateUtils } from '../common/DateUtils';
import { NumberUtils } from '../common/NumberUtils';
import { LedgerBreakpoint, ResponsiveUtils } from '../common/ResponsiveUtils';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { minimumBottomControlInsetVp } from '../../common/SafeAreaRules';
import { ledgerColor } from '../common/LedgerTheme';
import { AppSymbol } from '../../components/AppSymbol';

@Component
export struct LedgerStatisticsPage {
  @State currentYear: number = DateUtils.getCurrentYear();
  @StorageProp('safeAreaTop') safeAreaTop: number = 0;
  @StorageProp('safeAreaBottom') safeAreaBottom: number = 0;
  @State currentMonth: number = DateUtils.getCurrentMonth();
  @State monthSummary: MonthSummary = {
    year: DateUtils.getCurrentYear(),
    month: DateUtils.getCurrentMonth(),
    totalIncome: 0,
    totalExpense: 0,
    balance: 0,
    billCount: 0
  };
  @State expenseStats: CategoryStat[] = [];
  @State incomeStats: CategoryStat[] = [];
  @State showExpense: boolean = true;
  @State currentBreakpoint: LedgerBreakpoint = LedgerBreakpoint.COMPACT;

  private statisticsService: StatisticsService = new StatisticsService();
  private dataRequestId: number = 0;

  async aboutToAppear(): Promise<void> {
    await this.loadData();
  }

  private async loadData(): Promise<void> {
    const requestId = ++this.dataRequestId;
    try {
      const monthSummary = await this.statisticsService.getMonthSummary(this.currentYear, this.currentMonth);
      const expenseStats = await this.statisticsService.getCategoryStats(this.currentYear, this.currentMonth, BillType.EXPENSE);
      const incomeStats = await this.statisticsService.getCategoryStats(this.currentYear, this.currentMonth, BillType.INCOME);
      if (requestId !== this.dataRequestId) {
        return;
      }
      this.monthSummary = monthSummary;
      this.expenseStats = expenseStats;
      this.incomeStats = incomeStats;
    } catch (error) {
      if (requestId === this.dataRequestId) {
        promptAction.showToast({ message: $r('app.string.ledger_load_fail'), duration: 2000 });
      }
    }
  }

  private prevMonth(): void {
    if (this.currentMonth === 1) {
      this.currentMonth = 12;
      this.currentYear--;
    } else {
      this.currentMonth--;
    }
    this.loadData();
  }

  private nextMonth(): void {
    const now = new Date();
    if (this.currentYear === now.getFullYear() && this.currentMonth === now.getMonth() + 1) return;
    if (this.currentMonth === 12) {
      this.currentMonth = 1;
      this.currentYear++;
    } else {
      this.currentMonth++;
    }
    this.loadData();
  }

  private getCurrentStats(): CategoryStat[] {
    return this.showExpense ? this.expenseStats : this.incomeStats;
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ledgerColor('ledger_canvas'))
        .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);

      Column() {
      Row() {
        Button({ type: ButtonType.Normal }) {
          Image($r('app.media.ledger_close'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
        }
          .width(44)
          .height(44)
          .backgroundColor(ledgerColor('ledger_surface'))
          .borderRadius(Constants.RADIUS_FULL)
          .onClick(() => { router.back(); })

        Text($r('app.string.ledger_tab_statistics'))
          .fontSize(Constants.FONT_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ledgerColor('ledger_ink'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(44)
      }
      .width('100%')
      .height(60)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      Scroll() {
        Column() {
          Row() {
            Text($r('app.string.ledger_previous_month'))
              .fontSize(22)
              .fontColor(ledgerColor('ledger_primary_color'))
              .padding(8)
              .onClick(() => { this.prevMonth(); })

            Text(DateUtils.formatMonthDisplay(this.currentYear, this.currentMonth))
              .fontSize(Constants.FONT_BODY)
              .fontWeight(FontWeight.Medium)
              .fontColor(ledgerColor('ledger_ink'))
              .padding({ left: 16, right: 16 })

            Text($r('app.string.ledger_next_month'))
              .fontSize(22)
              .fontColor(ledgerColor('ledger_primary_color'))
              .padding(8)
              .onClick(() => { this.nextMonth(); })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 12, bottom: 12 })

          SummaryCard({
            totalIncome: this.monthSummary.totalIncome,
            totalExpense: this.monthSummary.totalExpense,
            title: DateUtils.formatMonthDisplay(this.currentYear, this.currentMonth)
          })
            .margin({ left: 16, right: 16 })

          Row({ space: 16 }) {
            Text($r('app.string.ledger_expense'))
              .fontSize(Constants.FONT_BODY)
              .fontWeight(this.showExpense ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.showExpense ? ledgerColor('ledger_expense_red') : ledgerColor('ledger_muted'))
              .padding({ left: 18, right: 18, top: 8, bottom: 8 })
              .backgroundColor(this.showExpense ? ledgerColor('ledger_expense_red_light') : ledgerColor('ledger_surface'))
              .borderRadius(Constants.RADIUS_FULL)
              .onClick(() => { this.showExpense = true; })

            Text($r('app.string.ledger_income'))
              .fontSize(Constants.FONT_BODY)
              .fontWeight(!this.showExpense ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(!this.showExpense ? ledgerColor('ledger_income_green') : ledgerColor('ledger_muted'))
              .padding({ left: 18, right: 18, top: 8, bottom: 8 })
              .backgroundColor(!this.showExpense ? ledgerColor('ledger_primary_light') : ledgerColor('ledger_surface'))
              .borderRadius(Constants.RADIUS_FULL)
              .onClick(() => { this.showExpense = false; })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 20 })

          Row() {
            PieChart({
              stats: this.getCurrentStats(),
              chartSize: ResponsiveUtils.getChartSize(this.currentBreakpoint)
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 16 })

          Text($r('app.string.ledger_category_ranking'))
            .fontSize(Constants.FONT_SUBTITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(ledgerColor('ledger_ink'))
            .width('100%')
            .padding({ left: 16, top: 20, bottom: 10 })

          Column() {
            ForEach(this.getCurrentStats(), (stat: CategoryStat, index: number) => {
              Row() {
                Text(`${index + 1}`)
                  .fontSize(Constants.FONT_CAPTION)
                  .fontColor(ledgerColor('ledger_muted'))
                  .width(24)
                  .textAlign(TextAlign.Center)

                AppSymbol({ name: stat.categoryIcon, symbolSize: 20, color: ledgerColor('ledger_primary_color') })
                  .margin({ left: 8 })

                Text(stat.categoryName)
                  .fontSize(Constants.FONT_BODY)
                  .fontColor(ledgerColor('ledger_ink'))
                  .margin({ left: 10 })
                  .layoutWeight(1)

                Column() {
                  Text(NumberUtils.formatAmount(stat.totalAmount))
                    .fontSize(Constants.FONT_BODY)
                    .fontColor(ledgerColor('ledger_ink'))
                    .fontWeight(FontWeight.Medium)
                  Text(NumberUtils.formatPercent(stat.percentage))
                    .fontSize(Constants.FONT_SMALL)
                    .fontColor(ledgerColor('ledger_muted'))
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.End)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })

              if (index < this.getCurrentStats().length - 1) {
                Divider().margin({ left: 52 }).color(ledgerColor('ledger_divider'))
              }
            }, (stat: CategoryStat) => stat.categoryId)
          }
          .backgroundColor(ledgerColor('ledger_surface'))
          .borderRadius(Constants.RADIUS_MD)
          .margin({ left: 16, right: 16 })

          Column().height(32)
          Column().height(minimumBottomControlInsetVp(this.safeAreaBottom))
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.safeAreaTop })
    .constraintSize({ maxWidth: ResponsiveUtils.getContentMaxWidth(this.currentBreakpoint) })
    }
    .width('100%')
    .height('100%')
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.currentBreakpoint = ResponsiveUtils.fromAreaWidth(newValue.width, (value: number) => this.getUIContext().px2vp(value));
    })
  }
}
