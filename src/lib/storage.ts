import { createMMKV } from 'react-native-mmkv';

/**
 * App-wide key-value storage (MMKV: synchronous, much faster than AsyncStorage).
 * Native module → requires a dev build, does not run in Expo Go.
 */
export const storage = createMMKV({ id: 'budgee' });

/** AsyncStorage-shaped adapter, used by the TanStack Query persister and Supabase Auth. */
export const storageAdapter = {
  getItem: (key: string): string | null => storage.getString(key) ?? null,
  setItem: (key: string, value: string): void => storage.set(key, value),
  removeItem: (key: string): void => {
    storage.remove(key);
  },
};
