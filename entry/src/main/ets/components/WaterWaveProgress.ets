@Component
export struct WaterWaveProgress {
  @Prop progress: number = 0
  @Prop currentMl: number = 0
  @Prop goalMl: number = 2000
  @Prop primaryColor: string = '#007AFF'
  @Prop primaryTextColor: string = '#0066CC'
  @Prop secondaryColor: string = '#30B0C7'
  @Prop textColor: string = '#1D1D1F'
  @Prop trackColor: string = '#D1D1D6'
  @Prop diameter: number = 220

  private visibleProgress(): number {
    return Math.min(this.progress, 100)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(this.diameter)
        .height(this.diameter)
        .fill(Color.Transparent)
        .stroke(this.secondaryColor)
        .strokeWidth(10)
        .opacity(0.22)

      Progress({ value: this.visibleProgress(), total: 100, type: ProgressType.Ring })
        .width(this.diameter)
        .height(this.diameter)
        .color(this.primaryColor)
        .style({ strokeWidth: 10 })

      Column({ space: 4 }) {
        Text(`${this.currentMl}`)
          .fontSize(38)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textColor)

        Text(`/ ${this.goalMl} ml`)
          .fontSize(14)
          .fontColor(this.textColor)
          .opacity(0.6)

        Text(`${Math.min(this.progress, 100)}%`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.primaryTextColor)
          .margin({ top: 4 })
      }
    }
    .width(this.diameter)
    .height(this.diameter)
    .margin({ top: 4, bottom: 4 })
  }
}
