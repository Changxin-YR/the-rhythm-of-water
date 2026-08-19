import { BillRecord, BillType } from '../models/BillRecord';
import { Category } from '../models/Category';
import { BillService } from '../services/BillService';
import { CategoryService } from '../services/CategoryService';
import { StreakService } from '../services/StreakService';
import { CategoryGrid } from '../components/CategoryGrid';
import { NumberKeyboard } from '../components/NumberKeyboard';
import { Constants } from '../common/Constants';
import { DateUtils } from '../common/DateUtils';
import { LedgerBreakpoint, ResponsiveUtils } from '../common/ResponsiveUtils';
import router from '@ohos.router';
import util from '@ohos.util';
import promptAction from '@ohos.promptAction';
import hilog from '@ohos.hilog';
import { minimumBottomControlInsetVp } from '../../common/SafeAreaRules';
import { ledgerColor } from '../common/LedgerTheme';

const ADD_BILL_DOMAIN = 0xFF01;
const ADD_BILL_TAG = 'AddBillPage';

interface AddBillParams {
  presetCategoryId?: string;
}

@Component
export struct LedgerAddBillPage {
  @State billType: BillType = BillType.EXPENSE;
  @StorageProp('safeAreaTop') safeAreaTop: number = 0;
  @StorageProp('safeAreaBottom') safeAreaBottom: number = 0;
  @State amount: string = '';
  @State selectedCategory: Category | null = null;
  @State note: string = '';
  @State isNoteFocused: boolean = false;
  @State selectedDate: string = DateUtils.getToday();
  @State categories: Category[] = [];
  @State expenseCategories: Category[] = [];
  @State incomeCategories: Category[] = [];
  @State isSaving: boolean = false;
  @State currentBreakpoint: LedgerBreakpoint = LedgerBreakpoint.COMPACT;

  private billService: BillService = new BillService();
  private categoryService: CategoryService = new CategoryService();
  private streakService: StreakService = new StreakService();

  async aboutToAppear(): Promise<void> {
    try {
      await this.loadCategories();
      this.applyPresetCategory();
    } catch (error) {
      promptAction.showToast({ message: $r('app.string.ledger_load_fail'), duration: 2000 });
    }
  }

  private applyPresetCategory(): void {
    const params = router.getParams() as AddBillParams;
    if (params && params.presetCategoryId) {
      const allCats = [...this.expenseCategories, ...this.incomeCategories];
      const found = allCats.find(c => c.id === params.presetCategoryId);
      if (found) {
        this.billType = found.type;
        this.categories = found.type === BillType.EXPENSE ? this.expenseCategories : this.incomeCategories;
        this.selectedCategory = found;
      }
    }
  }

  private async loadCategories(): Promise<void> {
    this.expenseCategories = await this.categoryService.getCategoriesByType(BillType.EXPENSE);
    this.incomeCategories = await this.categoryService.getCategoriesByType(BillType.INCOME);
    this.categories = this.billType === BillType.EXPENSE ? this.expenseCategories : this.incomeCategories;
    if (this.categories.length > 0 && !this.selectedCategory) {
      this.selectedCategory = this.categories[0];
    }
  }

  private switchBillType(type: BillType): void {
    this.billType = type;
    this.categories = type === BillType.EXPENSE ? this.expenseCategories : this.incomeCategories;
    if (this.categories.length > 0) {
      this.selectedCategory = this.categories[0];
    } else {
      this.selectedCategory = null;
    }
  }

  private handleInput(value: string): void {
    if (value === '.' && this.amount.includes('.')) return;
    if (this.amount.includes('.')) {
      const parts = this.amount.split('.');
      if (parts[1] && parts[1].length >= 2) return;
    }
    if (this.amount.length >= 10) return;
    if (this.amount === '' && value === '.') {
      this.amount = '0.';
      return;
    }
    if (this.amount === '0' && value !== '.') {
      this.amount = value;
      return;
    }
    this.amount += value;
  }

  private handleDelete(): void {
    if (this.amount.length > 0) {
      this.amount = this.amount.slice(0, -1);
    }
  }

