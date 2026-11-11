import { Text, View } from 'react-native';

type EmptyStateProps = {
  title: string;
  message?: string;
};

/** Friendly empty state. TODO: add the mascot illustration once the design is ready. */
export function EmptyState({ title, message }: EmptyStateProps) {
  return (
    <View
      className="flex-1 items-center justify-center gap-2 p-section"
      accessibilityRole="summary"
    >
      <Text
        className="text-center text-title font-bold text-text dark:text-text-dark"
        accessibilityRole="header"
      >
        {title}
      </Text>
      {message ? (
        <Text className="text-center text-body text-muted dark:text-muted-dark">{message}</Text>
      ) : null}
    </View>
  );
}
