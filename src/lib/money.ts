/**
 * Money utilities – amounts are ALWAYS integers in minor units (e.g. cents, fillér).
 * Never use floats for money math.
 *
 * 🎓 learning mode: implement these yourself, test-first (money.test.ts).
 * Edge cases to cover: currencies with 0 decimals (HUF in practice, JPY), negative results,
 * locale-specific separators ("1 234,50" vs "1,234.50"), invalid input, overflow > Number.MAX_SAFE_INTEGER.
 */

/** ISO 4217 currency code, e.g. 'HUF', 'EUR'. */
export type CurrencyCode = string;

export type Money = {
  amountMinor: number;
  currency: CurrencyCode;
};

/** Parse user input ("1 234,5") into minor units. Returns null for invalid input. */
export function parseAmount(
  _input: string,
  _currency: CurrencyCode,
  _locale?: string,
): number | null {
  // TODO(learn): implement
  throw new Error('parseAmount: not implemented');
}

/** Format minor units for display using Intl.NumberFormat. */
export function formatMoney(_money: Money, _locale?: string): string {
  // TODO(learn): implement
  throw new Error('formatMoney: not implemented');
}

/** Add two amounts of the same currency. Throws on currency mismatch. */
export function addMoney(_a: Money, _b: Money): Money {
  // TODO(learn): implement
  throw new Error('addMoney: not implemented');
}
