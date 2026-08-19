export class Constants {
  // Spacing
  static readonly SPACING_XS: number = 4;
  static readonly SPACING_SM: number = 8;
  static readonly SPACING_MD: number = 16;
  static readonly SPACING_LG: number = 24;
  static readonly SPACING_XL: number = 32;
  static readonly SPACING_XXL: number = 48;

  // Radius
  static readonly RADIUS_SM: number = 8;
  static readonly RADIUS_MD: number = 14;
  static readonly RADIUS_LG: number = 20;
  static readonly RADIUS_XL: number = 28;
  static readonly RADIUS_FULL: number = 999;

  // Font sizes
  static readonly FONT_DISPLAY: number = 28;
  static readonly FONT_TITLE: number = 20;
  static readonly FONT_SUBTITLE: number = 17;
  static readonly FONT_BODY: number = 15;
  static readonly FONT_CAPTION: number = 13;
  static readonly FONT_SMALL: number = 11;

  // Animation
  static readonly ANIM_DURATION_SHORT: number = 120;
  static readonly ANIM_DURATION_NORMAL: number = 250;
  static readonly ANIM_DURATION_LONG: number = 400;

  // Database
  static readonly DB_NAME: string = 'waterreminder_ledger.db';
  static readonly TABLE_BILL: string = 'bill_record';
  static readonly TABLE_CATEGORY: string = 'category';
  static readonly TABLE_BUDGET: string = 'budget';
  static readonly TABLE_STREAK: string = 'streak_state';
  static readonly TABLE_METADATA: string = 'app_metadata';

  // Category colors
  static readonly CATEGORY_COLORS: Resource[] = [
    $r('app.color.ledger_category_palette_01'), $r('app.color.ledger_category_palette_02'),
    $r('app.color.ledger_category_palette_03'), $r('app.color.ledger_category_palette_04'),
    $r('app.color.ledger_category_palette_05'), $r('app.color.ledger_category_palette_06'),
    $r('app.color.ledger_category_palette_07'), $r('app.color.ledger_category_palette_08'),
    $r('app.color.ledger_category_palette_09'), $r('app.color.ledger_category_palette_10'),
    $r('app.color.ledger_category_palette_11'), $r('app.color.ledger_category_palette_12'),
    $r('app.color.ledger_category_palette_13'), $r('app.color.ledger_category_palette_14'),
    $r('app.color.ledger_category_palette_15'), $r('app.color.ledger_category_palette_16')
  ];

  static readonly CATEGORY_ICON_OPTIONS: string[] = [
    '🍜', '🚌', '🛒', '🏠', '🎮', '💊', '📚', '📱',
    '👔', '⚽', '👥', '📦', '💰', '🎁', '💼', '📈',
    '🧧', '💎', '🎬', '✈️', '🐶', '🌸', '☕', '🎵',
    '🏋️', '🍰', '🚗', '💄', '👶', '🏥', '📮', '🎯'
  ];
}
