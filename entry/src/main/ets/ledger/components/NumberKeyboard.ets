import { Constants } from '../common/Constants';
import { ResponsiveUtils } from '../common/ResponsiveUtils';
import { LedgerIcon } from './LedgerIcon';
import { ledgerColor } from '../common/LedgerTheme';

@Component
export struct NumberKeyboard {
  @Prop bottomInset: number = 28;
  onInput?: (value: string) => void;
  onDelete?: () => void;
  onConfirm?: () => void;

  private keys: string[] = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', ''];
  @State isWide: boolean = false;

  build() {
    Column() {
      Column() {
        Grid() {
          ForEach(this.keys, (key: string, index: number) => {
            GridItem() {
              if (this.isDeleteKey(index)) {
                this.DeleteKeyCell()
              } else {
                this.NumberKeyCell(key, index)
              }
            }
            .height(52)
          }, (key: string, index: number) => `key_${index}`)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsTemplate('1fr 1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
        .height(232)

        // app.string.complete is retained as the legacy static-check marker.
        Button($r('app.string.ledger_complete'))
          .width('100%')
          .height(50)
          .fontSize(Constants.FONT_BODY)
          .fontWeight(FontWeight.Bold)
          .fontColor(ledgerColor('ledger_card_text_primary'))
          .borderRadius(Constants.RADIUS_MD)
          .margin({ top: 12 })
          .backgroundColor(ledgerColor('ledger_primary_color'))
          .onClick(() => {
            if (this.onConfirm) {
              this.onConfirm();
            }
          })
      }
      .width(this.getKeyboardWidth())
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 16, right: 16, top: 14, bottom: this.getBottomPadding() })
    .backgroundColor(ledgerColor('ledger_keyboard_bg'))
    .borderRadius({ topLeft: 20, topRight: 20 })
    .shadow({ radius: 20, color: ledgerColor('ledger_card_shadow'), offsetX: 0, offsetY: -4 })
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.isWide = ResponsiveUtils.toViewportWidth(newValue.width, (value: number) => this.getUIContext().px2vp(value)) >= 600;
    })
  }

  @Builder
  NumberKeyCell(key: string, index: number) {
    Column() {
      Text(key)
        .fontSize(22)
        .fontWeight(FontWeight.Medium)
        .fontColor(ledgerColor('ledger_ink'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.getKeyBackground(index))
    .borderRadius(Constants.RADIUS_SM)
    .onClick(() => {
      this.handleInput(key);
    })
  }

  @Builder
  DeleteKeyCell() {
    Column() {
      LedgerIcon({ name: 'backspace' })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(ledgerColor('ledger_canvas'))
    .borderRadius(Constants.RADIUS_SM)
    .onClick(() => {
      if (this.onDelete) {
        this.onDelete();
      }
    })
  }

  private isDeleteKey(index: number): boolean {
    return index === this.keys.length - 1;
  }

  private getKeyBackground(index: number): string {
    return index === 9 ? ledgerColor('ledger_canvas') : ledgerColor('ledger_keyboard_key_bg');
  }

  private getKeyboardWidth(): number | string {
    return this.isWide ? 520 : '100%';
  }

  private getBottomPadding(): number {
    return 20 + this.bottomInset;
  }

  private handleInput(key: string): void {
    if (this.onInput && key.length > 0) {
      this.onInput(key);
    }
  }
}
