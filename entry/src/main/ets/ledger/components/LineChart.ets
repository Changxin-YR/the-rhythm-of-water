import { BillType } from '../models/BillRecord';
import { DaySummary } from '../models/Statistics';
import { NumberUtils } from '../common/NumberUtils';
import { ledgerColor } from '../common/LedgerTheme';

@Component
export struct LineChart {
  @Prop @Watch('onDataChange') data: DaySummary[];
  @Prop @Watch('onSelectedTypeChange') selectedType: BillType;
  @Prop chartWidth: number;
  @Prop chartHeight: number;
  @State selectedIndex: number = -1;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private isReady: boolean = false;

  build() {
    Column() {
      Canvas(this.context)
        .width(this.chartWidth)
        .height(this.chartHeight)
        .onReady(() => {
          this.isReady = true;
          this.drawLineChart();
        })
        .onTouch((event: TouchEvent) => {
          this.handleCanvasTouch(event);
        })
    }
    .width(this.chartWidth)
    .height(this.chartHeight)
  }

  private onDataChange(): void {
    if (this.selectedIndex >= this.data.length) {
      this.selectedIndex = -1;
    }
    if (this.isReady) {
      this.drawLineChart();
    }
  }

  private onSelectedTypeChange(): void {
    this.selectedIndex = -1;
    if (this.isReady) {
      this.drawLineChart();
    }
  }

  private drawLineChart(): void {
    this.context.clearRect(0, 0, this.chartWidth, this.chartHeight);
    if (!this.data || this.data.length === 0) {
      this.drawEmptyState();
      return;
    }

    const plotLeft = 46;
    const plotTop = 28;
    const plotWidth = this.chartWidth - plotLeft - 14;
    const plotHeight = this.chartHeight - plotTop - 34;
    const values = this.getSelectedValues();
    const maxValue = this.getYAxisMax(values);

    this.drawGrid(plotLeft, plotTop, plotWidth, plotHeight);
    this.drawYAxisLabels(maxValue, plotLeft, plotTop, plotHeight);
    this.drawZeroBaseline(plotLeft, plotWidth, plotTop + plotHeight);
    this.drawLine(values, maxValue, plotLeft, plotTop, plotWidth, plotHeight, this.getSelectedColor());
    this.drawDateLabels(plotLeft, plotTop, plotWidth, plotHeight);

    if (this.selectedIndex >= 0 && this.selectedIndex < this.data.length) {
      this.drawSelectedPoint(this.selectedIndex, values, maxValue, plotLeft, plotTop, plotWidth, plotHeight);
    }
  }

  private getSelectedValues(): number[] {
    return this.data.map((item: DaySummary) => {
      return this.selectedType === BillType.EXPENSE ? item.totalExpense : item.totalIncome;
    });
  }

  private getYAxisMax(values: number[]): number {
    let maximum = 0;
    for (const value of values) {
      maximum = Math.max(maximum, value);
    }
    if (maximum <= 0) {
      return 100;
    }
    let magnitude = 1;
    while (maximum / magnitude > 10) {
      magnitude *= 10;
    }
    return Math.ceil(maximum / magnitude) * magnitude;
  }

  private drawGrid(plotLeft: number, plotTop: number, plotWidth: number, plotHeight: number): void {
    this.context.strokeStyle = this.getGridColor();
    this.context.lineWidth = 0.5;
    for (let index = 0; index <= 4; index++) {
      const y = plotTop + (plotHeight / 4) * index;
      this.context.beginPath();
      this.context.moveTo(plotLeft, y);
      this.context.lineTo(plotLeft + plotWidth, y);
      this.context.stroke();
    }
  }

  private drawYAxisLabels(maxValue: number, plotLeft: number, plotTop: number, plotHeight: number): void {
    this.context.font = '11px sans-serif';
    this.context.fillStyle = this.getTextColor();
    this.context.textAlign = 'right';
    this.context.textBaseline = 'middle';
    for (let index = 0; index <= 4; index++) {
      const value = maxValue - (maxValue / 4) * index;
      const y = plotTop + (plotHeight / 4) * index;
      this.context.fillText(this.formatAxisAmount(value), plotLeft - 7, y);
    }
  }

  private formatAxisAmount(value: number): string {
    if (value === Math.floor(value)) {
      return value.toFixed(0);
    }
    return value.toFixed(1);
  }

