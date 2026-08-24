import { Category } from '../models/Category';
import { BillType } from '../models/BillRecord';
import { CategoryService } from '../services/CategoryService';
import { Constants } from '../common/Constants';
import { LedgerBreakpoint, ResponsiveUtils } from '../common/ResponsiveUtils';
import router from '@ohos.router';
import util from '@ohos.util';
import promptAction from '@ohos.promptAction';
import { DataChangeNotifier, LedgerDataChange, LedgerDataChangeListener } from '../common/DataChangeNotifier';
import { minimumBottomControlInsetVp } from '../../common/SafeAreaRules';
import { ledgerColor } from '../common/LedgerTheme';
import { UiTokens } from '../../common/Theme';
import { AppSymbol } from '../../components/AppSymbol';

class CategoryListDataSource implements IDataSource {
  private data: Category[] = [];
  private listeners: DataChangeListener[] = [];

  constructor(categories: Category[]) {
    this.data = categories;
  }

  totalCount(): number {
    return this.data.length;
  }

  getData(index: number): Category {
    return this.data[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  update(categories: Category[]): void {
    this.data = categories;
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
  }
}

@Component
export struct LedgerCategoryManagePage {
  @State expenseCategories: Category[] = [];
  @StorageProp('safeAreaTop') safeAreaTop: number = 0;
  @StorageProp('safeAreaBottom') safeAreaBottom: number = 0;
  @State incomeCategories: Category[] = [];
  @State showAddDialog: boolean = false;
  @State newCategoryName: string = '';
  @State newCategoryIcon: string = '';
  @State newCategoryType: BillType = BillType.EXPENSE;
  @State selectedColorIndex: number = 0;
  @State currentTab: BillType = BillType.EXPENSE;
  @State isSaving: boolean = false;
  @State isLoading: boolean = true;
  @State currentBreakpoint: LedgerBreakpoint = LedgerBreakpoint.COMPACT;

  private categoryService: CategoryService = new CategoryService();
  private expenseCategoryDataSource: CategoryListDataSource = new CategoryListDataSource([]);
  private incomeCategoryDataSource: CategoryListDataSource = new CategoryListDataSource([]);
  private categoryRequestId: number = 0;
  private isCategoryMutationInProgress: boolean = false;
  private dataChangeListener: LedgerDataChangeListener = (change: LedgerDataChange): void => {
    if (change === LedgerDataChange.CategoryChanged && !this.isCategoryMutationInProgress) {
      void this.loadCategories();
    }
  };
  async aboutToAppear(): Promise<void> {
    DataChangeNotifier.subscribe(this.dataChangeListener);
    try {
      await this.loadCategories();
    } catch (error) {
      promptAction.showToast({ message: $r('app.string.ledger_load_fail'), duration: 2000 });
    }
  }

  async onPageShow(): Promise<void> {
    await this.loadCategories();
  }

  aboutToDisappear(): void {
    DataChangeNotifier.unsubscribe(this.dataChangeListener);
  }

  private async loadCategories(): Promise<void> {
    const requestId = ++this.categoryRequestId;
    this.isLoading = true;
    try {
      const expenseCategories = await this.categoryService.getCategoriesByType(BillType.EXPENSE);
      const incomeCategories = await this.categoryService.getCategoriesByType(BillType.INCOME);
      if (requestId !== this.categoryRequestId) {
        return;
      }
      this.replaceCategories(expenseCategories, incomeCategories);
    } finally {
      if (requestId === this.categoryRequestId) {
        this.isLoading = false;
      }
    }
  }

  private async addCategory(): Promise<void> {
    if (this.isSaving || this.isCategoryMutationInProgress) return;
    const categoryName = this.newCategoryName.trim();
    if (categoryName.length === 0) {
      promptAction.showToast({ message: $r('app.string.ledger_category_name_required'), duration: 1500 });
      return;
    }
    if (this.newCategoryIcon.length === 0) {
      promptAction.showToast({ message: $r('app.string.ledger_category_icon_required'), duration: 1500 });
      return;
    }
    const currentCategories = this.currentTab === BillType.EXPENSE ?
      this.expenseCategories : this.incomeCategories;

    const category: Category = {
      id: util.generateRandomUUID(true),
      name: categoryName,
      icon: this.newCategoryIcon,
      type: this.currentTab,
      isCustom: true,
      sortOrder: currentCategories.length,
      color: this.getResourceColorString(Constants.CATEGORY_COLORS[this.selectedColorIndex])
    };

    this.isSaving = true;
    this.isCategoryMutationInProgress = true;
    this.categoryRequestId++;
    try {
      await this.categoryService.addCategory(category);
      this.applyAddedCategory(category);
      this.showAddDialog = false;
      this.newCategoryName = '';
      this.newCategoryIcon = '';
      this.selectedColorIndex = 0;
      await this.reconcileCategoriesAfterMutation();
      promptAction.showToast({ message: $r('app.string.ledger_category_add_success'), duration: 1500 });
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.ledger_category_add_fail'), duration: 2000 });
    } finally {
      this.isSaving = false;
      this.isCategoryMutationInProgress = false;
    }
  }

  private async deleteCategory(category: Category): Promise<void> {
    if (!category.isCustom || this.isSaving || this.isCategoryMutationInProgress) return;
    this.isCategoryMutationInProgress = true;
    try {
      const billCount = await this.categoryService.getCategoryBillCount(category.id);
      if (billCount > 0) {
        AlertDialog.show({
          title: $r('app.string.ledger_category_delete_title'),
          message: this.getResourceString($r('app.string.ledger_category_delete_message'), category.name, billCount),
          cancel: () => { this.isCategoryMutationInProgress = false; },
          primaryButton: {
            value: $r('app.string.ledger_cancel'),
            action: () => { this.isCategoryMutationInProgress = false; }
          },
          secondaryButton: {
            value: $r('app.string.ledger_delete'),
            fontColor: ledgerColor('ledger_expense_red'),
            action: () => {
              this.performDeleteCategory(category.id);
            }
          }
        });
      } else {
        await this.performDeleteCategory(category.id);
      }
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.ledger_category_delete_fail'), duration: 2000 });
      this.isCategoryMutationInProgress = false;
    }
  }

  private async performDeleteCategory(id: string): Promise<void> {
    this.categoryRequestId++;
    try {
      await this.categoryService.deleteCategory(id);
      this.applyDeletedCategory(id);
      await this.reconcileCategoriesAfterMutation();
      promptAction.showToast({ message: $r('app.string.ledger_category_deleted'), duration: 1500 });
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.ledger_category_delete_fail'), duration: 2000 });
    } finally {
      this.isCategoryMutationInProgress = false;
    }
  }

  private async reconcileCategoriesAfterMutation(): Promise<void> {
    const requestId = ++this.categoryRequestId;
    const expenseCategories = await this.categoryService.getCategoriesByType(BillType.EXPENSE);
    const incomeCategories = await this.categoryService.getCategoriesByType(BillType.INCOME);
    if (requestId !== this.categoryRequestId) {
      return;
    }
    this.replaceCategories(expenseCategories, incomeCategories);
  }

  private replaceCategories(expenseCategories: Category[], incomeCategories: Category[]): void {
    this.expenseCategories = [...expenseCategories];
    this.incomeCategories = [...incomeCategories];
    this.expenseCategoryDataSource.update(this.expenseCategories);
    this.incomeCategoryDataSource.update(this.incomeCategories);
  }

  private applyAddedCategory(category: Category): void {
    if (category.type === BillType.EXPENSE) {
      this.replaceCategories([...this.expenseCategories, category], this.incomeCategories);
    } else {
      this.replaceCategories(this.expenseCategories, [...this.incomeCategories, category]);
    }
  }

  private applyDeletedCategory(id: string): void {
    this.replaceCategories(
      this.expenseCategories.filter((category: Category) => category.id !== id),
      this.incomeCategories.filter((category: Category) => category.id !== id)
    );
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
          .width(UiTokens.recommendedTouchTargetSize)
          .height(UiTokens.recommendedTouchTargetSize)
          .backgroundColor(ledgerColor('ledger_surface'))
          .borderRadius(Constants.RADIUS_FULL)
          .onClick(() => { router.back(); })

        Text($r('app.string.ledger_category_manage'))
          .fontSize(Constants.FONT_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ledgerColor('ledger_ink'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text($r('app.string.ledger_add_category'))
          .fontSize(Constants.FONT_BODY)
          .fontColor(ledgerColor('ledger_primary_color'))
          .fontWeight(FontWeight.Medium)
          .height(UiTokens.recommendedTouchTargetSize)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.newCategoryType = this.currentTab;
            this.showAddDialog = true;
          })
          .padding({ left: 8, right: 8 })
      }
      .width('100%')
      .height(60)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      Row({ space: 8 }) {
        Text($r('app.string.ledger_expense'))
          .fontSize(Constants.FONT_CAPTION)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentTab === BillType.EXPENSE ? ledgerColor('ledger_expense_red') : ledgerColor('ledger_muted'))
          .height(UiTokens.minimumTouchTargetSize)
          .textAlign(TextAlign.Center)
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .backgroundColor(this.currentTab === BillType.EXPENSE ? ledgerColor('ledger_expense_soft') : ledgerColor('ledger_surface'))
          .borderRadius(10)
          .animation({ duration: Constants.ANIM_DURATION_SHORT })
          .onClick(() => { this.currentTab = BillType.EXPENSE; })

        Text($r('app.string.ledger_income'))
          .fontSize(Constants.FONT_CAPTION)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentTab === BillType.INCOME ? ledgerColor('ledger_income_green') : ledgerColor('ledger_muted'))
          .height(UiTokens.minimumTouchTargetSize)
          .textAlign(TextAlign.Center)
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .backgroundColor(this.currentTab === BillType.INCOME ? ledgerColor('ledger_income_soft') : ledgerColor('ledger_surface'))
          .borderRadius(10)
          .animation({ duration: Constants.ANIM_DURATION_SHORT })
          .onClick(() => { this.currentTab = BillType.INCOME; })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 8 })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
            .color(ledgerColor('ledger_primary_color'));
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          if (this.currentTab === BillType.EXPENSE) {
            LazyForEach(this.expenseCategoryDataSource, (item: Category) => {
              this.CategoryListItem(item)
            }, (item: Category) => item.id)
          } else {
            LazyForEach(this.incomeCategoryDataSource, (item: Category) => {
              this.CategoryListItem(item)
            }, (item: Category) => item.id)
          }

          ListItem() {
            Column().height(minimumBottomControlInsetVp(this.safeAreaBottom))
          }
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .padding({ top: 12, bottom: 20, left: 16, right: 16 })
      }

      if (this.showAddDialog) {
        this.AddCategoryDialog()
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
  CategoryListItem(item: Category) {
    ListItem() {
      Column() {
        Row() {
          AppSymbol({ name: item.icon, symbolSize: 22, color: ledgerColor('ledger_primary_color') })
            .width(44)
            .height(44)
            .backgroundColor(ledgerColor('ledger_primary_light'))
            .borderRadius(14)

          Text(item.name)
            .fontSize(Constants.FONT_BODY)
            .fontColor(ledgerColor('ledger_ink'))
            .margin({ left: 12 })
            .layoutWeight(1)

          if (item.isCustom) {
            Text($r('app.string.ledger_delete'))
              .fontSize(Constants.FONT_CAPTION)
              .fontColor(ledgerColor('ledger_expense_red'))
              .height(UiTokens.minimumTouchTargetSize)
              .textAlign(TextAlign.Center)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(Constants.RADIUS_SM)
              .backgroundColor(ledgerColor('ledger_expense_red_light'))
              .onClick(() => {
                this.deleteCategory(item);
              })
          } else {
            Text($r('app.string.ledger_preset'))
              .fontSize(Constants.FONT_SMALL)
              .fontColor(ledgerColor('ledger_muted'))
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })

        Divider().color(ledgerColor('ledger_divider')).margin({ left: 72 })
      }
      .width('100%')
      .backgroundColor(ledgerColor('ledger_surface'))
      .borderRadius(Constants.RADIUS_MD)
    }
    .width('100%')
    .padding({ left: 0, right: 0 })
  }

  @Builder
  AddCategoryDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ledgerColor('ledger_dialog_overlay'))
        .onClick(() => { this.showAddDialog = false; })

      Stack({ alignContent: Alignment.Center }) {
        Column() {
          Text($r('app.string.ledger_add_category'))
            .fontSize(Constants.FONT_SUBTITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(ledgerColor('ledger_ink'))
            .margin({ bottom: 16 })

        TextInput({ placeholder: $r('app.string.ledger_category_name_placeholder'), text: this.newCategoryName })
          .width('100%')
          .height(44)
          .fontColor(ledgerColor('ledger_ink'))
          .placeholderColor(ledgerColor('ledger_text_secondary'))
          .backgroundColor(ledgerColor('ledger_divider'))
          .borderRadius(Constants.RADIUS_SM)
          .margin({ bottom: 16 })
          .maxLength(8)
          .onChange((value: string) => { this.newCategoryName = value; })

        Scroll() {
          Column() {
            Text($r('app.string.ledger_select_icon'))
              .fontSize(Constants.FONT_CAPTION)
              .fontColor(ledgerColor('ledger_muted'))
              .width('100%')
              .margin({ bottom: 8 })

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(Constants.CATEGORY_ICON_OPTIONS, (icon: string) => {
                AppSymbol({ name: icon, symbolSize: 22, color: ledgerColor('ledger_primary_color') })
                  .width(UiTokens.recommendedTouchTargetSize)
                  .height(UiTokens.recommendedTouchTargetSize)
                  .borderRadius(12)
                  .backgroundColor(this.newCategoryIcon === icon ?
                    ledgerColor('ledger_primary_light') : ledgerColor('ledger_surface'))
                  .border({
                    width: this.newCategoryIcon === icon ? 1.5 : 0,
                    color: ledgerColor('ledger_primary_color')
                  })
                  .onClick(() => { this.newCategoryIcon = icon; })
                  .margin(2)
              }, (icon: string, index: number) => `${icon}_${index}`)
            }
            .width('100%')
            .margin({ bottom: 16 })

            Text($r('app.string.ledger_select_color'))
              .fontSize(Constants.FONT_CAPTION)
              .fontColor(ledgerColor('ledger_muted'))
              .width('100%')
              .margin({ bottom: 8 })

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(Constants.CATEGORY_COLORS, (color: Resource, index: number) => {
                Stack({ alignContent: Alignment.Center }) {
                  Circle()
                    .width(30)
                    .height(30)
                    .fill(color)
                    .stroke(ledgerColor('ledger_ink'))
                    .strokeWidth(this.selectedColorIndex === index ? 3 : 0)
                }
                  .width(UiTokens.recommendedTouchTargetSize)
                  .height(UiTokens.recommendedTouchTargetSize)
                  .margin(3)
                  .onClick(() => { this.selectedColorIndex = index; })
              }, (color: Resource, index: number) => `${color.id}_${index}`)
            }
            .width('100%')
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .margin({ bottom: 16 })

          Row() {
            Button($r('app.string.ledger_cancel'))
              .width('45%')
              .height(UiTokens.recommendedTouchTargetSize)
              .backgroundColor(ledgerColor('ledger_divider'))
              .fontColor(ledgerColor('ledger_ink'))
              .borderRadius(Constants.RADIUS_SM)
              .onClick(() => { this.showAddDialog = false; })

            Button($r('app.string.ledger_confirm'))
              .width('45%')
              .height(UiTokens.recommendedTouchTargetSize)
              .backgroundColor(ledgerColor('ledger_primary_color'))
              .fontColor(ledgerColor('ledger_card_text_primary'))
              .borderRadius(Constants.RADIUS_SM)
              .onClick(() => { this.addCategory(); })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('85%')
        .height('80%')
        .constraintSize({ maxWidth: 480, maxHeight: 560 })
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
