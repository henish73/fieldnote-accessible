# Fieldnote redesign test report

Run: 2026-11-25 18:31 - headless Microsoft Edge - https://henish73.github.io/fieldnote-accessible/?v=4

**92 passed, 0 failed** (92 tests)

## Functional

| Result | Test | Detail |
| --- | --- | --- |
| PASS | '/' moves focus to the search box | |
| PASS | Empty search shows an error instead of doing nothing | |
| PASS | Down arrow opens suggestions and highlights the first one | |
| PASS | Escape closes suggestions | |
| PASS | Enter submits the search and focus moves to the results heading | 10 results for “campus bike repair”|
| PASS | Error clears after a valid search | |
| PASS | Page title names the view | |
| PASS | Paging: page 2 opens and is marked current | |
| PASS | Enter on a type button applies it | |
| PASS | Type change is announced in words | |
| PASS | Arrow key picks Free only | |
| PASS | Filtered list shows Free/Paid in words, past event grouped | |
| PASS | 'u' undoes the last change | |
| PASS | Enter on a radio choice selects it | |
| PASS | 'Show all results again' clears type and filter | |
| PASS | Opening a result moves focus to its heading | |
| PASS | Event page shows when, cost and a copy button | |
| PASS | Back returns focus to the same result | |
| PASS | Browser Back button returns to the results | #q=campus+bike+repair&type=Events&filter=free|
| PASS | Task 3: map has a text purpose naming the repair stand marker | |
| PASS | Task 3: places listed in text with shape and position | |
| PASS | Task 4: 'Edit your search' selects the old words | |
| PASS | Task 4: a suggested search gives results | |
| PASS | No results with filters offers to search without them | |
| PASS | Set B: library workshop filter finds the citation workshop | |
| PASS | Set B: quiet study map names its marker | |
| PASS | '?' opens the shortcuts dialog with focus inside | |
| PASS | Shortcuts can be turned off (WCAG 2.1.4) | |
| PASS | Refreshing a link restores the same view | |
| PASS | Clear empties the box and keeps focus there | |

## Usability (keystrokes)

| Result | Test | Detail |
| --- | --- | --- |
| PASS | Task 1: search, open a result, go back in 7 steps (target <= 8) | |
| PASS | Task 2: record a free workshop in 12 steps (target <= 13) | |
| PASS | Task 3: open the North Quad map in 8 steps (target <= 9) | |
| PASS | Task 4: recover from no results in 6 steps (target <= 7) | |

## Accessibility

| Result | Test | Detail |
| --- | --- | --- |
| PASS | axe-core: no violations on Home | []|
| PASS | axe-core: no violations on Results | []|
| PASS | axe-core: no violations on Filtered | []|
| PASS | axe-core: no violations on No results | []|
| PASS | axe-core: no violations on No results + filters | []|
| PASS | axe-core: no violations on Event page | []|
| PASS | axe-core: no violations on Map page | []|
| PASS | axe-core: no violations in the shortcuts dialog | []|

## Structure and order

| Result | Test | Detail |
| --- | --- | --- |
| PASS | Home: one h1, no skipped heading levels | OK 122|
| PASS | Results: one h1, no skipped heading levels | OK 12333332|
| PASS | Filtered: one h1, no skipped heading levels | OK 1233232|
| PASS | No results: one h1, no skipped heading levels | OK 122|
| PASS | No results + filters: one h1, no skipped heading levels | OK 122|
| PASS | Event page: one h1, no skipped heading levels | OK 1|
| PASS | Map page: one h1, no skipped heading levels | OK 12|
| PASS | Landmarks: banner, search, main, contentinfo present | |
| PASS | Page language set | |
| PASS | No positive tabindex anywhere | |
| PASS | Results: Tab order follows reading order (top to bottom) | 22 stops, 0 backward jumps|
| PASS | Results: every Tab stop is visible on screen | |
| PASS | Filtered: Tab order follows reading order (top to bottom) | 19 stops, 0 backward jumps|
| PASS | Filtered: every Tab stop is visible on screen | |
| PASS | Event page: Tab order follows reading order (top to bottom) | 8 stops, 0 backward jumps|
| PASS | Event page: every Tab stop is visible on screen | |

## UI/UX layout

| Result | Test | Detail |
| --- | --- | --- |
| PASS | Home: every control is at least 44x44 px | []|
| PASS | Home: every control shows a focus indicator | []|
| PASS | Results: every control is at least 44x44 px | []|
| PASS | Results: every control shows a focus indicator | []|
| PASS | Filtered: every control is at least 44x44 px | []|
| PASS | Filtered: every control shows a focus indicator | []|
| PASS | No results: every control is at least 44x44 px | []|
| PASS | No results: every control shows a focus indicator | []|
| PASS | No results + filters: every control is at least 44x44 px | []|
| PASS | No results + filters: every control shows a focus indicator | []|
| PASS | Event page: every control is at least 44x44 px | []|
| PASS | Event page: every control shows a focus indicator | []|
| PASS | Map page: every control is at least 44x44 px | []|
| PASS | Map page: every control shows a focus indicator | []|
| PASS | Spacing: no overlapping blocks in the results page | gaps px: [18,12,6,26,0,28]|
| PASS | Alignment: search, heading, filters and results share one left edge | left x: [190,190,190,190]|
| PASS | Readable body text: line height at least 1.5, size at least 16 px | 1.60 / 17px|
| PASS | Line length stays readable (under ~90 characters) | about 84 characters per line|
| PASS | Reflow at 320 px (= 400%/200% zoom): no sideways scroll on Home | overflow 0 px|
| PASS | Reflow at 320 px (= 400%/200% zoom): no sideways scroll on Results | overflow 0 px|
| PASS | Reflow at 320 px (= 400%/200% zoom): no sideways scroll on Filtered | overflow 0 px|
| PASS | Reflow at 320 px (= 400%/200% zoom): no sideways scroll on No results | overflow 0 px|
| PASS | Reflow at 320 px (= 400%/200% zoom): no sideways scroll on No results + filters | overflow 0 px|
| PASS | Reflow at 320 px (= 400%/200% zoom): no sideways scroll on Event page | overflow 0 px|
| PASS | Reflow at 320 px (= 400%/200% zoom): no sideways scroll on Map page | overflow 0 px|
| PASS | Reflow at 640 px (= 400%/200% zoom): no sideways scroll on Home | overflow 0 px|
| PASS | Reflow at 640 px (= 400%/200% zoom): no sideways scroll on Results | overflow 0 px|
| PASS | Reflow at 640 px (= 400%/200% zoom): no sideways scroll on Filtered | overflow 0 px|
| PASS | Reflow at 640 px (= 400%/200% zoom): no sideways scroll on No results | overflow 0 px|
| PASS | Reflow at 640 px (= 400%/200% zoom): no sideways scroll on No results + filters | overflow 0 px|
| PASS | Reflow at 640 px (= 400%/200% zoom): no sideways scroll on Event page | overflow 0 px|
| PASS | Reflow at 640 px (= 400%/200% zoom): no sideways scroll on Map page | overflow 0 px|
| PASS | Text spacing override (WCAG 1.4.12): nothing is clipped | []|
| PASS | Reduced motion: change highlight does not animate | |

