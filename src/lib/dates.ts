/**
 * Date helpers. Transactions store `occurred_on` as a plain date ('YYYY-MM-DD'); timestamps are UTC.
 *
 * 🎓 learning mode: implement these yourself, test-first (dates.test.ts).
 * Edge cases: month_start_day = 29/30/31 in February, leap years, year boundaries, time zones.
 */

/** 'YYYY-MM-DD' in the user's local calendar. */
export type ISODate = string;

/** Local calendar date of `date` as 'YYYY-MM-DD' (no UTC shift!). */
export function toISODate(_date: Date): ISODate {
  // TODO(learn): implement
  throw new Error('toISODate: not implemented');
}

/**
 * The budget month containing `today`, respecting the user's `month_start_day` (1–31).
 * `end` is inclusive.
 */
export function getBudgetMonth(
  _today: Date,
  _monthStartDay: number,
): { start: ISODate; end: ISODate } {
  // TODO(learn): implement
  throw new Error('getBudgetMonth: not implemented');
}
