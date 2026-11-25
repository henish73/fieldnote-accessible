# Fieldnote Search – accessible redesign

A keyboard-first redesign of the Fieldnote Search simulator (COSC 2596, A5 Accessible UI).
Original: https://somang.github.io/cosc2596a5/

Single self-contained page (`index.html`), same sample data as the original.

## What changed
- Every control is a real button, radio button or form field: Enter submits, Tab reaches everything, suggestions work with arrow keys and Escape.
- Visible focus outline with a gold halo; focus moves to the new heading after each view change, and Back returns focus to the result that was opened.
- Free / Paid / Past event shown as text badges; type and filter controls always visible with their current state.
- Map markers are numbered, shaped and labelled, with a text list of places.
- Helpful no-results screen: names the search, gives tips, "Edit your search" and suggested searches.
- Labelled search box, landmarks and headings, page title per view, screen-reader announcements, zoom allowed, responsive layout.
- Chestnut and pale-yellow theme; all text meets WCAG 2.2 AA contrast in light and dark mode.
