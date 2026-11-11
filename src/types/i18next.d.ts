import 'i18next';

import type { defaultNS, resources } from '@/lib/i18n';

// Makes t('key') type-safe: typos in translation keys become compile errors.
declare module 'i18next' {
  interface CustomTypeOptions {
    defaultNS: typeof defaultNS;
    resources: (typeof resources)['en'];
  }
}
