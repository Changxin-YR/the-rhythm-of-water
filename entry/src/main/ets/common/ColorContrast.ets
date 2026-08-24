interface RgbaColor {
  red: number
  green: number
  blue: number
  alpha: number
}

function parseHexColor(value: string): RgbaColor | null {
  const match = /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.exec(value)
  if (match === null) return null

  const hex = match[1]
  return {
    red: parseInt(hex.slice(0, 2), 16),
    green: parseInt(hex.slice(2, 4), 16),
    blue: parseInt(hex.slice(4, 6), 16),
    alpha: hex.length === 8 ? parseInt(hex.slice(6, 8), 16) / 255 : 1
  }
}

function linearize(channel: number): number {
  const normalized = channel / 255
  return normalized <= 0.04045
    ? normalized / 12.92
    : Math.pow((normalized + 0.055) / 1.055, 2.4)
}

function relativeLuminance(color: RgbaColor): number {
  return linearize(color.red) * 0.2126 + linearize(color.green) * 0.7152 + linearize(color.blue) * 0.0722
}

const WHITE: RgbaColor = { red: 255, green: 255, blue: 255, alpha: 1 }

function compositeRgba(foreground: RgbaColor, background: RgbaColor): RgbaColor {
  const alpha = foreground.alpha + background.alpha * (1 - foreground.alpha)
  if (alpha <= 0) return { red: 0, green: 0, blue: 0, alpha: 0 }
  return {
    red: (foreground.red * foreground.alpha + background.red * background.alpha * (1 - foreground.alpha)) / alpha,
    green: (foreground.green * foreground.alpha + background.green * background.alpha * (1 - foreground.alpha)) / alpha,
    blue: (foreground.blue * foreground.alpha + background.blue * background.alpha * (1 - foreground.alpha)) / alpha,
    alpha
  }
}

function resolveOpaque(color: RgbaColor): RgbaColor {
  return color.alpha >= 1 ? color : compositeRgba(color, WHITE)
}

function toHexByte(value: number): string {
  const byte = Math.max(0, Math.min(255, Math.round(value)))
  return byte.toString(16).padStart(2, '0').toUpperCase()
}

function rgbaToHex(color: RgbaColor): string {
  const rgb = `#${toHexByte(color.red)}${toHexByte(color.green)}${toHexByte(color.blue)}`
  return color.alpha >= 1 ? rgb : `${rgb}${toHexByte(color.alpha * 255)}`
}

/** Resolves an alpha foreground over an alpha background for callers that need the actual rendered color. */
export function compositeColor(foreground: string, background: string): string {
  const foregroundColor = parseHexColor(foreground)
  const backgroundColor = parseHexColor(background)
  if (foregroundColor === null || backgroundColor === null) return ''
  return rgbaToHex(compositeRgba(foregroundColor, backgroundColor))
}

function calculateContrastRatio(foregroundColor: RgbaColor, backgroundColor: RgbaColor): number {
  const effectiveBackground = resolveOpaque(backgroundColor)
  const effectiveForeground = resolveOpaque(compositeRgba(foregroundColor, effectiveBackground))
  const foregroundLuminance = relativeLuminance(effectiveForeground)
  const backgroundLuminance = relativeLuminance(effectiveBackground)
  const lighter = Math.max(foregroundLuminance, backgroundLuminance)
  const darker = Math.min(foregroundLuminance, backgroundLuminance)
  return (lighter + 0.05) / (darker + 0.05)
}

export function contrastRatio(foreground: string, background: string): number {
  const foregroundColor = parseHexColor(foreground)
  const backgroundColor = parseHexColor(background)
  if (foregroundColor === null || backgroundColor === null) return 0
  return calculateContrastRatio(foregroundColor, backgroundColor)
}

/** Checks a translucent foreground/background pair over its real opaque page surface. */
export function contrastRatioOverSurface(foreground: string, background: string, surface: string): number {
  const foregroundColor = parseHexColor(foreground)
  const backgroundColor = parseHexColor(background)
  const surfaceColor = parseHexColor(surface)
  if (foregroundColor === null || backgroundColor === null || surfaceColor === null) return 0
  const effectiveBackground = compositeRgba(backgroundColor, resolveOpaque(surfaceColor))
  return calculateContrastRatio(foregroundColor, effectiveBackground)
}

export function hasMinimumTextContrast(foreground: string, background: string): boolean {
  return contrastRatio(foreground, background) > 4.5
}

export function hasMinimumIconOrTitleContrast(foreground: string, background: string): boolean {
  return contrastRatio(foreground, background) > 3
}
