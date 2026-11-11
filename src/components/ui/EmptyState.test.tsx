import { render, screen } from '@testing-library/react-native';

import { EmptyState } from './EmptyState';

describe('EmptyState', () => {
  it('renders the title as a header and the message', async () => {
    await render(<EmptyState title="Nothing here" message="Add your first one!" />);

    expect(screen.getByRole('header', { name: 'Nothing here' })).toBeOnTheScreen();
    expect(screen.getByText('Add your first one!')).toBeOnTheScreen();
  });
});