  private drawZeroBaseline(plotLeft: number, plotWidth: number, baselineY: number): void {
    this.context.strokeStyle = this.getTextColor();
    this.context.lineWidth = 1;
    this.context.beginPath();
    this.context.moveTo(plotLeft, baselineY);
    this.context.lineTo(plotLeft + plotWidth, baselineY);
    this.context.stroke();
  }

  private drawLine(values: number[], maxValue: number, plotLeft: number, plotTop: number,
    plotWidth: number, plotHeight: number, color: string): void {
    if (values.length === 0) {
      return;
    }
    this.context.strokeStyle = color;
    this.context.lineWidth = 2;
    this.context.lineJoin = 'round';
    this.context.beginPath();
    for (let index = 0; index < values.length; index++) {
      const x = this.getPointX(index, values.length, plotLeft, plotWidth);
      const y = this.getPointY(values[index], maxValue, plotTop, plotHeight);
      if (index === 0) {
        this.context.moveTo(x, y);
      } else {
        this.context.lineTo(x, y);
      }
    }
    this.context.stroke();

    this.context.fillStyle = color;
    for (let index = 0; index < values.length; index++) {
      const x = this.getPointX(index, values.length, plotLeft, plotWidth);
      const y = this.getPointY(values[index], maxValue, plotTop, plotHeight);
      this.context.beginPath();
      this.context.arc(x, y, 3.5, 0, 2 * Math.PI);
      this.context.fill();
    }
  }

  private drawDateLabels(plotLeft: number, plotTop: number, plotWidth: number, plotHeight: number): void {
    this.context.font = '11px sans-serif';
    this.context.fillStyle = this.getTextColor();
    this.context.textAlign = 'center';
    this.context.textBaseline = 'alphabetic';
    for (let index = 0; index < this.data.length; index++) {
      if (this.shouldDrawDateLabel(index)) {
        const x = this.getPointX(index, this.data.length, plotLeft, plotWidth);
        this.context.fillText(this.getDateLabel(this.data[index].date), x, plotTop + plotHeight + 22);
      }
    }
  }

  private drawSelectedPoint(index: number, values: number[], maxValue: number, plotLeft: number,
    plotTop: number, plotWidth: number, plotHeight: number): void {
    const x = this.getPointX(index, values.length, plotLeft, plotWidth);
    const y = this.getPointY(values[index], maxValue, plotTop, plotHeight);
    const color = this.getSelectedColor();

    this.context.strokeStyle = this.getGridColor();
    this.context.lineWidth = 1;
    this.context.beginPath();
    this.context.moveTo(x, plotTop);
    this.context.lineTo(x, plotTop + plotHeight);
    this.context.stroke();

    this.context.fillStyle = this.getTooltipBackgroundColor();
    this.context.beginPath();
    this.context.arc(x, y, 8, 0, 2 * Math.PI);
    this.context.fill();
    this.context.fillStyle = color;
    this.context.beginPath();
    this.context.arc(x, y, 5, 0, 2 * Math.PI);
    this.context.fill();
    this.drawTooltip(this.data[index], values[index], x, y);
  }

  private drawTooltip(day: DaySummary, amount: number, pointX: number, pointY: number): void {
    const tooltipWidth = 188;
    const tooltipHeight = 88;
    let tooltipX = pointX + 12;
    let tooltipY = pointY - tooltipHeight - 12;
    if (tooltipX + tooltipWidth > this.chartWidth - 6) {
      tooltipX = pointX - tooltipWidth - 12;
    }
    if (tooltipY < 6) {
      tooltipY = pointY + 12;
    }
    if (tooltipY + tooltipHeight > this.chartHeight - 6) {
      tooltipY = this.chartHeight - tooltipHeight - 6;
    }

    this.context.fillStyle = this.getTooltipBackgroundColor();
    this.context.fillRect(tooltipX, tooltipY, tooltipWidth, tooltipHeight);
    this.context.strokeStyle = this.getTooltipBorderColor();
    this.context.lineWidth = 2;
    this.context.strokeRect(tooltipX, tooltipY, tooltipWidth, tooltipHeight);

    this.context.textAlign = 'left';
    this.context.textBaseline = 'alphabetic';
    this.context.font = '14px sans-serif';
    this.context.fillStyle = this.getTooltipTextColor();
    this.context.fillText(this.getDateLabel(day.date), tooltipX + 14, tooltipY + 24);
    this.context.font = 'bold 14px sans-serif';
    this.context.fillStyle = this.getTooltipSubtextColor();
    this.context.fillText(this.getSelectedTotalLabel(), tooltipX + 14, tooltipY + 48);
    this.context.font = 'bold 26px sans-serif';
    this.context.fillStyle = this.getSelectedColor();
    this.context.fillText(this.formatCurrency(amount), tooltipX + 14, tooltipY + 78);
  }

