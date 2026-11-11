import { colors } from '@/theme';

const HEX = /^#[0-9A-F]{6}$/i;

describe('color tokens', () => {
  it.each(Object.entries(colors))('%s has valid light and dark values', (_name, token) => {
    expect(token.DEFAULT).toMatch(HEX);
    expect(token.dark).toMatch(HEX);
  });
});
