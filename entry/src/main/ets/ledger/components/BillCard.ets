import { BillRecord, BillType } from '../models/BillRecord';
import { Category } from '../models/Category';
import { NumberUtils } from '../common/NumberUtils';
import { Constants } from '../common/Constants';
import { ledgerColor } from '../common/LedgerTheme';
import router from '@ohos.router';
import { AppSymbol } from '../../components/AppSymbol';

@Component
export struct BillCard {
  @Prop bill: BillRecord;
  @Prop category: Category;
  onDelete?: (id: string) => void;
  @State scaleValue: number = 1;
  @StorageProp('refreshSignal') refreshSignal: number = 0;
  @StorageProp('ledgerDarkMode') ledgerDarkMode: boolean = false;

  build() {
    Row() {
      Column() {
        AppSymbol({ name: this.getCategoryIcon(), symbolSize: 22, color: this.getCategoryAccentColor() })
      }
      .width(44)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.getCategoryBgColor())
      .borderRadius(12)

      Column() {
        Text(this.getCategoryName())
          .fontSize(Constants.FONT_BODY)
          .fontColor(ledgerColor('ledger_ink'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.bill.note && this.bill.note.length > 0) {
          Text(this.bill.note)
            .fontSize(Constants.FONT_CAPTION)
            .fontColor(ledgerColor('ledger_muted'))
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .margin({ left: 12 })
      .layoutWeight(1)

      Column() {
        Text(this.getAmountText())
          .fontSize(this.getAmountFontSize())
          .fontColor(this.getAmountColor())
          .fontWeight(FontWeight.Bold)
          .maxLines(1)

        Text(this.getDateTimeText())
          .fontSize(Constants.FONT_SMALL)
          .fontColor(ledgerColor('ledger_muted'))
          .margin({ top: 4 })
          .maxLines(1)
      }
      .layoutWeight(1)
      .constraintSize({ minWidth: 136, maxWidth: 232 })
      .alignItems(HorizontalAlign.End)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(76)
    .padding({ left: 14, right: 14 })
    .backgroundColor(this.ledgerDarkMode ? ledgerColor('ledger_surface') : ledgerColor('ledger_surface'))
    .borderRadius(Constants.RADIUS_MD)
    .scale({ x: this.scaleValue, y: this.scaleValue })
    .animation({ duration: Constants.ANIM_DURATION_SHORT, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.scaleValue = 0.98;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.scaleValue = 1;
      }
    })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/ledger/LedgerEditBillPage',
        params: { bill: this.bill }
      });
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          if (this.onDelete) {
            AlertDialog.show({
              title: $r('app.string.ledger_delete_confirm_title'),
              message: $r('app.string.ledger_delete_confirm_message'),
              primaryButton: {
                value: $r('app.string.ledger_cancel'),
                action: () => {
                }
              },
              secondaryButton: {
                value: $r('app.string.ledger_delete'),
                fontColor: ledgerColor('ledger_expense_red'),
                action: () => {
                  if (this.onDelete) {
                    this.onDelete(this.bill.id);
                  }
                }
              }
            });
          }
        })
    )
  }

  private getCategoryIcon(): string {
    return this.category && this.category.icon ? this.category.icon : '';
  }

  private getCategoryName(): string | Resource {
    return this.category ? this.category.name : $r('app.string.ledger_other');
  }

  private getCategoryBgColor(): string {
    return this.category && this.category.color ?
      ledgerColor('ledger_category_bg') : ledgerColor('ledger_category_unselected_bg');
  }

  private getCategoryAccentColor(): string {
    return this.category && this.category.color ?
      this.category.color : ledgerColor('ledger_category_fallback');
  }

  private getAmountText(): string {
    const isExpense = this.bill.type === BillType.EXPENSE;
    return NumberUtils.formatAmountWithSign(this.bill.amount, isExpense);
  }

  private getAmountFontSize(): number {
    return this.getAmountText().length > 15 ? Constants.FONT_CAPTION : Constants.FONT_BODY;
  }

  private getAmountColor(): string {
    return this.bill.type === BillType.EXPENSE ? ledgerColor('ledger_expense_red') : ledgerColor('ledger_income_green');
  }

  private getDateTimeText(): string {
    const dateText = this.bill.date.length > 5 ? this.bill.date.substring(5).replace('-', '/') : this.bill.date;
    if (this.bill.createTime <= 0) {
      return dateText;
    }
    const time = new Date(this.bill.createTime);
    const hour = time.getHours() < 10 ? `0${time.getHours()}` : `${time.getHours()}`;
    const minute = time.getMinutes() < 10 ? `0${time.getMinutes()}` : `${time.getMinutes()}`;
    return `${dateText} ${hour}:${minute}`;
  }
}
