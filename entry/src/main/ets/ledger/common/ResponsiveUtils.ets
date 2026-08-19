export enum LedgerBreakpoint {
  COMPACT = 'compact',
  MEDIUM = 'medium',
  EXPANDED = 'expanded'
}

export class ResponsiveUtils {
  static toViewportWidth(areaWidth: Length, pxToVp: (value: number) => number): number {
    let width: number;
    if (typeof areaWidth === 'number') {
      width = areaWidth;
    } else if (typeof areaWidth === 'string') {
      width = parseFloat(areaWidth);
    } else {
      return 0;
    }
    return isNaN(width) ? 0 : pxToVp(width);
  }

  static fromAreaWidth(areaWidth: Length, pxToVp: (value: number) => number): LedgerBreakpoint {
    const width = ResponsiveUtils.toViewportWidth(areaWidth, pxToVp);
    if (width < 600) {
      return LedgerBreakpoint.COMPACT;
    }
    if (width < 840) {
      return LedgerBreakpoint.MEDIUM;
    }
    return LedgerBreakpoint.EXPANDED;
  }

  static getContentMaxWidth(breakpoint: LedgerBreakpoint): string {
    if (breakpoint === LedgerBreakpoint.EXPANDED) {
      return '960vp';
    }
    if (breakpoint === LedgerBreakpoint.MEDIUM) {
      return '720vp';
    }
    return '100%';
  }

  static getCategoryColumns(breakpoint: LedgerBreakpoint): number {
    if (breakpoint === LedgerBreakpoint.EXPANDED) {
      return 6;
    }
    if (breakpoint === LedgerBreakpoint.MEDIUM) {
      return 5;
    }
    return 4;
  }

  static getChartSize(breakpoint: LedgerBreakpoint): number {
    if (breakpoint === LedgerBreakpoint.EXPANDED) {
      return 240;
    }
    if (breakpoint === LedgerBreakpoint.MEDIUM) {
      return 210;
    }
    return 180;
  }
}
