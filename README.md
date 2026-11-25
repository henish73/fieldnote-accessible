# Fieldnote Search – accessible redesign

A keyboard-first redesign of the Fieldnote Search simulator (COSC 2596, A5 Accessible UI).
Original: https://somang.github.io/cosc2596a5/ · Live redesign: https://henish73.github.io/fieldnote-accessible/

Single self-contained page (`index.html`), same sample data and ranking as the original.

## Audit fixes (F1–F9)
- Every control is a real button, radio button or form field; Enter works in the search box, on suggestions and on filter choices.
- Visible focus outline with a gold halo; focus moves to the new heading after each view change; Back returns focus to the result you opened.
- Free / Paid / Past event as text badges; type and filter controls always visible with their state.
- Numbered, shaped, labelled map markers plus a text list of places.
- Helpful no-results screen; labelled search box; headings, landmarks, page titles; screen-reader announcements; zoom allowed; responsive.
- Plum (#672367) on near-white lilac; all text meets WCAG 2.2 AA contrast.

## Minimal layout (v4)
- One 760px column: slim top bar, one search field, two short filter rows (Type, Show), a plain result list, related searches at the end. No side panels or cards.
- The no-results page puts "Edit your search" first, so it is one Tab from the heading; filters only appear there when they are on.
- Detail pages: Back link, one row of key facts (When, Cost, Where, From), a copy button for events, then the map with its text list.

## Changes based on the COSC 2596 lectures
| Lecture idea | Change |
|---|---|
| Lec 8 Consistency: "all user actions must be reversible" | Undo after every type/filter change (button or `u`); browser Back/Forward work |
| Lec 8 Consistency: keyboard equivalents / power keys | Single-key shortcuts `/` `r` `f` `u` `?` with a help panel and an on/off switch (WCAG 2.1.4) |
| Lec 8 User feedback: correction & confirmation messages | Empty search shows an inline correction message; every change confirms the new result count |
| Lec 8 Context + hypermedia rules | Clear page headings and Back link; every view has its own link and survives a refresh |
| Lec 4 Attention: make information salient; change blindness | Event "When:" shown first; past events grouped under their own heading; the result line highlights when it changes (static under reduced motion) |
| Lec 4 External cognition: reduce memory load | Recent searches; "Copy title, date and time" on event pages |
| Lec 9 Alt text should say why an image is there | Map text states its purpose and which marker is which |
| Lec 9 Voice-only control / multi-modality | Every control has a visible name that matches its accessible name (e.g. "Clear" instead of "×"); works by keyboard, mouse, touch and voice |
| Lec 9 Situational limits (glare, weak connection) | High contrast, one small file, no external fonts or scripts |
| Lec 2/9 Krug, "Don't make me think" | Plain labels, one primary action per screen, skip links to results and filters |

## Tests
`tests/run-tests.ps1` drives headless Microsoft Edge with real key presses and checks functionality, keystrokes per task, axe-core (WCAG 2.2 AA), heading order, Tab order, target size, focus visibility, reflow at 320/640 px, text spacing and reduced motion. Put `axe.min.js` (axe-core 4.10) next to the script first. Latest results: [tests/TEST_REPORT.md](tests/TEST_REPORT.md).
