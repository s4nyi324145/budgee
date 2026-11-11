import { createAsyncStoragePersister } from '@tanstack/query-async-storage-persister';
import { QueryClient } from '@tanstack/react-query';

import { storageAdapter } from './storage';

const ONE_DAY = 1000 * 60 * 60 * 24;

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 30,
      // Must be >= persister maxAge, otherwise cached data is garbage-collected before it's persisted.
      gcTime: ONE_DAY,
      retry: 2,
    },
  },
});

export const queryPersister = createAsyncStoragePersister({
  storage: storageAdapter,
  key: 'budgee-query-cache',
});

export const persistMaxAge = ONE_DAY;
