/**
 * Color tokens – the ONLY place hex values are allowed.
 * Placeholder palette: sync with the design system in Notion ("Budgee – Project Hub").
 *
 * Each token has a light value (DEFAULT) and a dark value, used as
 * `bg-surface dark:bg-surface-dark` in NativeWind classes.
 */
export const colors = {
  brand: { DEFAULT: '#7C5CFF', dark: '#9D85FF' },
  background: { DEFAULT: '#FAF8FF', dark: '#121018' },
  surface: { DEFAULT: '#FFFFFF', dark: '#1E1A28' },
  text: { DEFAULT: '#1C1830', dark: '#F4F1FF' },
  muted: { DEFAULT: '#6E6890', dark: '#A39DC2' },
  border: { DEFAULT: '#E6E1F5', dark: '#2F2A3D' },
  income: { DEFAULT: '#1F9D66', dark: '#3DD68C' },
  expense: { DEFAULT: '#E5484D', dark: '#FF6B70' },
  warning: { DEFAULT: '#F5A524', dark: '#FFC15E' },
} as const;

export type ColorToken = keyof typeof colors;