  private handleCanvasTouch(event: TouchEvent): void {
    if (event.type !== TouchType.Up || !this.data || this.data.length === 0 || event.changedTouches.length === 0) {
      return;
    }
    const plotLeft = 46;
    const plotTop = 28;
    const plotWidth = this.chartWidth - plotLeft - 14;
    const plotHeight = this.chartHeight - plotTop - 34;
    const values = this.getSelectedValues();
    const maxValue = this.getYAxisMax(values);
    const touch = event.changedTouches[0];
    const nextIndex = this.findTouchedPoint(touch.x, touch.y, values, maxValue, plotLeft, plotTop, plotWidth, plotHeight);
    if (nextIndex !== -1) {
      this.selectedIndex = nextIndex;
      this.drawLineChart();
    }
  }

  private findTouchedPoint(touchX: number, touchY: number, values: number[], maxValue: number,
    plotLeft: number, plotTop: number, plotWidth: number, plotHeight: number): number {
    let nearestIndex = -1;
    let nearestDistance = 22;
    for (let index = 0; index < values.length; index++) {
      const x = this.getPointX(index, values.length, plotLeft, plotWidth);
      const y = this.getPointY(values[index], maxValue, plotTop, plotHeight);
      const distance = Math.sqrt((touchX - x) * (touchX - x) + (touchY - y) * (touchY - y));
      if (distance <= nearestDistance) {
        nearestDistance = distance;
        nearestIndex = index;
      }
    }
    return nearestIndex;
  }

  private getPointX(index: number, count: number, plotLeft: number, plotWidth: number): number {
    if (count <= 1) {
      return plotLeft + plotWidth / 2;
    }
    return plotLeft + (plotWidth / (count - 1)) * index;
  }

  private getPointY(value: number, maxValue: number, plotTop: number, plotHeight: number): number {
    return plotTop + plotHeight - (value / maxValue) * plotHeight;
  }

  private getDateLabel(date: string): string {
    const parts = date.split('-');
    return `${parseInt(parts[1])}/${parseInt(parts[2])}`;
  }

  private shouldDrawDateLabel(index: number): boolean {
    const labelInterval = Math.max(1, Math.ceil(this.data.length / 6));
    return index === this.data.length - 1 || index % labelInterval === 0;
  }

  private getSelectedColor(): string {
    return this.selectedType === BillType.EXPENSE ? this.getExpenseColor() : this.getIncomeColor();
  }

  private getSelectedTotalLabel(): string {
    return this.selectedType === BillType.EXPENSE
      ? this.getResourceString($r('app.string.ledger_chart_total_expense'))
      : this.getResourceString($r('app.string.ledger_chart_total_income'));
  }

  private formatCurrency(amount: number): string {
    return NumberUtils.formatAmount(amount);
  }

  private getGridColor(): string {
    return ledgerColor('ledger_progress_bg');
  }

  private getExpenseColor(): string {
    return ledgerColor('ledger_expense_red');
  }

  private getIncomeColor(): string {
    return ledgerColor('ledger_income_green');
  }

  private getTextColor(): string {
    return ledgerColor('ledger_text_secondary');
  }

  private getTooltipBackgroundColor(): string {
    return this.selectedType === BillType.EXPENSE ?
      ledgerColor('ledger_expense_soft') :
      ledgerColor('ledger_income_soft');
  }

  private getTooltipBorderColor(): string {
    return this.getSelectedColor();
  }

  private getTooltipTextColor(): string {
    return ledgerColor('ledger_ink');
  }

  private getTooltipSubtextColor(): string {
    return ledgerColor('ledger_muted');
  }

  private drawEmptyState(): void {
    this.context.font = '13px sans-serif';
    this.context.fillStyle = this.getTextColor();
    this.context.textAlign = 'center';
    this.context.textBaseline = 'middle';
    this.context.fillText(this.getResourceString($r('app.string.ledger_no_bills')), this.chartWidth / 2, this.chartHeight / 2);
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
}
