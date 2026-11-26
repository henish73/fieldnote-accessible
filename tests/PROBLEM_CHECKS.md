# Fieldnote: four deliberate problems, every button, professor tasks

Run: 2026-11-25 19:09 - headless Microsoft Edge - https://henish73.github.io/fieldnote-accessible/?v=7

**35 passed, 0 failed** (35 tests)

## Problem 1: Back button

| Result | Test | Detail |
| --- | --- | --- |
| PASS | Guide page: 'Back to results' returns to the list with focus on the same result | #q=campus+bike+repair / open-bike-hub|
| PASS | Map page: 'Back to results' returns to the list with focus on the same result | #q=campus+bike+repair / open-north-quad|
| PASS | Event page: 'Back to results' returns to the list with focus on the same result | #q=campus+bike+repair / open-gear-clinic|
| PASS | Opened from a shared link: Back still goes to the filtered results | #q=campus+bike+repair&type=Events&filter=free|
| PASS | Browser Back from a result returns to the results | #q=campus+bike+repair|
| PASS | Browser Back again returns to the home page | #home|
| PASS | Browser Back undoes the last filter step by step | #q=campus+bike+repair&type=Events|

## Problem 2: free bike repair workshop under Free only

| Result | Test | Detail |
| --- | --- | --- |
| PASS | Events + Free only for 'campus bike repair' lists Fix a Flat Tire workshop | ["Winter bike maintenance workshop","Fix a Flat Tire workshop","Bike lights and visibility workshop (past event)"]|
| PASS | Events + Free only for 'bike repair workshop' lists Fix a Flat Tire workshop | ["Winter bike maintenance workshop","Fix a Flat Tire workshop","Bike lights and visibility workshop (past event)"]|
| PASS | Events + Free only for 'free bike repair workshop' lists Fix a Flat Tire workshop | ["Winter bike maintenance workshop","Fix a Flat Tire workshop","Bike lights and visibility workshop (past event)"]|
| PASS | Events + Free only for 'bike workshop' lists Fix a Flat Tire workshop | ["Winter bike maintenance workshop","Fix a Flat Tire workshop","Bike lights and visibility workshop (past event)"]|
| PASS | Events + Free only for 'bike repair' lists Fix a Flat Tire workshop | ["Winter bike maintenance workshop","Fix a Flat Tire workshop","Bike lights and visibility workshop (past event)"]|
| PASS | Free only with all types also lists it (across result pages) | |
| PASS | Every listed event says Free in words | |

## Problem 3: filters visible, not top right

| Result | Test | Detail |
| --- | --- | --- |
| PASS | At 1100 px: filters sit under the heading on the left, inside the first screen | left 44, top 279, viewport 1100x800|
| PASS | At 1100 px: all Type and Show choices are visible without opening a menu | |
| PASS | At 1440 px: filters sit under the heading on the left, inside the first screen | left 116, top 279, viewport 1440x800|
| PASS | At 1440 px: all Type and Show choices are visible without opening a menu | |
| PASS | At 360 px: filters sit under the heading on the left, inside the first screen | left 20, top 336, viewport 360x800|
| PASS | At 360 px: all Type and Show choices are visible without opening a menu | |

## Problem 4: bigger map markers

| Result | Test | Detail |
| --- | --- | --- |
| PASS | At 1100 px: both markers are at least 44 px | sizes [44,44] (was 30)|
| PASS | At 1100 px: marker labels are not cut off | []|
| PASS | At 320 px: both markers are at least 44 px | sizes [44,44] (was 30)|
| PASS | At 320 px: marker labels are not cut off | []|

## Every button works

| Result | Test | Detail |
| --- | --- | --- |
| PASS | Home: all 11 visible buttons and links do something, no script errors | |
| PASS | Results: all 22 visible buttons and links do something, no script errors | |
| PASS | Filtered: all 19 visible buttons and links do something, no script errors | |
| PASS | No results: all 14 visible buttons and links do something, no script errors | |
| PASS | No results + filters: all 22 visible buttons and links do something, no script errors | |
| PASS | Event page: all 7 visible buttons and links do something, no script errors | |
| PASS | Map page: all 6 visible buttons and links do something, no script errors | |

## Professor tasks (keyboard only)

| Result | Test | Detail |
| --- | --- | --- |
| PASS | Task 1: search campus bike repair, open a result, go back to the results | #q=campus+bike+repair / open-bike-hub|
| PASS | Task 2: Events + Free only, record title, date and time | Fix a Flat Tire workshop - When Nov 28 · 1:00 p.m. Cost Free Where On campus From Campus Cycle Hub|
| PASS | Task 3: open the North Quad map and identify the repair stand marker | 11. Repair stand — circle marker, top centre of the map|
| PASS | Task 4: from the no-results screen get back to a useful search | |

