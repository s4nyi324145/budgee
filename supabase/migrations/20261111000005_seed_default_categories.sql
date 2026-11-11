-- Default categories (user_id NULL), shared and read-only for all users.
-- This is a migration, not seed.sql: seed.sql only runs on a local `db reset`.
-- Colors are contrast-safe foregrounds; the app derives the light background tint.

insert into public.categories (user_id, key, name, icon, color, type, sort_order) values
  (null, 'food',          'Food',          'utensils',        '#B45309', 'expense', 10),
  (null, 'transport',     'Transport',     'bus',             '#1D4ED8', 'expense', 20),
  (null, 'fun',           'Fun',           'party-popper',    '#BE185D', 'expense', 30),
  (null, 'rent',          'Rent',          'home',            '#6A45F5', 'expense', 40),
  (null, 'subscriptions', 'Subscriptions', 'repeat',          '#0F766E', 'expense', 50),
  (null, 'education',     'Education',     'book-open',       '#4B5563', 'expense', 60),
  (null, 'health',        'Health',        'heart-pulse',     '#B91C1C', 'expense', 70),
  (null, 'other',         'Other',         'circle-ellipsis', '#6B6578', 'expense', 80),
  (null, 'allowance',     'Allowance',     'wallet',          '#15803D', 'income',  10),
  (null, 'scholarship',   'Scholarship',   'graduation-cap',  '#047857', 'income',  20),
  (null, 'job',           'Job',           'briefcase',       '#4D7C0F', 'income',  30),
  (null, 'gift',          'Gift',          'gift',            '#A21CAF', 'income',  40),
  (null, 'other_income',  'Other',         'circle-ellipsis', '#6B6578', 'income',  50);
