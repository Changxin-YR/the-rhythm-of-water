import { BillRecord, BillType } from '../models/BillRecord';
import { Category } from '../models/Category';
import { MonthSummary, DaySummary } from '../models/Statistics';
import { BillService } from '../services/BillService';
import { CategoryService } from '../services/CategoryService';
import { StatisticsService } from '../services/StatisticsService';
import { StreakService, StreakInfo } from '../services/StreakService';
import { BillCard } from '../components/BillCard';
import { SummaryCard } from '../components/SummaryCard';
import { LedgerIcon, LedgerIconName } from '../components/LedgerIcon';
import { Constants } from '../common/Constants';
import { DateUtils } from '../common/DateUtils';
import { NumberUtils } from '../common/NumberUtils';
import { DataChangeNotifier, LedgerDataChange, LedgerDataChangeListener } from '../common/DataChangeNotifier';
import { LedgerBreakpoint, ResponsiveUtils } from '../common/ResponsiveUtils';
import { ledgerColor, setLedgerDarkMode } from '../common/LedgerTheme';
import { isSystemDarkMode } from '../../common/Theme';
import { ConfigurationConstant } from '@kit.AbilityKit';
import router from '@ohos.router';
import fs from '@ohos.file.fs';
import promptAction from '@ohos.promptAction';
import { picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { AppSymbol } from '../../components/AppSymbol';

interface BillWithCategory {
  bill: BillRecord;
  category: Category;
}

interface DateGroup {
  date: string;
  renderKey: string;
  displayDate: string;
  bills: BillWithCategory[];
  dayIncome: number;
  dayExpense: number;
}

class DateGroupDataSource implements IDataSource {
  private data: DateGroup[] = [];
  private listeners: DataChangeListener[] = [];

  constructor(groups: DateGroup[]) {
    this.data = groups;
  }

  totalCount(): number {
    return this.data.length;
  }

  getData(index: number): DateGroup {
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

  update(groups: DateGroup[]): void {
    this.data = groups;
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
  }
}

@Component
export struct LedgerHomePage {
  // 账本只保留一个页面层级；交易记录作为页面内的可返回子视图，
  // 一级导航仍由 MainPage 的唯一底部 TabBar 负责。
  @State ledgerView: number = 0;
  @State monthSummary: MonthSummary = {
    year: DateUtils.getCurrentYear(),
    month: DateUtils.getCurrentMonth(),
    totalIncome: 0,
    totalExpense: 0,
    balance: 0,
    billCount: 0
  };
  @State todaySummary: DaySummary = {
    date: DateUtils.getToday(),
    totalIncome: 0,
    totalExpense: 0,
    balance: 0,
    billCount: 0
  };
  @State filteredTodaySummary: DaySummary = {
    date: DateUtils.getToday(),
    totalIncome: 0,
    totalExpense: 0,
    balance: 0,
    billCount: 0
  };
  @State recentBills: BillWithCategory[] = [];
  @State @Watch('handleDateGroupsChange') dateGroups: DateGroup[] = [];
  @State categories: Category[] = [];
  @State searchKeyword: string = '';
  @State filterType: number = 0;
  @State streakInfo: StreakInfo = { currentStreak: 0, longestStreak: 0, totalDays: 0, lastRecordDate: '' };
  @State currentBreakpoint: LedgerBreakpoint = LedgerBreakpoint.COMPACT;
  @StorageProp('refreshSignal') @Watch('onRefreshSignal') refreshSignal: number = 0;
  @StorageProp('ledgerDarkMode') ledgerDarkMode: boolean = false;

  private billService: BillService = new BillService();
  private categoryService: CategoryService = new CategoryService();
  private statisticsService: StatisticsService = new StatisticsService();
  private streakService: StreakService = new StreakService();
  private categoryMap: Map<string, Category> = new Map();
  private dateGroupDataSource: DateGroupDataSource = new DateGroupDataSource([]);
  private pageDataRequestId: number = 0;
  private dateGroupsRequestId: number = 0;
  private deletingBillId: string = '';
  private searchTimerId: number = -1;
  private isDataChangeSubscribed: boolean = false;
  private hasRequestedInitialPageData: boolean = false;
  private dataChangeListener: LedgerDataChangeListener = (change: LedgerDataChange): void => {
    void this.handleDataChange(change);
  };

  @StorageProp('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  aboutToAppear(): void {
    this.reloadTheme();
    this.ensurePageDataLoaded();
  }

  onColorModeChange(): void {
    this.reloadTheme();
  }

  async onRefreshSignal(): Promise<void> {
    this.reloadTheme();
    this.ensurePageDataLoaded();
    await this.loadPageData();
  }

  private reloadTheme(): void {
    const dark = isSystemDarkMode(this.colorMode);
    setLedgerDarkMode(dark);
    this.ledgerDarkMode = dark;
  }

  onPageShow(): void {
    this.ensurePageDataLoaded();
    void this.loadPageData();
  }

  aboutToBeDeleted(): void {
    if (this.isDataChangeSubscribed) {
      DataChangeNotifier.unsubscribe(this.dataChangeListener);
      this.isDataChangeSubscribed = false;
    }
  }

  private async handleDataChange(change: LedgerDataChange): Promise<void> {
    if (change === LedgerDataChange.BillChanged || change === LedgerDataChange.CategoryChanged) {
      await this.loadPageData();
    }
  }

  private ensurePageDataLoaded(): void {
    if (!this.isDataChangeSubscribed) {
      DataChangeNotifier.subscribe(this.dataChangeListener);
      this.isDataChangeSubscribed = true;
    }
    if (this.hasRequestedInitialPageData) {
      return;
    }
    this.hasRequestedInitialPageData = true;
    void this.loadPageData();
  }

  private async loadPageData(): Promise<void> {
    const requestId = ++this.pageDataRequestId;
    try {
      await this.loadCategories(requestId);
      if (requestId !== this.pageDataRequestId) {
        return;
      }
      await this.refreshData(requestId);
      if (requestId !== this.pageDataRequestId) {
        return;
      }
      await this.loadStreak(requestId);
    } catch (error) {
      if (requestId === this.pageDataRequestId) {
        promptAction.showToast({ message: $r('app.string.ledger_load_fail'), duration: 2000 });
      }
    }
  }

  private async loadCategories(pageDataRequestId: number): Promise<void> {
    const categories = await this.categoryService.getAllCategories();
    if (pageDataRequestId !== this.pageDataRequestId) {
      return;
    }
    const categoryMap = new Map<string, Category>();
    for (const category of categories) {
      categoryMap.set(category.id, category);
    }
    this.categories = categories;
    this.categoryMap = categoryMap;
  }

  private async loadStreak(pageDataRequestId: number): Promise<void> {
    const context = getContext(this) as Context;
    const streakInfo = await this.streakService.getStreakInfo(context);
    if (pageDataRequestId !== this.pageDataRequestId) {
      return;
    }
    this.streakInfo = streakInfo;
  }

  private async refreshData(pageDataRequestId: number): Promise<void> {
    const year = DateUtils.getCurrentYear();
    const month = DateUtils.getCurrentMonth();
    const monthSummary = await this.statisticsService.getMonthSummary(year, month);
    if (pageDataRequestId !== this.pageDataRequestId) {
      return;
    }
    const todaySummary = await this.statisticsService.getDaySummary(DateUtils.getToday());
    if (pageDataRequestId !== this.pageDataRequestId) {
      return;
    }
    this.monthSummary = monthSummary;
    this.todaySummary = todaySummary;
    await this.loadRecentBills(pageDataRequestId);
    if (pageDataRequestId !== this.pageDataRequestId) {
      return;
    }
    await this.loadDateGroups(pageDataRequestId);
  }

  private async loadRecentBills(pageDataRequestId: number): Promise<void> {
    const bills = await this.billService.getBillsByDate(DateUtils.getToday());
    if (pageDataRequestId !== this.pageDataRequestId) {
      return;
    }
    this.recentBills = bills.map((bill: BillRecord) => {
      return { bill: bill, category: this.getCategory(bill.categoryId) } as BillWithCategory;
    });
  }

  private async loadDateGroups(pageDataRequestId?: number): Promise<void> {
    const requestId = ++this.dateGroupsRequestId;
    try {
      const keyword = this.normalizeSearchKeyword(this.searchKeyword);
      const type = this.filterType;
      const year = DateUtils.getCurrentYear();
      const month = DateUtils.getCurrentMonth();
      const range = DateUtils.getMonthRange(year, month);
      let bills = await this.billService.getBillsByDateRange(range.start, range.end);

      if (keyword.length > 0) {
        bills = bills.filter((bill: BillRecord) => this.matchesSearchKeyword(bill, keyword));
      }

      if (type === 1) {
        bills = bills.filter((bill: BillRecord) => bill.type === BillType.EXPENSE);
      } else if (type === 2) {
        bills = bills.filter((bill: BillRecord) => bill.type === BillType.INCOME);
      }

      const filteredTodaySummary = this.createFilteredTodaySummary(bills);
      const groupMap = new Map<string, BillWithCategory[]>();
      for (const bill of bills) {
        const list = groupMap.get(bill.date) || [];
        list.push({ bill: bill, category: this.getCategory(bill.categoryId) });
        groupMap.set(bill.date, list);
      }

      const groups: DateGroup[] = [];
      const entries = Array.from(groupMap.entries());
      entries.sort((a: [string, BillWithCategory[]], b: [string, BillWithCategory[]]) => b[0].localeCompare(a[0]));

      for (const entry of entries) {
        const date = entry[0];
        const billsInGroup = entry[1];
        let dayIncome = 0;
        let dayExpense = 0;
        for (const item of billsInGroup) {
          if (item.bill.type === BillType.INCOME) {
            dayIncome += item.bill.amount;
          } else {
            dayExpense += item.bill.amount;
          }
        }
        groups.push({
          date: date,
          renderKey: `${date}|${type}|${keyword}`,
          displayDate: DateUtils.getRelativeDate(date),
          bills: billsInGroup,
          dayIncome: dayIncome,
          dayExpense: dayExpense
        });
      }
      if (requestId !== this.dateGroupsRequestId ||
        (pageDataRequestId !== undefined && pageDataRequestId !== this.pageDataRequestId)) {
        return;
      }
      this.dateGroups = groups;
      this.filteredTodaySummary = filteredTodaySummary;
    } catch (error) {
      if (requestId === this.dateGroupsRequestId &&
        (pageDataRequestId === undefined || pageDataRequestId === this.pageDataRequestId)) {
        promptAction.showToast({ message: $r('app.string.ledger_load_fail'), duration: 2000 });
      }
    }
  }

  private normalizeSearchKeyword(value: string): string {
    return value.trim().toLowerCase();
  }

  private matchesSearchKeyword(bill: BillRecord, keyword: string): boolean {
    if (keyword.length === 0) {
      return true;
    }
    const categoryName = this.getCategory(bill.categoryId).name.toLowerCase();
    const note = (bill.note || '').toLowerCase();
    return categoryName.includes(keyword) || note.includes(keyword);
  }

  private createFilteredTodaySummary(bills: BillRecord[]): DaySummary {
    const date = DateUtils.getToday();
    let totalIncome = 0;
    let totalExpense = 0;
    let billCount = 0;
    for (const bill of bills) {
      if (bill.date !== date) {
        continue;
      }
      billCount++;
      if (bill.type === BillType.INCOME) {
        totalIncome += bill.amount;
      } else {
        totalExpense += bill.amount;
      }
    }
    return { date, totalIncome, totalExpense, balance: totalIncome - totalExpense, billCount };
  }

  private getCategory(categoryId: string): Category {
    const category = this.categoryMap.get(categoryId);
    if (category) {
      return category;
    }
    return {
      id: '',
      name: this.getResourceString($r('app.string.ledger_other')),
      icon: 'wallet',
      type: BillType.EXPENSE,
      isCustom: false,
      sortOrder: 0,
      color: ledgerColor('ledger_category_fallback')
    };
  }

  private handleDateGroupsChange(): void {
    this.dateGroupDataSource.update(this.dateGroups);
  }

  private async handleDeleteBill(id: string): Promise<void> {
    if (this.deletingBillId === id) return;
    this.deletingBillId = id;
    try {
      await this.billService.deleteBill(id);
      await this.loadPageData();
      promptAction.showToast({ message: $r('app.string.ledger_delete_success'), duration: 1500 });
    } catch (error) {
      promptAction.showToast({ message: $r('app.string.ledger_delete_fail'), duration: 2000 });
    } finally {
      if (this.deletingBillId === id) {
        this.deletingBillId = '';
      }
    }
  }

  private getGreeting(): Resource {
    const hour = new Date().getHours();
    if (hour < 6) {
      return $r('app.string.ledger_greeting_night');
    }
    if (hour < 11) {
      return $r('app.string.ledger_greeting_morning');
    }
    if (hour < 14) {
      return $r('app.string.ledger_greeting_noon');
    }
    if (hour < 18) {
      return $r('app.string.ledger_greeting_afternoon');
    }
    return $r('app.string.ledger_greeting_evening');
  }

  private getTodayDisplay(): string {
    const now = new Date();
    const month = now.getMonth() + 1;
    const day = now.getDate();
    return `${month}/${day} ${DateUtils.getDayOfWeek(DateUtils.getToday())}`;
  }

  private getContentWidth(): string {
    return ResponsiveUtils.getContentMaxWidth(this.currentBreakpoint);
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        // 显式依赖主题状态，保证系统主题变化后整张账本页重新解析语义色。
        .backgroundColor(this.ledgerDarkMode ? ledgerColor('ledger_canvas') : ledgerColor('ledger_canvas'));

      if (this.ledgerDarkMode) {
        Column() {
          if (this.ledgerView === 0) {
            this.HomeTab();
          } else {
            this.BillsTab();
          }
        }
        .width('100%')
        .height('100%')
        .constraintSize({ maxWidth: ResponsiveUtils.getContentMaxWidth(this.currentBreakpoint) });
      } else {
        Column() {
          if (this.ledgerView === 0) {
            this.HomeTab();
          } else {
            this.BillsTab();
          }
        }
        .width('100%')
        .height('100%')
        .constraintSize({ maxWidth: ResponsiveUtils.getContentMaxWidth(this.currentBreakpoint) });
      }
    }
    .width('100%')
    .height('100%')
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.currentBreakpoint = ResponsiveUtils.fromAreaWidth(newValue.width, (value: number) => this.getUIContext().px2vp(value));
      this.ensurePageDataLoaded();
    });
  }

  @Builder
  HomeTab() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Scroll() {
        Column() {
          Column() {
            Row() {
              Column() {
                Text(this.getGreeting())
                  .fontSize(Constants.FONT_DISPLAY)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ledgerColor('ledger_ink'));
                Text(this.getTodayDisplay())
                  .fontSize(Constants.FONT_BODY)
                  .fontColor(ledgerColor('ledger_muted'))
                  .margin({ top: 4 });
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1);

              Button({ type: ButtonType.Normal }) {
                AppSymbol({ name: 'add', symbolSize: 22, color: ledgerColor('ledger_primary_color') })
              }
              .width(48)
              .height(48)
              .padding(0)
              .backgroundColor(ledgerColor('ledger_primary_light'))
              .borderRadius(24)
              .onClick(() => {
                router.pushUrl({ url: 'pages/ledger/LedgerAddBillPage' });
              });
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding({ top: 20, bottom: 18 });

            SummaryCard({
              totalIncome: this.monthSummary.totalIncome,
              totalExpense: this.monthSummary.totalExpense,
              title: DateUtils.formatMonthDisplay(this.monthSummary.year, this.monthSummary.month),
              illustration: $r('app.media.ledger_wallet_illustration')
            });

            this.HomeStatMetricRow();
            this.LedgerTools();

            Row() {
              Text($r('app.string.ledger_today_transactions'))
                .fontSize(Constants.FONT_TITLE)
                .fontWeight(FontWeight.Bold)
                .fontColor(ledgerColor('ledger_ink'));
              Blank();
              Text($r('app.string.ledger_view_all'))
                .fontSize(Constants.FONT_CAPTION)
                .fontWeight(FontWeight.Medium)
                .fontColor(ledgerColor('ledger_primary_color'))
                .onClick(() => {
                  this.ledgerView = 1;
                });
            }
            .width('100%')
            .margin({ top: 26, bottom: 12 });

            if (this.recentBills.length === 0) {
              Column() {
                Image($r('app.media.ledger_empty_transactions'))
                  .width(138)
                  .height(104)
                  .objectFit(ImageFit.Contain);
                Text($r('app.string.ledger_no_transactions_today'))
                  .fontSize(Constants.FONT_BODY)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ledgerColor('ledger_ink'))
                  .margin({ top: 8 });
                Text($r('app.string.ledger_start_recording'))
                  .fontSize(Constants.FONT_CAPTION)
                  .fontColor(ledgerColor('ledger_muted'))
                  .textAlign(TextAlign.Center)
                  .maxLines(2)
                  .margin({ top: 5 });
              }
              .width('100%')
              .padding({ top: 22, bottom: 24, left: 20, right: 20 })
              .backgroundColor(ledgerColor('ledger_surface'))
              .borderRadius(Constants.RADIUS_LG);
            } else {
              Column({ space: 8 }) {
                ForEach(this.recentBills, (item: BillWithCategory) => {
                  BillCard({
                    bill: item.bill,
                    category: item.category,
                    onDelete: async (id: string) => {
                      await this.handleDeleteBill(id);
                    }
                  });
                }, (item: BillWithCategory) => item.bill.id);
              }
              .width('100%');
            }

            Column().height(96);
          }
          .width(this.getContentWidth())
          .padding({ left: 20, right: 20 });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%');

    }
    .width('100%')
    .height('100%');
  }

  @Builder
  LedgerTools() {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        this.LedgerToolCard('bills', $r('app.string.ledger_tab_bills'), $r('app.string.ledger_bills_subtitle'), () => {
          this.ledgerView = 1;
        });
        this.LedgerToolCard('statistics', $r('app.string.ledger_tab_statistics'), $r('app.string.ledger_stats_subtitle'), () => {
          router.pushUrl({ url: 'pages/ledger/LedgerStatisticsPage' });
        });
      }
      .width('100%');

      Row({ space: 10 }) {
        this.LedgerToolCard('settings', $r('app.string.ledger_category_manage'), $r('app.string.ledger_category_ranking'), () => {
          router.pushUrl({ url: 'pages/ledger/LedgerCategoryManagePage' });
        });
        this.LedgerToolCard('calendar', $r('app.string.ledger_budget_manage'), $r('app.string.ledger_budget_set_tip'), () => {
          router.pushUrl({ url: 'pages/ledger/LedgerBudgetPage' });
        });
      }
      .width('100%');
    }
    .width('100%')
    .margin({ top: 18 });
  }

  @Builder
  LedgerToolCard(icon: LedgerIconName, title: Resource, subtitle: Resource, action: () => void) {
    Column() {
      LedgerIcon({ name: icon, active: true })
        .width(26)
        .height(26);
      Text(title)
        .fontSize(Constants.FONT_BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor(ledgerColor('ledger_ink'))
        .margin({ top: 10 });
      Text(subtitle)
        .fontSize(Constants.FONT_SMALL)
        .fontColor(ledgerColor('ledger_muted'))
        .margin({ top: 4 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .layoutWeight(1)
    .padding({ left: 12, right: 12, top: 14, bottom: 14 })
    .backgroundColor(ledgerColor('ledger_surface'))
    .borderRadius(Constants.RADIUS_MD)
    .onClick(() => {
      action();
    });
  }

  @Builder
  HomeStatMetricRow() {
    Row({ space: 8 }) {
      Column() {
        Text(`${this.streakInfo.currentStreak}`)
          .fontSize(Constants.FONT_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ledgerColor('ledger_streak_gold'))
          .maxLines(1);
        Text($r('app.string.ledger_continue_days'))
          .fontSize(Constants.FONT_SMALL)
          .fontColor(ledgerColor('ledger_muted'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 });
      }
      .layoutWeight(1)
      .height(76)
      .padding({ left: 6, right: 6, top: 13, bottom: 10 })
      .backgroundColor(ledgerColor('ledger_surface'))
      .borderRadius(Constants.RADIUS_MD)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center);

      Column() {
        Text(`${this.monthSummary.billCount}`)
          .fontSize(Constants.FONT_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ledgerColor('ledger_income_green'))
          .maxLines(1);
        Text($r('app.string.ledger_month_records'))
          .fontSize(Constants.FONT_SMALL)
          .fontColor(ledgerColor('ledger_muted'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 });
      }
      .layoutWeight(1)
      .height(76)
      .padding({ left: 6, right: 6, top: 13, bottom: 10 })
      .backgroundColor(ledgerColor('ledger_surface'))
      .borderRadius(Constants.RADIUS_MD)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center);

      Column() {
        Text(`${this.streakInfo.totalDays}`)
          .fontSize(Constants.FONT_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ledgerColor('ledger_primary_color'))
          .maxLines(1);
        Text($r('app.string.ledger_total_days'))
          .fontSize(Constants.FONT_SMALL)
          .fontColor(ledgerColor('ledger_muted'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 });
      }
      .layoutWeight(1)
      .height(76)
      .padding({ left: 6, right: 6, top: 13, bottom: 10 })
      .backgroundColor(ledgerColor('ledger_surface'))
      .borderRadius(Constants.RADIUS_MD)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center);
    }
    .width('100%')
    .margin({ top: 16 });
  }

  @Builder
  StatisticsMetricRow() {
    Row({ space: 10 }) {
      Column() {
        Text(`${this.monthSummary.billCount}`)
          .fontSize(Constants.FONT_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ledgerColor('ledger_primary_color'))
          .maxLines(1);
        Text($r('app.string.ledger_month_records'))
          .fontSize(Constants.FONT_SMALL)
          .fontColor(ledgerColor('ledger_muted'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 });
      }
      .layoutWeight(1)
      .height(76)
      .padding({ left: 6, right: 6, top: 13, bottom: 10 })
      .backgroundColor(ledgerColor('ledger_surface'))
      .borderRadius(Constants.RADIUS_MD)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center);

      Column() {
        Text(`${this.streakInfo.totalDays}`)
          .fontSize(Constants.FONT_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ledgerColor('ledger_income_green'))
          .maxLines(1);
        Text($r('app.string.ledger_total_days'))
          .fontSize(Constants.FONT_SMALL)
          .fontColor(ledgerColor('ledger_muted'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 });
      }
      .layoutWeight(1)
      .height(76)
      .padding({ left: 6, right: 6, top: 13, bottom: 10 })
      .backgroundColor(ledgerColor('ledger_surface'))
      .borderRadius(Constants.RADIUS_MD)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center);
    }
    .width('100%')
    .margin({ top: 16 });
  }

  @Builder
  BillSummaryMetrics() {
    Column() {
      Text(NumberUtils.formatAmount(this.filteredTodaySummary.totalExpense))
        .fontSize(this.getDaySummaryFontSize(this.filteredTodaySummary.totalExpense))
        .fontWeight(FontWeight.Bold)
        .fontColor(ledgerColor('ledger_expense_red'))
        .maxLines(2);
      Text($r('app.string.ledger_expense'))
        .fontSize(Constants.FONT_SMALL)
        .fontColor(ledgerColor('ledger_muted'))
        .margin({ top: 3 });
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start);

    Column() {
      Text(NumberUtils.formatAmount(this.filteredTodaySummary.totalIncome))
        .fontSize(this.getDaySummaryFontSize(this.filteredTodaySummary.totalIncome))
        .fontWeight(FontWeight.Bold)
        .fontColor(ledgerColor('ledger_income_green'))
        .maxLines(2);
      Text($r('app.string.ledger_income'))
        .fontSize(Constants.FONT_SMALL)
        .fontColor(ledgerColor('ledger_muted'))
        .margin({ top: 3 });
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start);

    Column() {
      Text(`${this.dateGroups.length}`)
        .fontSize(Constants.FONT_SUBTITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ledgerColor('ledger_primary_color'));
      Text($r('app.string.ledger_record_days'))
        .fontSize(Constants.FONT_SMALL)
        .fontColor(ledgerColor('ledger_muted'))
        .maxLines(1);
    }
    .alignItems(HorizontalAlign.End);
  }

  @Builder
  BillsTab() {
    Column() {
      Column() {
        Row() {
          Text('‹')
            .fontSize(32)
            .fontColor(ledgerColor('ledger_primary_color'))
            .width(34)
            .height(40)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.ledgerView = 0;
            });
          Column() {
            Text($r('app.string.ledger_tab_bills'))
              .fontSize(Constants.FONT_DISPLAY)
              .fontWeight(FontWeight.Bold)
              .fontColor(ledgerColor('ledger_ink'));
            Text($r('app.string.ledger_bills_subtitle'))
              .fontSize(Constants.FONT_CAPTION)
              .fontColor(ledgerColor('ledger_muted'))
              .margin({ top: 4 });
           }
           .alignItems(HorizontalAlign.Start)
           .layoutWeight(1);
        }
        .width('100%')
        .padding({ top: 20, bottom: 16 });

        Row() {
          LedgerIcon({ name: 'bills', active: false })
            .width(18)
            .height(18)
            .margin({ right: 8 });
          TextInput({ placeholder: $r('app.string.ledger_bills_search'), text: this.searchKeyword })
            .layoutWeight(1)
            .height(40)
            .backgroundColor(ledgerColor('ledger_surface'))
            .padding({ left: 0, right: 0 })
            .fontSize(Constants.FONT_BODY)
            .fontColor(ledgerColor('ledger_ink'))
            .placeholderColor(ledgerColor('ledger_muted'))
            .onChange((value: string) => {
              this.searchKeyword = value;
              if (this.searchTimerId >= 0) {
                clearTimeout(this.searchTimerId);
              }
              this.searchTimerId = setTimeout(() => {
                this.searchTimerId = -1;
                this.loadDateGroups();
              }, 300);
            });
        }
        .width('100%')
        .height(48)
        .padding({ left: 14, right: 14 })
        .backgroundColor(ledgerColor('ledger_surface'))
        .borderRadius(Constants.RADIUS_FULL);

        Row({ space: 8 }) {
          this.FilterChip(0, $r('app.string.ledger_all'));
          this.FilterChip(1, $r('app.string.ledger_expense'));
          this.FilterChip(2, $r('app.string.ledger_income'));
        }
        .width('100%')
        .margin({ top: 14 });

        this.BillSummaryCard();
      }
      .width(this.getContentWidth())
      .padding({ left: 20, right: 20 });

      if (this.dateGroups.length === 0) {
        Column() {
          Image($r('app.media.ledger_empty_transactions'))
            .width(142)
            .height(106)
            .objectFit(ImageFit.Contain);
          Text($r('app.string.ledger_no_bills'))
            .fontSize(Constants.FONT_BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor(ledgerColor('ledger_ink'))
            .margin({ top: 10 });
          Text($r('app.string.ledger_start_first_bill'))
            .fontSize(Constants.FONT_CAPTION)
            .fontColor(ledgerColor('ledger_muted'))
            .textAlign(TextAlign.Center)
            .maxLines(2)
            .margin({ top: 6 });
        }
        .width(this.getContentWidth())
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 36, right: 36, bottom: 24 });
      } else {
        List() {
          LazyForEach(this.dateGroupDataSource, (group: DateGroup) => {
            ListItemGroup({ header: this.DateGroupHeader(group) }) {
              ForEach(group.bills, (item: BillWithCategory) => {
                ListItem() {
                  BillCard({
                    bill: item.bill,
                    category: item.category,
                    onDelete: (id: string) => {
                      this.handleDeleteBill(id);
                    }
                  });
                }
                .padding({ left: 20, right: 20, top: 4, bottom: 4 });
              }, (item: BillWithCategory) => item.bill.id);
            }
          }, (group: DateGroup) => group.renderKey);
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .divider({ strokeWidth: 0, color: ledgerColor('ledger_divider') });
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  FilterChip(index: number, label: Resource) {
    Text(label)
      .fontSize(Constants.FONT_CAPTION)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.filterType === index ? ledgerColor('ledger_card_text_primary') : ledgerColor('ledger_muted'))
      .padding({ left: 18, right: 18, top: 8, bottom: 8 })
      .backgroundColor(this.filterType === index ? ledgerColor('ledger_primary_color') : ledgerColor('ledger_surface'))
      .borderRadius(Constants.RADIUS_FULL)
      .animation({ duration: Constants.ANIM_DURATION_SHORT })
      .onClick(() => {
        this.filterType = index;
        this.loadDateGroups();
      });
  }

  @Builder
  BillSummaryCard() {
    Column() {
      Row() {
        Text($r('app.string.ledger_today'))
          .fontSize(Constants.FONT_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ledgerColor('ledger_ink'));
        Blank();
        Text(NumberUtils.formatAmount(this.filteredTodaySummary.balance))
          .fontSize(Constants.FONT_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.filteredTodaySummary.balance >= 0 ? ledgerColor('ledger_income_green') : ledgerColor('ledger_expense_red'))
          .maxLines(1);
      }
      .width('100%');

      Divider()
        .color(ledgerColor('ledger_divider'))
        .margin({ top: 13, bottom: 13 });

      Row() {
        this.BillSummaryMetrics();
      }
      .width('100%')
      .alignItems(VerticalAlign.Top);
    }
    .width('100%')
    .padding(16)
    .margin({ top: 14, bottom: 8 })
    .backgroundColor(ledgerColor('ledger_primary_light'))
    .borderRadius(Constants.RADIUS_MD);
  }

  @Builder
  DateGroupHeader(group: DateGroup) {
    Row() {
      Text(group.displayDate)
        .fontSize(Constants.FONT_CAPTION)
        .fontWeight(FontWeight.Bold)
        .fontColor(ledgerColor('ledger_ink'));
      Text(DateUtils.getDayOfWeek(group.date))
        .fontSize(Constants.FONT_CAPTION)
        .fontColor(ledgerColor('ledger_muted'))
        .margin({ left: 6 });
      Blank();
      Column() {
        Text(NumberUtils.formatAmount(group.dayExpense))
          .fontSize(this.getDateGroupAmountFontSize(group.dayExpense))
          .fontColor(ledgerColor('ledger_expense_red'))
          .maxLines(2)
          .textAlign(TextAlign.End);
        Text($r('app.string.ledger_expense'))
          .fontSize(12)
          .fontColor(ledgerColor('ledger_muted'))
          .margin({ top: 2 });
      }
      .width(72)
      .alignItems(HorizontalAlign.End);
      Column() {
        Text(NumberUtils.formatAmount(group.dayIncome))
          .fontSize(this.getDateGroupAmountFontSize(group.dayIncome))
          .fontColor(ledgerColor('ledger_income_green'))
          .maxLines(2)
          .textAlign(TextAlign.End);
        Text($r('app.string.ledger_income'))
          .fontSize(12)
          .fontColor(ledgerColor('ledger_muted'))
          .margin({ top: 2 });
      }
      .width(72)
      .alignItems(HorizontalAlign.End)
      .margin({ left: 12 });
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 8 })
    .backgroundColor(ledgerColor('ledger_canvas'))
    .alignItems(VerticalAlign.Top);
  }

  @Builder
  StatisticsTab() {
    Scroll() {
      Column() {
        Column() {
          Text($r('app.string.ledger_tab_statistics'))
            .fontSize(Constants.FONT_DISPLAY)
            .fontWeight(FontWeight.Bold)
            .fontColor(ledgerColor('ledger_ink'));
          Text($r('app.string.ledger_stats_subtitle'))
            .fontSize(Constants.FONT_CAPTION)
            .fontColor(ledgerColor('ledger_muted'))
            .margin({ top: 5, bottom: 20 });

          SummaryCard({
            totalIncome: this.monthSummary.totalIncome,
            totalExpense: this.monthSummary.totalExpense,
            title: DateUtils.formatMonthDisplay(this.monthSummary.year, this.monthSummary.month),
            illustration: $r('app.media.ledger_chart_illustration')
          });

          this.StatisticsMetricRow();

          Button($r('app.string.ledger_detail_statistics'))
            .width('100%')
            .height(50)
            .margin({ top: 24 })
            .fontSize(Constants.FONT_BODY)
            .fontWeight(FontWeight.Bold)
            .fontColor(ledgerColor('ledger_card_text_primary'))
            .borderRadius(Constants.RADIUS_MD)
            .backgroundColor(ledgerColor('ledger_primary_color'))
            .onClick(() => {
              router.pushUrl({ url: 'pages/ledger/LedgerStatisticsPage' });
            });
        }
        .width(this.getContentWidth())
        .padding({ left: 20, right: 20, top: 20, bottom: 32 });
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center);
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off);
  }

  private async exportDataToCSV(): Promise<void> {
    try {
      const year = DateUtils.getCurrentYear();
      const month = DateUtils.getCurrentMonth();
      const bills = await this.billService.getAllBillsByMonth(year, month);
      const allCategories = await this.categoryService.getAllCategories();

      const headerFields: string[] = [
        this.getResourceString($r('app.string.ledger_csv_date')),
        this.getResourceString($r('app.string.ledger_csv_type')),
        this.getResourceString($r('app.string.ledger_csv_category')),
        this.getResourceString($r('app.string.ledger_csv_amount')),
        this.getResourceString($r('app.string.ledger_csv_note'))
      ];
      let csvContent = '\uFEFF' + headerFields.map((header: string) => this.escapeCsvField(header)).join(',') + '\n';
      for (const bill of bills) {
        const category = allCategories.find((item: Category) => item.id === bill.categoryId);
        const typeName = bill.type === BillType.EXPENSE ?
          this.getResourceString($r('app.string.ledger_csv_expense')) :
          this.getResourceString($r('app.string.ledger_csv_income'));
        const categoryName = category ? category.name : this.getResourceString($r('app.string.ledger_csv_other'));
        const fields: Array<string | number> = [bill.date, typeName, categoryName, bill.amount, bill.note];
        csvContent += fields.map((field: string | number) => this.escapeCsvField(field)).join(',') + '\n';
      }

      const context = getContext(this) as common.UIAbilityContext;
      const options = new picker.DocumentSaveOptions();
      options.newFileNames = [`bills_export_${year}_${month}.csv`];
      const targetUris = await new picker.DocumentViewPicker(context).save(options);
      if (!targetUris || targetUris.length === 0) {
        return;
      }
      const filePath = targetUris[0];
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(file.fd, csvContent);
      } finally {
        fs.closeSync(file.fd);
      }

      AlertDialog.show({
        title: $r('app.string.ledger_export_success'),
        message: $r('app.string.ledger_export_success_message'),
        confirm: { value: $r('app.string.ledger_confirm'), action: () => {} }
      });
    } catch (error) {
      AlertDialog.show({
        title: $r('app.string.ledger_export_fail'),
        message: $r('app.string.ledger_export_fail_message'),
        confirm: { value: $r('app.string.ledger_confirm'), action: () => {} }
      });
    }
  }

  private escapeCsvField(value: string | number): string {
    let text = `${value}`;
    const firstCharacter = text.charAt(0);
    if (firstCharacter === '=' || firstCharacter === '+' || firstCharacter === '-' || firstCharacter === '@') {
      text = `'${text}`;
    }
    const escapedText = text.replace(/"/g, '""');
    if (escapedText.includes(',') || escapedText.includes('"') || escapedText.includes('\n') || escapedText.includes('\r')) {
      return `"${escapedText}"`;
    }
    return escapedText;
  }

  private getResourceString(resource: Resource): string {
    const context = getContext(this) as Context;
    return context.resourceManager.getStringSync(resource);
  }

  private getDaySummaryFontSize(amount: number): number {
    const length = NumberUtils.formatAmount(amount).length;
    if (length > 18) {
      return Constants.FONT_SMALL;
    }
    if (length > 13) {
      return Constants.FONT_CAPTION;
    }
    return Constants.FONT_BODY;
  }

  private getDateGroupAmountFontSize(amount: number): number {
    const length = NumberUtils.formatAmount(amount).length;
    if (length > 16) {
      return 10;
    }
    if (length > 12) {
      return Constants.FONT_SMALL;
    }
    return Constants.FONT_CAPTION;
  }

  private clearAllData(): void {
    AlertDialog.show({
      title: $r('app.string.ledger_clear_data_title'),
      message: $r('app.string.ledger_clear_data_message'),
      primaryButton: { value: $r('app.string.ledger_cancel'), action: () => {} },
      secondaryButton: {
        value: $r('app.string.ledger_clear_data'),
        fontColor: ledgerColor('ledger_expense_red'),
        action: () => {
          this.performClearAllData();
        }
      }
    });
  }

  private async performClearAllData(): Promise<void> {
    const context = getContext(this) as Context;
    try {
      await this.billService.deleteAllBills();
      await this.streakService.clearStreak(context);
      await this.loadPageData();
      AlertDialog.show({
        title: $r('app.string.ledger_clear_data'),
        message: $r('app.string.ledger_clear_data_done'),
        confirm: { value: $r('app.string.ledger_confirm'), action: () => {} }
      });
    } catch (error) {
      try {
        await this.loadPageData();
      } catch (refreshError) {
          promptAction.showToast({ message: $r('app.string.ledger_load_fail'), duration: 2000 });
      }
      AlertDialog.show({
        title: $r('app.string.ledger_clear_data_title'),
        message: $r('app.string.ledger_clear_data_fail_message'),
        confirm: { value: $r('app.string.ledger_confirm'), action: () => {} }
      });
      return;
    }
  }

  @Builder
  SettingsTab() {
    Scroll() {
      Column() {
        Column() {
          Text($r('app.string.ledger_tab_settings'))
            .fontSize(Constants.FONT_DISPLAY)
            .fontWeight(FontWeight.Bold)
            .fontColor(ledgerColor('ledger_ink'));
          Text($r('app.string.ledger_settings_subtitle'))
            .fontSize(Constants.FONT_CAPTION)
            .fontColor(ledgerColor('ledger_muted'))
            .margin({ top: 5 });

          Image($r('app.media.ledger_settings_illustration'))
            .width('100%')
            .height(138)
            .objectFit(ImageFit.Contain)
            .margin({ top: 10, bottom: 12 });

          Column() {
            this.SettingsRow('bills', $r('app.string.ledger_category_manage'), () => {
              router.pushUrl({ url: 'pages/ledger/LedgerCategoryManagePage' });
            });
            Divider().margin({ left: 64 }).color(ledgerColor('ledger_divider'));
            this.SettingsRow('statistics', $r('app.string.ledger_budget_manage'), () => {
              router.pushUrl({ url: 'pages/ledger/LedgerBudgetPage' });
            });
          }
          .width('100%')
          .backgroundColor(ledgerColor('ledger_surface'))
          .borderRadius(Constants.RADIUS_MD);

          Column() {
            this.SettingsRow('calendar', $r('app.string.ledger_export_data'), () => {
              this.exportDataToCSV();
            });
            Divider().margin({ left: 64 }).color(ledgerColor('ledger_divider'));
            this.SettingsRow('close', $r('app.string.ledger_clear_data'), () => {
              this.clearAllData();
            });
          }
          .width('100%')
          .margin({ top: 14 })
          .backgroundColor(ledgerColor('ledger_surface'))
          .borderRadius(Constants.RADIUS_MD);

          Column() {
            this.SettingsInfoRow('home', $r('app.string.ledger_about'), $r('app.string.ledger_version_value'));
            Divider().margin({ left: 64 }).color(ledgerColor('ledger_divider'));
            Column() {
              Text($r('app.string.ledger_app_name'))
                .fontSize(Constants.FONT_BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(ledgerColor('ledger_ink'));
              Text($r('app.string.ledger_app_description'))
                .fontSize(Constants.FONT_CAPTION)
                .fontColor(ledgerColor('ledger_muted'))
                .margin({ top: 5 });
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 16 })
            .alignItems(HorizontalAlign.Start);
          }
          .width('100%')
          .margin({ top: 14, bottom: 24 })
          .backgroundColor(ledgerColor('ledger_surface'))
          .borderRadius(Constants.RADIUS_MD);
        }
        .width(this.getContentWidth())
        .padding({ left: 20, right: 20, top: 20 });
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center);
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off);
  }

  @Builder
  SettingsRow(icon: LedgerIconName, title: Resource, action: () => void) {
    Row() {
      Column() {
        LedgerIcon({ name: icon, active: true });
      }
      .width(40)
      .height(40)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(ledgerColor('ledger_primary_light'))
      .borderRadius(Constants.RADIUS_SM);

      Text(title)
        .fontSize(Constants.FONT_BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor(ledgerColor('ledger_ink'))
        .margin({ left: 12 })
        .layoutWeight(1);
      Text($r('app.string.ledger_navigation_hint'))
        .fontSize(Constants.FONT_TITLE)
        .fontColor(ledgerColor('ledger_muted'));
    }
    .width('100%')
    .height(68)
    .padding({ left: 14, right: 16 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      action();
    });
  }

  @Builder
  SettingsInfoRow(icon: LedgerIconName, title: Resource, detail: Resource) {
    Row() {
      Column() {
        LedgerIcon({ name: icon, active: true });
      }
      .width(40)
      .height(40)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(ledgerColor('ledger_primary_light'))
      .borderRadius(Constants.RADIUS_SM);

      Text(title)
        .fontSize(Constants.FONT_BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor(ledgerColor('ledger_ink'))
        .margin({ left: 12 })
        .layoutWeight(1);
      Text(detail)
        .fontSize(Constants.FONT_CAPTION)
        .fontColor(ledgerColor('ledger_muted'));
    }
    .width('100%')
    .height(68)
    .padding({ left: 14, right: 16 })
    .alignItems(VerticalAlign.Center);
  }
}
