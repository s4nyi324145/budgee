import { getLocales } from 'expo-localization';
import { createInstance } from 'i18next';
import { initReactI18next } from 'react-i18next';

import en from '@/locales/en.json';

export const defaultNS = 'translation';
export const resources = {
  en: { translation: en },
} as const;

export const i18n = createInstance();

void i18n.use(initReactI18next).init({
  resources,
  defaultNS,
  lng: getLocales()[0]?.languageCode ?? 'en',
  fallbackLng: 'en',
  interpolation: { escapeValue: false }, // React already escapes
});
