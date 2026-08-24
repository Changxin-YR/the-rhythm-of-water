import { BudgetService, BudgetProgress } from '../services/BudgetService';
import { StatisticsService } from '../services/StatisticsService';
import { MonthSummary } from '../models/Statistics';
import { Constants } from '../common/Constants';
import { DateUtils } from '../common/DateUtils';
import { NumberUtils } from '../common/NumberUtils';
import { LedgerBreakpoint, ResponsiveUtils } from '../common/ResponsiveUtils';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { minimumBottomControlInsetVp } from '../../common/SafeAreaRules';
import { ledgerColor } from '../common/LedgerTheme';

@Component
export struct LedgerBudgetPage {
  @State currentYear: number = DateUtils.getCurrentYear();
  @StorageProp('safeAreaTop') safeAreaTop: number = 0;
  @StorageProp('safeAreaBottom') safeAreaBottom: number = 0;
  @State currentMonth: number = DateUtils.getCurrentMonth();
  @State budgetAmount: number = 0;
  @State @Watch('onBudgetProgressChange') budgetProgress: BudgetProgress = { budget: 0, spent: 0, remaining: 0, percent: 0 };
  @State showSetBudgetDialog: boolean = false;
  @State inputBudget: string = '';
  @State historyList: BudgetProgress[] = [];
  @State historyMonths: string[] = [];
  @State isSaving: boolean = false;
  @State currentBreakpoint: LedgerBreakpoint = LedgerBreakpoint.COMPACT;

