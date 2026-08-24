export type LedgerIconName = 'home' | 'bills' | 'statistics' | 'settings' | 'close' | 'bell' | 'filter' | 'calendar' | 'backspace';

@Component
export struct LedgerIcon {
  @Prop name: LedgerIconName = 'home';
  @Prop active: boolean = false;

  private getResource(): Resource {
    switch (this.name) {
      case 'bills':
        return $r('app.media.ledger_bills');
      case 'statistics':
        return $r('app.media.ledger_statistics');
      case 'settings':
        return $r('app.media.ledger_settings');
      case 'close':
        return $r('app.media.ledger_close');
      case 'bell':
        return $r('app.media.ledger_bell');
      case 'filter':
        return $r('app.media.ledger_filter');
      case 'calendar':
        return $r('app.media.ledger_calendar');
      case 'backspace':
        return $r('app.media.ledger_backspace');
      case 'home':
      default:
        return $r('app.media.ledger_home');
    }
  }

  build() {
    Image(this.getResource())
      .width(24)
      .height(24)
      .objectFit(ImageFit.Contain)
      .opacity(this.active ? 1 : 0.56)
      .scale({ x: this.active ? 1 : 0.92, y: this.active ? 1 : 0.92 })
  }
}
