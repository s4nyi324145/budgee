import '../global.css';
import '@/lib/i18n';

import { PersistQueryClientProvider } from '@tanstack/react-query-persist-client';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { StyleSheet } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';

import { persistMaxAge, queryClient, queryPersister } from '@/lib/queryClient';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={styles.root}>
      <PersistQueryClientProvider
        client={queryClient}
        persistOptions={{ persister: queryPersister, maxAge: persistMaxAge }}
      >
        <Stack screenOptions={{ headerShown: false }} />
        <StatusBar style="auto" />
      </PersistQueryClientProvider>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
});
