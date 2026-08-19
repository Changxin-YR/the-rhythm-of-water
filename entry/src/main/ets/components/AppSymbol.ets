@Component
export struct AppSymbol {
  @Prop name: string = 'default'
  @Prop symbolSize: number = 22
  @Prop color: string = '#007AFF'
  @Prop opacityValue: number = 1

  private resource(): Resource {
    switch (this.name) {
      case 'water':
      case 'drop':
      case '💧':
      case '🫗':
      case '🌊':
      case '🌏':
      case '🐳':
      case '🐋':
      case '🏞️':
      case '🏖️':
      case '🌍':
        return $r('sys.symbol.drop_fill')
      case 'wallet':
      case '💰':
      case '💎':
      case '💼':
      case '🧧':
      case '🛒':
      case '📦':
      case '🎁':
      case '📈':
      case '💄':
      case '📮':
        return $r('sys.symbol.wallet_fill')
      case 'achievement':
      case 'medal':
      case '🏆':
      case '🎯':
      case '⭐':
      case '👑':
      case '🎮':
      case '⚽':
      case '🎬':
      case '🎵':
      case '🏋️':
      case '🎨':
      case '💪':
      case '8️⃣':
        return $r('sys.symbol.medal')
      case 'fire':
      case '🔥':
        return $r('sys.symbol.flame')
      case 'plant':
      case 'leaf':
      case '🌱':
      case '🌿':
      case '🍃':
      case '☘️':
      case '🌻':
      case '🌵':
      case '🪴':
      case '🌸':
      case '🫘':
      case '🌼':
      case '💐':
      case '💜':
      case '🏜️':
      case '🍀':
      case '🌺':
      case '🌳':
      case '🎋':
      case '🐶':
        return $r('sys.symbol.leaf_fill')
      case 'settings':
      case '⚙':
      case '⚙️':
        return $r('sys.symbol.gearshape')
      case 'back':
        return $r('sys.symbol.chevron_left')
      case 'next':
        return $r('sys.symbol.chevron_right')
      case 'add':
      case '+':
        return $r('sys.symbol.plus')
      case 'overview':
      case 'grid':
        return $r('sys.symbol.square_grid_2x2')
      case 'profile':
      case 'person':
      case '👥':
      case '👔':
      case '👶':
      case '🏥':
        return $r('sys.symbol.person')
      case 'calendar':
      case '📅':
      case '📚':
        return $r('sys.symbol.calendar')
      case 'card':
      case 'payment':
        return $r('sys.symbol.creditcard')
      case 'time':
      case 'clock':
      case '☀️':
      case '☁️':
      case '🌙':
      case '🌅':
      case '✈️':
      case '🚌':
      case '🚗':
        return $r('sys.symbol.clock')
      case 'cup':
      case 'beverage':
      case '🍵':
      case '☕':
      case '🥛':
      case '🧃':
      case '🍲':
      case '🥤':
      case '🥥':
      case '🍜':
      case '🍹':
      case '🧋':
      case '🍺':
      case '🥃':
      case '🍰':
        return $r('sys.symbol.cup')
      case 'upload':
        return $r('sys.symbol.upload')
      case 'download':
        return $r('sys.symbol.download')
      case 'delete':
      case 'trash':
        return $r('sys.symbol.trash')
      case 'security':
      case 'shield':
        return $r('sys.symbol.checkmark_shield_fill')
      default:
        return $r('sys.symbol.square_grid_2x2')
    }
  }

  build() {
    SymbolGlyph(this.resource())
      .fontSize(this.symbolSize)
      .fontColor([this.color])
      .opacity(this.opacityValue)
  }
}