  private budgetService: BudgetService = new BudgetService();
  private statisticsService: StatisticsService = new StatisticsService();
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);
  private isCanvasReady: boolean = false;
  private dataRequestId: number = 0;

  async aboutToAppear(): Promise<void> {
    await this.reloadMonthData();
  }

  private async reloadMonthData(): Promise<void> {
    const requestId = ++this.dataRequestId;
    const year = this.currentYear;
    const month = this.currentMonth;
    try {
      const context = getContext(this) as Context;
      const budgetAmount = await this.budgetService.getBudget(context, year, month);
      const budgetProgress = await this.budgetService.getBudgetProgress(context, year, month);
      const historyList: BudgetProgress[] = [];
      const historyMonths: string[] = [];
      const historyEndMonth = year === DateUtils.getCurrentYear() ? DateUtils.getCurrentMonth() : 12;
      for (let historyMonth = historyEndMonth; historyMonth >= 1; historyMonth--) {
        const progress = await this.budgetService.getBudgetProgress(context, year, historyMonth);
        if (progress.budget > 0) {
          historyList.push(progress);
          historyMonths.push(DateUtils.formatMonthDisplay(year, historyMonth));
        }
      }
      if (requestId !== this.dataRequestId) {
        return;
      }
      this.budgetAmount = budgetAmount;
      this.budgetProgress = budgetProgress;
      this.historyList = historyList;
      this.historyMonths = historyMonths;
    } catch (error) {
      if (requestId === this.dataRequestId) {
        promptAction.showToast({ message: $r('app.string.ledger_load_fail'), duration: 2000 });
      }
    }
  }

  private onBudgetProgressChange(): void {
    if (this.budgetAmount > 0 && this.isCanvasReady) {
      this.drawProgressRing();
    }
  }

  private async saveBudget(): Promise<void> {
    if (this.isSaving) return;
    const amountText = this.inputBudget.trim();
    const amount = Number(amountText);
    if (!/^(?:\d+(?:\.\d{1,2})?|\.\d{1,2})$/.test(amountText) || !isFinite(amount) || amount <= 0) {
      promptAction.showToast({ message: $r('app.string.ledger_amount_required'), duration: 1500 });
      return;
    }
    const context = getContext(this) as Context;
    this.isSaving = true;
    try {
      await this.budgetService.setBudget(context, this.currentYear, this.currentMonth, amount);
      this.showSetBudgetDialog = false;
      this.inputBudget = '';
      promptAction.showToast({ message: $r('app.string.ledger_budget_save_success'), duration: 1500 });
      await this.reloadMonthData();
    } catch (error) {
      promptAction.showToast({ message: $r('app.string.ledger_save_fail'), duration: 2000 });
    } finally {
      this.isSaving = false;
    }
  }

  private switchMonth(delta: number): void {
    this.currentMonth += delta;
    if (this.currentMonth > 12) {
      this.currentMonth = 1;
      this.currentYear += 1;
    } else if (this.currentMonth < 1) {
      this.currentMonth = 12;
      this.currentYear -= 1;
    }
    this.reloadMonthData();
  }

  private drawProgressRing(): void {
    const ctx = this.canvasContext;
    const size = 200;
    const centerX = size / 2;
    const centerY = size / 2;
    const radius = 76;
    const lineWidth = 12;
    const startAngle = -Math.PI / 2;
    const fullAngle = 2 * Math.PI;

    ctx.clearRect(0, 0, size, size);

    // Background ring
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, 0, fullAngle);
    ctx.lineWidth = lineWidth;
    ctx.strokeStyle = ledgerColor('ledger_progress_bg');
    ctx.lineCap = 'round';
    ctx.stroke();

    // Progress
    if (this.budgetProgress.percent > 0) {
      const drawPercent = Math.min(this.budgetProgress.percent, 1.0);
      const progressAngle = startAngle + fullAngle * drawPercent;
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, startAngle, progressAngle);
      ctx.lineWidth = lineWidth;
      ctx.strokeStyle = this.budgetProgress.percent >= 1.0 ?
        ledgerColor('ledger_progress_danger') :
        this.budgetProgress.percent >= 0.8 ?
        ledgerColor('ledger_progress_warning') :
        ledgerColor('ledger_progress_safe');
      ctx.lineCap = 'round';
      ctx.stroke();
    }

    // Center text
    ctx.fillStyle = ledgerColor('ledger_ink');
    ctx.font = 'bold 48px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(`${Math.round(this.budgetProgress.percent * 100)}%`, centerX, centerY - 10);

    ctx.fillStyle = ledgerColor('ledger_muted');
    ctx.font = '22px sans-serif';
    ctx.fillText(this.getResourceString($r('app.string.ledger_budget_used')), centerX, centerY + 20);
  }

  private getResourceString(resource: Resource): string {
    const context = getContext(this) as Context;
    return context.resourceManager.getStringSync(resource);
  }

  private getResourceColorString(resource: Resource): string {
    const context = getContext(this) as Context;
    const colorValue = context.resourceManager.getColorSync(resource);
    const rgb = (colorValue & 0x00FFFFFF).toString(16).toUpperCase();
    return `#${'000000'.substring(rgb.length)}${rgb}`;
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

        Text($r('app.string.ledger_budget_manage'))
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
          // Month selector
          Row() {
            Text($r('app.string.ledger_previous_month'))
              .fontSize(22)
              .fontColor(ledgerColor('ledger_primary_color'))
              .padding(8)
              .onClick(() => { this.switchMonth(-1); })

            Text(DateUtils.formatMonthDisplay(this.currentYear, this.currentMonth))
              .fontSize(Constants.FONT_BODY)
              .fontWeight(FontWeight.Medium)
              .fontColor(ledgerColor('ledger_ink'))
              .padding({ left: 16, right: 16 })

            Text($r('app.string.ledger_next_month'))
              .fontSize(22)
              .fontColor(ledgerColor('ledger_primary_color'))
              .padding(8)
              .onClick(() => { this.switchMonth(1); })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 16 })

          // Progress ring
          Column() {
            if (this.budgetAmount > 0) {
              Canvas(this.canvasContext)
                .width(200)
                .height(200)
                .onReady(() => {
                  this.isCanvasReady = true;
                  this.drawProgressRing();
                })
                .margin({ top: 16 })

              // Budget info
              Row() {
                Column() {
                  Text($r('app.string.ledger_budget_title'))
                    .fontSize(Constants.FONT_SMALL)
                    .fontColor(ledgerColor('ledger_muted'))
                  Text(NumberUtils.formatAmount(this.budgetProgress.budget))
                    .fontSize(Constants.FONT_BODY)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(ledgerColor('ledger_ink'))
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)

                Column() {
                  Text($r('app.string.ledger_budget_spent'))
                    .fontSize(Constants.FONT_SMALL)
                    .fontColor(ledgerColor('ledger_muted'))
                  Text(NumberUtils.formatAmount(this.budgetProgress.spent))
                    .fontSize(Constants.FONT_BODY)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(ledgerColor('ledger_expense_red'))
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)

                Column() {
                  Text($r('app.string.ledger_budget_remaining'))
                    .fontSize(Constants.FONT_SMALL)
                    .fontColor(ledgerColor('ledger_muted'))
                  Text(NumberUtils.formatAmount(this.budgetProgress.remaining))
                    .fontSize(Constants.FONT_BODY)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.budgetProgress.remaining >= 0 ?
                      ledgerColor('ledger_income_green') : ledgerColor('ledger_expense_red'))
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
              }
              .width('100%')
              .padding({ top: 20, bottom: 16 })
            } else {
              // Empty state
              Column() {
                Column()
                  .width(64)
                  .height(64)
                  .borderRadius(32)
                  .backgroundColor(ledgerColor('ledger_primary_light'))
                  .margin({ top: 32 })

                Text($r('app.string.ledger_budget_empty'))
                  .fontSize(Constants.FONT_BODY)
                  .fontColor(ledgerColor('ledger_muted'))
                  .margin({ top: 14 })
                Text($r('app.string.ledger_budget_tip'))
                  .fontSize(Constants.FONT_CAPTION)
                  .fontColor(ledgerColor('ledger_muted'))
                  .margin({ top: 4 })
              }
              .width('100%')
              .padding({ bottom: 20 })
            }

            // Set budget button
            Button(this.budgetAmount > 0 ? $r('app.string.ledger_budget_modify') : $r('app.string.ledger_budget_set'))
              .width('80%')
              .height(48)
              .fontSize(Constants.FONT_BODY)
              .fontWeight(FontWeight.Medium)
                .fontColor(ledgerColor('ledger_card_text_primary'))
              .borderRadius(Constants.RADIUS_MD)
              .backgroundColor(ledgerColor('ledger_primary_color'))
              .margin({ top: 16 })
              .onClick(() => {
                this.showSetBudgetDialog = true;
              })
          }
          .width('100%')
          .backgroundColor(ledgerColor('ledger_surface'))
          .borderRadius(Constants.RADIUS_MD)
          .margin({ left: 16, right: 16, top: 16 })
          .padding({ left: 16, right: 16, top: 8, bottom: 20 })

          // History
          if (this.historyList.length > 0) {
            Text($r('app.string.ledger_budget_history'))
              .fontSize(Constants.FONT_SUBTITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(ledgerColor('ledger_ink'))
              .width('100%')
              .padding({ left: 16, top: 24, bottom: 10 })

            Column() {
              ForEach(this.historyMonths, (monthLabel: string, index: number) => {
                Row() {
                  Text(monthLabel)
                    .fontSize(Constants.FONT_BODY)
                    .fontColor(ledgerColor('ledger_ink'))
                    .layoutWeight(1)

                  Text(`${Math.round(this.historyList[index].percent * 100)}%`)
                    .fontSize(Constants.FONT_BODY)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.historyList[index].percent >= 1.0 ?
                      ledgerColor('ledger_expense_red') :
                      this.historyList[index].percent >= 0.8 ?
                      ledgerColor('ledger_progress_warning') :
                      ledgerColor('ledger_income_green'))
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })

                if (index < this.historyMonths.length - 1) {
                  Divider().color(ledgerColor('ledger_divider')).margin({ left: 16 })
                }
              }, (label: string) => label)
            }
            .backgroundColor(ledgerColor('ledger_surface'))
            .borderRadius(Constants.RADIUS_MD)
            .margin({ left: 16, right: 16 })
          }

          Column().height(32)
          Column().height(minimumBottomControlInsetVp(this.safeAreaBottom))
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // Set budget dialog
      if (this.showSetBudgetDialog) {
        this.SetBudgetDialog()
      }
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

  @Builder
  SetBudgetDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ledgerColor('ledger_dialog_overlay'))
        .onClick(() => { this.showSetBudgetDialog = false; })

      Stack({ alignContent: Alignment.Center }) {
        Column() {
          Text($r('app.string.ledger_budget_dialog_title'))
            .fontSize(Constants.FONT_SUBTITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(ledgerColor('ledger_ink'))
            .margin({ bottom: 16 })

          TextInput({ placeholder: $r('app.string.ledger_budget_amount_placeholder'), text: this.inputBudget })
            .width('100%')
            .height(44)
            .fontColor(ledgerColor('ledger_ink'))
            .placeholderColor(ledgerColor('ledger_text_secondary'))
            .backgroundColor(ledgerColor('ledger_divider'))
            .borderRadius(Constants.RADIUS_SM)
            .type(InputType.Number)
            .margin({ bottom: 20 })
            .onChange((value: string) => { this.inputBudget = value; })

          Row() {
            Button($r('app.string.ledger_cancel'))
              .width('45%')
              .height(40)
              .backgroundColor(ledgerColor('ledger_divider'))
              .fontColor(ledgerColor('ledger_ink'))
              .borderRadius(Constants.RADIUS_SM)
              .onClick(() => { this.showSetBudgetDialog = false; })

            Button($r('app.string.ledger_confirm'))
              .width('45%')
              .height(40)
              .backgroundColor(ledgerColor('ledger_primary_color'))
              .fontColor(ledgerColor('ledger_card_text_primary'))
              .borderRadius(Constants.RADIUS_SM)
              .onClick(() => { this.saveBudget(); })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('85%')
        .constraintSize({ maxWidth: 480 })
        .padding(24)
        .backgroundColor(ledgerColor('ledger_surface'))
        .borderRadius(Constants.RADIUS_LG)
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: minimumBottomControlInsetVp(this.safeAreaBottom) })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }
}
