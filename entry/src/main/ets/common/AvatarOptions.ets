export interface AvatarOption {
  id: string
  glyph: string
}

export const DEFAULT_AVATAR_ID: string = 'avatar_sun'

export const AVATAR_OPTIONS: AvatarOption[] = [
  { id: 'avatar_sun', glyph: '☀️' },
  { id: 'avatar_cloud', glyph: '☁️' },
  { id: 'avatar_leaf', glyph: '🍃' },
  { id: 'avatar_wave', glyph: '🌊' },
  { id: 'avatar_moon', glyph: '🌙' },
  { id: 'avatar_star', glyph: '⭐' }
]

export function normalizeAvatarId(id: string | undefined): string {
  for (const item of AVATAR_OPTIONS) {
    if (item.id === id) return item.id
  }
  return DEFAULT_AVATAR_ID
}

export function avatarGlyph(id: string | undefined): string {
  const normalized = normalizeAvatarId(id)
  for (const item of AVATAR_OPTIONS) {
    if (item.id === normalized) return item.glyph
  }
  return AVATAR_OPTIONS[0].glyph
}
