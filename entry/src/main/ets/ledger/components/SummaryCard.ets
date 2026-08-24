import { Constants } from '../common/Constants';
import { ResponsiveUtils } from '../common/ResponsiveUtils';
import { ledgerColor } from '../common/LedgerTheme';

@Component
export struct SummaryCard {
  @Prop totalIncome: number;
  @Prop totalExpense: number;
  @Prop title: string;
  @Prop illustration: Resource = $r('app.media.ledger_wallet_illustration');
  @State isCompact: boolean = false;
  @StorageProp('refreshSignal') refreshSignal: number = 0;
  @StorageProp('ledgerDarkMode') ledgerDarkMode: boolean = false;

  build() {
    Column() {
      if (this.isCompact) {
        Column() {
          this.BalanceText()
          Image(this.illustration)
            .width(88)
            .height(58)
            .objectFit(ImageFit.Contain)
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      } else {
        Row() {
          Column() {
            this.BalanceText()
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Image(this.illustration)
            .width(104)
            .height(78)
            .objectFit(ImageFit.Contain)
            .margin({ left: 12, top: 2 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }

      Row()
        .width('100%')
        .height(1)
        .backgroundColor(ledgerColor('ledger_divider'))
        .margin({ top: 18, bottom: 16 })

      Row() {
        Column() {
          Text($r('app.string.ledger_income'))
            .fontSize(Constants.FONT_SMALL)
            .fontColor(ledgerColor('ledger_muted'))
          Row() {
            Text($r('app.string.ledger_currency'))
              .fontSize(Constants.FONT_SMALL)
              .fontColor(ledgerColor('ledger_income_green'))
            Text(this.formatNumber(this.totalIncome))
              .fontSize(Constants.FONT_SUBTITLE)
              .fontColor(ledgerColor('ledger_income_green'))
              .fontWeight(FontWeight.Medium)
              .margin({ left: 2 })
          }
          .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text($r('app.string.ledger_expense'))
            .fontSize(Constants.FONT_SMALL)
            .fontColor(ledgerColor('ledger_muted'))
          Row() {
            Text($r('app.string.ledger_currency'))
              .fontSize(Constants.FONT_SMALL)
              .fontColor(ledgerColor('ledger_expense_red'))
            Text(this.formatNumber(this.totalExpense))
              .fontSize(Constants.FONT_SUBTITLE)
              .fontColor(ledgerColor('ledger_expense_red'))
              .fontWeight(FontWeight.Medium)
              .margin({ left: 2 })
          }
          .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 22, right: 22, top: 20, bottom: 20 })
    .borderRadius(Constants.RADIUS_LG)
    .backgroundColor(ledgerColor('ledger_surface'))
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.isCompact = ResponsiveUtils.toViewportWidth(newValue.width, (value: number) => this.getUIContext().px2vp(value)) < 520;
    })
  }

  @Builder
  BalanceText() {
    Text(this.title)
      .fontSize(Constants.FONT_CAPTION)
      .fontColor(ledgerColor('ledger_muted'))
      .fontWeight(FontWeight.Medium)
      .maxLines(1)

    Text($r('app.string.ledger_balance'))
      .fontSize(Constants.FONT_SMALL)
      .fontColor(ledgerColor('ledger_muted'))
      .margin({ top: 16 })

    Row() {
      Text($r('app.string.ledger_currency'))
        .fontSize(18)
        .fontColor(ledgerColor('ledger_ink'))
        .fontWeight(FontWeight.Medium)
        .margin({ right: 4, bottom: 4 })
      Text(this.formatBalance())
        .fontSize(this.getBalanceFontSize())
        .fontColor(ledgerColor('ledger_ink'))
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
    }
    .alignItems(VerticalAlign.Bottom)
    .margin({ top: 4 })
  }

  private formatBalance(): string {
    return this.formatNumber(this.totalIncome - this.totalExpense);
  }

  private getBalanceFontSize(): number {
    const length = this.formatBalance().length;
    if (this.isCompact && length > 15) {
      return 22;
    }
    if (this.isCompact && length > 12) {
      return 26;
    }
    return this.isCompact ? 30 : 34;
  }

  private formatNumber(amount: number): string {
    const sign = amount < 0 ? '-' : '';
    const roundedCents = Math.round(Math.abs(amount) * 100);
    const integerPart = Math.floor(roundedCents / 100);
    const decimalPart = roundedCents % 100;
    const formattedDecimal = decimalPart < 10 ? `0${decimalPart}` : `${decimalPart}`;
    return `${sign}${this.addThousandSep(integerPart)}.${formattedDecimal}`;
  }

  private addThousandSep(num: number): string {
    const str = num.toString();
    const result: string[] = [];
    let count = 0;
    for (let i = str.length - 1; i >= 0; i--) {
      count++;
      result.unshift(str[i]);
      if (count % 3 === 0 && i !== 0) {
        result.unshift(',');
      }
    }
    return result.join('');
  }
}