  private async handleConfirm(): Promise<void> {
    if (this.isSaving) return;
    const numAmount = parseFloat(this.amount);
    if (isNaN(numAmount) || numAmount <= 0) {
      promptAction.showToast({ message: $r('app.string.ledger_amount_required'), duration: 1500 });
      return;
    }
    if (!this.selectedCategory) {
      promptAction.showToast({ message: $r('app.string.ledger_category_required'), duration: 1500 });
      return;
    }

    this.isSaving = true;
    try {
      const bill: BillRecord = {
        id: util.generateRandomUUID(true),
        amount: numAmount,
        type: this.billType,
        categoryId: this.selectedCategory.id,
        note: this.note,
        date: this.selectedDate,
        createTime: Date.now()
      };
      await this.billService.addBill(bill);

      const context = getContext(this) as Context;
      try {
        await this.streakService.recordToday(context);
      } catch (streakError) {
        hilog.warn(ADD_BILL_DOMAIN, ADD_BILL_TAG,
          'Streak update failed after bill save: %{public}s', JSON.stringify(streakError) ?? '');
      }

      promptAction.showToast({ message: $r('app.string.ledger_save_success'), duration: 1500 });
      setTimeout(() => {
        router.back();
      }, 300);
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.ledger_save_fail'), duration: 2000 });
      this.isSaving = false;
    }
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

        Text($r('app.string.ledger_add_bill'))
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

      Row() {
        this.TypeChip($r('app.string.ledger_expense'), BillType.EXPENSE)
        this.TypeChip($r('app.string.ledger_income'), BillType.INCOME)
      }
      .width('64%')
      .constraintSize({ minWidth: 240, maxWidth: 360 })
      .height(48)
      .padding(4)
      .backgroundColor(ledgerColor('ledger_divider'))
      .borderRadius(Constants.RADIUS_FULL)
      .margin({ top: 12 })

      Row() {
        Text($r('app.string.ledger_currency'))
          .fontSize(24)
          .fontColor(ledgerColor('ledger_muted'))
          .fontWeight(FontWeight.Medium)
        Text(this.amount.length > 0 ? this.amount : '0')
          .fontSize(this.getAmountFontSize())
          .fontColor(ledgerColor('ledger_ink'))
          .fontWeight(FontWeight.Bold)
          .margin({ left: 4 })
          .maxLines(1)
      }
      .width('100%')
      .height(92)
      .padding({ left: 24, right: 24, top: 16, bottom: 12 })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Row() {
        TextInput({ placeholder: $r('app.string.ledger_add_note'), text: this.note })
          .fontSize(Constants.FONT_CAPTION)
          .fontColor(ledgerColor('ledger_ink'))
          .placeholderColor(ledgerColor('ledger_muted'))
          .backgroundColor(ledgerColor('ledger_surface'))
          .layoutWeight(1)
          .height(36)
          .onChange((value: string) => {
            if (value.length <= 50) this.note = value;
          })
          .onFocus(() => {
            this.isNoteFocused = true;
          })
          .onBlur(() => {
            this.isNoteFocused = false;
          })

        Divider()
          .vertical(true)
          .height(24)
          .color(ledgerColor('ledger_divider'))

        Button({ type: ButtonType.Normal }) {
          Row() {
            Text(this.selectedDate)
              .fontSize(Constants.FONT_CAPTION)
              .fontWeight(FontWeight.Medium)
              .fontColor(ledgerColor('ledger_accent'))

            Image($r('app.media.ledger_calendar'))
              .width(18)
              .height(18)
              .objectFit(ImageFit.Contain)
              .margin({ left: 6 })
          }
        }
          .height(40)
          .backgroundColor(ledgerColor('ledger_surface'))
          .padding({ left: 12, right: 8 })
          .onClick(() => {
            DatePickerDialog.show({
              start: new Date('2020-1-1'),
              end: new Date('2035-12-31'),
              selected: new Date(this.selectedDate),
              onDateAccept: (value: Date) => {
                this.selectedDate = DateUtils.formatDate(value);
              }
            });
          })
      }
      .width('100%')
      .height(58)
      .margin({ left: 16, right: 16, top: 4, bottom: 12 })
      .padding({ left: 14, right: 8 })
      .backgroundColor(ledgerColor('ledger_surface'))
      .borderRadius(Constants.RADIUS_MD)

      Column() {
        Scroll() {
          CategoryGrid({
            categories: this.categories,
            selectedId: this.selectedCategory ? this.selectedCategory.id : '',
            onSelect: (category: Category) => {
              this.selectedCategory = category;
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .layoutWeight(1)
      .width('100%')
      .margin({ left: 16, right: 16, bottom: 12 })
      .backgroundColor(ledgerColor('ledger_surface'))
      .borderRadius(Constants.RADIUS_LG)

      if (!this.isNoteFocused) {
        NumberKeyboard({
          bottomInset: minimumBottomControlInsetVp(this.safeAreaBottom),
          onInput: (value: string) => { this.handleInput(value); },
          onDelete: () => { this.handleDelete(); },
          onConfirm: () => { this.handleConfirm(); }
        })
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
  TypeChip(label: Resource, type: BillType) {
    Button({ type: ButtonType.Normal }) {
      Text(label)
        .fontSize(Constants.FONT_BODY)
        .fontWeight(this.billType === type ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.getTypeChipTextColor(type))
    }
      .layoutWeight(1)
      .height('100%')
      .backgroundColor(this.getTypeChipBackground(type))
      .borderRadius(Constants.RADIUS_FULL)
      .onClick(() => { this.switchBillType(type); })
  }

  private getAmountFontSize(): number {
    if (this.amount.length >= 10) return 30;
    if (this.amount.length >= 8) return 36;
    return 48;
  }

  private getTypeChipBackground(type: BillType): string {
    if (this.billType !== type) return ledgerColor('ledger_surface');
    return type === BillType.EXPENSE ? ledgerColor('ledger_accent') : ledgerColor('ledger_income_green');
  }

  private getTypeChipTextColor(type: BillType): string {
    return this.billType === type ? ledgerColor('ledger_card_text_primary') : ledgerColor('ledger_muted');
  }
}
