import { useTranslation } from 'react-i18next';
import { SafeAreaView } from 'react-native-safe-area-context';

import { EmptyState } from '@/components/ui/EmptyState';

export default function SignInScreen() {
  const { t } = useTranslation();
  return (
    <SafeAreaView className="flex-1 bg-background dark:bg-background-dark">
      <EmptyState title={t('auth.signIn')} message={t('common.comingSoonMessage')} />
    </SafeAreaView>
  );
}
