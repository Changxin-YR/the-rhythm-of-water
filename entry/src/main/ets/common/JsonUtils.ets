export function parseJsonArray<T>(raw: string): T[] | null {
  try {
    const parsed = JSON.parse(raw) as T[]
    return Array.isArray(parsed) ? parsed : null
  } catch (e) {
    return null
  }
}

export function parseJsonObject<T>(raw: string): T | null {
  try {
    const parsed = JSON.parse(raw) as T
    if (parsed === null || Array.isArray(parsed) || typeof parsed !== 'object') return null
    return parsed
  } catch (e) {
    return null
  }
}
