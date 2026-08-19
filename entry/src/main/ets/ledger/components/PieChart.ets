import { CategoryStat } from '../models/Statistics';
import { Constants } from '../common/Constants';
import { ledgerColor } from '../common/LedgerTheme';

@Component
export struct PieChart {
  @Prop @Watch('onStatsChange') stats: CategoryStat[];
  @Prop @Watch('onChartSizeChange') chartSize: number;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private isReady: boolean = false;

  private onStatsChange(): void {
    if (this.isReady) {
      this.drawPieChart();
    }
  }

  private onChartSizeChange(): void {
    if (!this.isReady) {
      return;
    }
    setTimeout(() => {
      if (this.isReady) {
        this.drawPieChart();
      }
    }, 0);
  }

  build() {
    Column() {
      Canvas(this.context)
        .width(this.chartSize)
        .height(this.chartSize)
        .onReady(() => {
          this.isReady = true;
          this.drawPieChart();
        })

      if (this.stats && this.stats.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
          ForEach(this.stats.slice(0, 6), (stat: CategoryStat) => {
            Row() {
              Row()
                .width(8)
                .height(8)
                .borderRadius(4)
                .backgroundColor(this.getCategoryColor(stat))
                .margin({ right: 4 })
              Text(stat.categoryName)
                .fontSize(16)
                .fontColor(ledgerColor('ledger_muted'))
            }
            .margin({ left: 8, right: 8, top: 6 })
          }, (stat: CategoryStat) => stat.categoryId)
        }
        .width('100%')
        .margin({ top: 12 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  private drawPieChart(): void {
    const centerX = this.chartSize / 2;
    const centerY = this.chartSize / 2;
    const radius = this.chartSize / 2 - 16;
    const innerRadius = radius * 0.58;
    const gap = 0.02;

    this.context.clearRect(0, 0, this.chartSize, this.chartSize);

    if (!this.stats || this.stats.length === 0) {
      this.drawEmptyChart(centerX, centerY, radius, innerRadius);
      return;
    }

    let startAngle = -Math.PI / 2;

    for (let i = 0; i < this.stats.length; i++) {
      const stat = this.stats[i];
      const sweepAngle = stat.percentage * 2 * Math.PI - gap;
      if (sweepAngle <= 0) continue;

      this.context.beginPath();
      this.context.arc(centerX, centerY, radius, startAngle, startAngle + sweepAngle);
      this.context.arc(centerX, centerY, innerRadius, startAngle + sweepAngle, startAngle, true);
      this.context.closePath();
      this.context.fillStyle = this.getCategoryColor(stat);
      this.context.fill();

      startAngle += sweepAngle + gap;
    }

    // Inner circle
    this.context.beginPath();
    this.context.arc(centerX, centerY, innerRadius - 1, 0, 2 * Math.PI);
    this.context.fillStyle = ledgerColor('ledger_surface');
    this.context.fill();

    // Center text
    if (this.stats.length > 0) {
      this.context.font = `bold ${this.getUIContext().vp2px(14)}px sans-serif`;
      this.context.fillStyle = ledgerColor('ledger_ink');
      this.context.textAlign = 'center';
      this.context.textBaseline = 'middle';
      this.context.fillText(
        this.getResourceString($r('app.string.ledger_chart_category_count'), this.stats.length),
        centerX,
        centerY
      );
    }
  }

  private drawEmptyChart(centerX: number, centerY: number, radius: number, innerRadius: number): void {
    this.context.beginPath();
    this.context.arc(centerX, centerY, radius, 0, 2 * Math.PI);
    this.context.arc(centerX, centerY, innerRadius, 0, 2 * Math.PI, true);
    this.context.closePath();
    this.context.fillStyle = ledgerColor('ledger_progress_bg');
    this.context.fill();

    this.context.beginPath();
    this.context.arc(centerX, centerY, innerRadius - 1, 0, 2 * Math.PI);
    this.context.fillStyle = ledgerColor('ledger_surface');
    this.context.fill();

    this.context.font = '13px sans-serif';
    this.context.fillStyle = ledgerColor('ledger_muted');
    this.context.textAlign = 'center';
    this.context.textBaseline = 'middle';
    this.context.fillText(this.getResourceString($r('app.string.ledger_chart_empty')), centerX, centerY);
  }

  private getCategoryColor(stat: CategoryStat): string {
    return stat.categoryColor || ledgerColor('ledger_category_fallback');
  }

  private getResourceString(resource: Resource, ...args: Array<string | number>): string {
    const context = getContext(this) as Context;
    return context.resourceManager.getStringSync(resource, ...args);
  }

  private getResourceColorString(resource: Resource): string {
    const context = getContext(this) as Context;
    const colorValue = context.resourceManager.getColorSync(resource);
    const rgb = (colorValue & 0x00FFFFFF).toString(16).toUpperCase();
    return `#${'000000'.substring(rgb.length)}${rgb}`;
  }
}
