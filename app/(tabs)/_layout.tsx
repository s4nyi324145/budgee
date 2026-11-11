import { Tabs } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { useColorScheme } from 'react-native';

import { colors } from '@/theme';

export default function TabsLayout() {
  const { t } = useTranslation();
  const isDark = useColorScheme() === 'dark';
  const pick = (token: { DEFAULT: string; dark: string }) => (isDark ? token.dark : token.DEFAULT);

  // TODO: add tab icons once the icon set is chosen.
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: pick(colors.brand),
        tabBarInactiveTintColor: pick(colors.muted),
        tabBarStyle: { backgroundColor: pick(colors.surface), borderTopColor: pick(colors.border) },
      }}
    >
      <Tabs.Screen name="index" options={{ title: t('tabs.home') }} />
      <Tabs.Screen name="transactions" options={{ title: t('tabs.transactions') }} />
      <Tabs.Screen name="budgets" options={{ title: t('tabs.budgets') }} />
      <Tabs.Screen name="goals" options={{ title: t('tabs.goals') }} />
      <Tabs.Screen name="profile" options={{ title: t('tabs.profile') }} />
    </Tabs>
  );
}
