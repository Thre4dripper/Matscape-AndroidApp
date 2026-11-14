# Matscape design handoff

This file is how the app tells the design what has changed. The app is
built in Flutter in this repository; the design lives in this project
(the HTML prototype, the layout boards, the store pictures and the films).

**Designer (Open Design or Claude Design): start here.**

1. Look at the pictures in `reference/`. They are rendered from the real
   app, so they are the truth for how every screen looks today.
2. Work through "Waiting for design" below, top to bottom.
3. Keep the design system exactly: colours, type, spacing, radii, icon
   style, light and dark themes. Add what is missing and correct what has
   changed; do not restyle screens that already match.
4. Keep every file name and output size, so the render scripts still work.
5. When you finish an entry, move it to "Done" with the date, and list the
   files you changed. Say plainly if something could not be matched.

## What is in `reference/`

Each folder is a device; each picture is one screen or state. Sizes are in
points, pictures are at 2×. The system status bar and camera are not drawn.
Labels use the Mac's system face in place of each platform's own; maths is
the app's bundled STIX, exactly as on a device.

| Folder | Device | Size |
| --- | --- | --- |
| `iphone/` | iPhone, light | 402×874 |
| `iphone-dark/` | iPhone, dark | 402×874 |
| `android-small/` | Small Android phone | 360×800 |
| `iphone-landscape/` | iPhone on its side | 874×402 |
| `iphone-duo-closed/` | iPhone Duo, outer screen | 466×678 |
| `iphone-duo-closed-landscape/` | iPhone Duo outer, on its side | 678×466 |
| `iphone-duo-open/` | iPhone Duo, inner screen | 669×951 |
| `ipad-mini/` | Small tablet | 744×1133 |
| `ipad-11/`, `ipad-11-dark/` | Large tablet | 1180×820 |
| `iphone-full-page/` | A whole solution in one tall picture | 402 wide |

## Where the design stands

The prototype (`app.html`, `app/`) matches the app as it was on
13 November 2026, before any entry below. The store pictures and films are
captured from the prototype, so they show that older app too.

## Waiting for design

### H-001 · Step-by-step solutions

Added 14 Nov 2026 · commits `e2a0075`, `b5cd822` · affects: prototype,
layout boards, store pictures, films

The headline feature. A Steps button under every result opens the
expression worked out one operation at a time.

- **Steps screen.** Title "Steps · Expression 1", back arrow, copy icon at
  the top right. On large tablets and open foldables it sits in the
  right-hand pane with a close X; on small tablets it replaces the
  workspace column; on phones it is full screen.
- **Top.** The expression in the maths serif, large, then "= value". Then a
  small-caps label, "10 STEPS".
- **Step card.** 16px radius, 1px border, surface colour. A 24px numbered
  bubble (accent-soft fill, accent ink), the title in semibold, the
  sub-expression in the maths serif, "= value", and a one-line note in
  secondary ink.
- **Working.** Below a hairline, a 44px row "Show the working" with a
  chevron, in accent ink; open, it reads "Hide the working". The methods
  are a segmented control that hugs its labels and scrolls sideways:
  "Cofactor expansion | Row reduction", "Formula | Gauss–Jordan |
  Adjugate", "Elimination | Cramer's rule | Inverse".
- **Lines of working.** Four kinds: prose (small, secondary ink); maths
  lines in the serif; a captioned matrix; a row-operation block (12px
  radius on the page background, small numbered bubble, the operation,
  then the matrix with a divider bar when augmented). Working that belongs
  to a minor is indented with a 2px guide line at its left.
- **Answer.** The last card has an accent border and an "ANSWER" tag at the
  right of its title. A solution with one step shows just that card, with
  its working open.
- **Loader.** Long working shows a small spinner and "Working out the full
  solution…" until it is ready.

Reference: `iphone/03-steps-determinant-cofactors.png`,
`iphone/04-steps-determinant-row-reduction.png`,
`iphone/05-steps-ten-steps.png`, `iphone/06-steps-working-open.png`,
`iphone-full-page/01-steps-ten-steps-full.png`, `ipad-mini/02-steps.png`,
`ipad-11/03-steps-in-side-pane.png`, `ipad-11/04-steps-ten-steps.png`,
`iphone-dark/03-steps-determinant-cofactors.png`.

### H-002 · The actions under a result

Added 14 Nov 2026 · commit `b5cd822` · affects: prototype, layout boards,
store pictures

Matrix results now read, on one row: the size ("3×3") at the left, then
Steps · Inspect · Save · copy icon. "Save as matrix" is now "Save". Number
results read "= 43" with Steps and the copy icon at the right. A value on
its own, such as "A", has no Steps button.

Reference: `iphone/02-results.png`, `android-small/02-results.png`.

### H-003 · The inspector follows the active expression

Added 14 Nov 2026 · commit `82ee7d9` · affects: prototype, layout boards

- Titles say "Inspector · Expression 2", never "Line 2".
- When the active expression gives a number, the side inspector shows an
  eye icon, "No matrix to inspect", a sentence, a "See the steps" link, and
  "MATRICES IN THIS EXPRESSION" with a row per matrix.
- Tapping Inspect on a tablet makes that expression the active one. Nothing
  opens on top of the inspector.

Reference: `ipad-11/01-workspace-inspector-no-matrix.png`,
`ipad-11/02-inspect-makes-expression-active.png`, `iphone/07-inspector.png`.

### H-004 · Copy as LaTeX

Added 14 Nov 2026 · commit `5e23f5d` · affects: prototype

Settings has a new group, "Copying", with "Copy as": Plain text | LaTeX and
a line of help under it. After copying, the toast reads "Copied as LaTeX".

Reference: `iphone/14-settings.png`, `ipad-mini/03-settings.png`.

### H-005 · A phone on its side: 60/40

Added 14 Nov 2026 · commit `5b7f46d` · affects: prototype, layout boards

The content takes 60% of the usable width and the keypad 40%, in the
workspace and in the matrix editor.

Reference: `iphone-landscape/01-workspace.png`,
`iphone-landscape/02-matrix-editor.png`.

### H-006 · iPhone Duo, outer screen

Added 14 Nov 2026 · commit `766ba2c` · affects:
`layouts/iphone-duo-closed.html`, store pictures of foldables

iOS keeps an 84pt strip down one side of the outer screen for the camera,
clock and Wi-Fi. The matrices now live in that strip as a column of 60×54
tiles (italic name over the size, 14px radius) with a "+" tile last,
starting below the status items. The "MATRICES" row above the expressions
is gone on this screen. On its side, the strip is at the left.

Reference: `iphone-duo-closed/01-workspace.png`,
`iphone-duo-closed/02-steps-determinant.png`,
`iphone-duo-closed-landscape/01-workspace.png`,
`iphone-duo-open/01-workspace.png`.

### H-007 · First-launch tour

Added 14 Nov 2026 · commit `a98c736` · affects: prototype, films

Nine pages with Skip, Back, Next and "Get started", each with a small
figure: Welcome to Matscape; Matrices live at the top; Write expressions
underneath; A keypad made for matrices; Exact answers you can reuse; See
the working, and look inside; Every operation, explained; Sample
workspaces to learn from; The rest is in the menu. Help has "Take the tour
again".

Reference: `iphone/16-tour-welcome.png`,
`iphone/17-tour-steps-and-inspector.png`, `iphone/15-help.png`.

### H-008 · A page for each library operation

Added 14 Nov 2026 · commits `b9899a8`, `815e494` · affects: prototype,
store pictures

Tapping an operation opens its own page: what it is, how to write it, and
examples shown as real matrices plus the one-line form. Two buttons at the
bottom: "Insert" and "Try it out".

Reference: `iphone/09-library.png`, `iphone/10-library-operation.png`,
`ipad-11/05-library.png`.

### H-009 · Drag to reorder

Added 14 Nov 2026 · commits `0021f93`, `0e2efc0` · affects: prototype,
layout boards

A grip of dots sits at the top right of each matrix card, at the left of
each matrix chip, and under the number in each expression's gutter.

Reference: `iphone/01-workspace.png`, `ipad-11/01-workspace-inspector-no-matrix.png`.

### H-010 · Sample workspaces

Added 14 Nov 2026 · commit `6b77804` · affects: prototype

Twelve sample workspaces, one per topic, and "Restore samples" on the
Workspaces screen.

Reference: `iphone/13-workspaces.png`.

### H-011 · Store pictures and films

Added 14 Nov 2026 · affects: `store/`, `motion-source/`

- Redo picture 04 (step-by-step) with the new Steps screen, and make Steps
  the second picture in every set. Suggested captions: "Every step, worked
  out", "Choose your method", "From matrix to answer, line by line".
- Add a Steps scene to each film: tap Steps, open a step, switch method.
- Re-render every store size and all three films once H-001 to H-010 are
  in the prototype.

### H-012 · Backup & sync with Google Drive

Added 15 Nov 2026 · affects: prototype, layout boards,
store pictures (optional)

A new first group in Settings, **Backup & sync**, holding one card:

- **Off:** a cloud icon, the title "Back up and sync", a short explanation
  (stored privately in the user's own Google Drive; Matscape has no
  servers) and a primary button, "Connect Google Drive".
- **Connected:** the Google account's email as the title, "Synced just now"
  (or "5 minutes ago") under it, and two buttons side by side: "Sync now"
  (with a sync icon) and "Disconnect".
- **Working:** "Waiting for Google…" or "Syncing…", with a small spinner at
  the right of the title.
- **Failed:** the line turns to the danger colour: "Couldn't sync: … Your
  work is safe on this device, and it will try again."
- **Needs connecting again:** the danger line "Google Drive access has run
  out…" and a primary "Connect again" button.
- **Disconnect** asks first, in the app's usual confirm card.
- **When connected**, under the buttons: a small heading, "Changes from
  your other devices", one line saying what the choice does, and a
  two-part switch in the app's segmented style: **On opening** (the
  default: nothing changes on screen while you work) and **Live** (checks
  every 30 seconds while the app is open).

**After a sync**, a notice in the usual pill at the top of the screen:

- A workspace deleted on another device: "“Name” was deleted on another
  device", with an underlined bold **Undo** inside the pill. This pill stays
  ten seconds instead of two, and Undo brings the workspace back (and
  reopens it if it was open).
- Two devices changed one workspace: "Changed on two devices: both kept,
  one as “Name (from iPad)”".

Also: workspace rows and the delete card now say "1 line" and "1 matrix"
rather than "1 lines" and "1 matrices".

The tour's last page and Help each gain a sentence about it.

Reference: `iphone/14-settings.png`, `iphone/14b-settings-synced.png`,
`iphone/14c-deleted-on-another-device.png`, `ipad-mini/03-settings.png`,
`ipad-mini/04-settings-synced.png`.

### H-013 · Matrix editor saves on Done, with undo and redo

Added 15 Nov 2026 · affects: prototype, layout boards

Changes in the matrix editor are no longer applied as they are typed: they
wait for **Done**.

- **Top row:** two new icon buttons, **Undo** and **Redo** (curved arrows in
  the set's stroke style), sit left of Delete, Duplicate and Inspect, with a
  thin vertical divider between the two groups. All five icons are 32px wide
  now (were 40) so the row still fits a phone. Undo and Redo are dimmed when
  there is nothing to undo or redo. Where the row is short of room (phones),
  the word "Matrix" before the name chip is left out rather than cut off.
- **Unsaved changes:** a small dot appears before "Done" inside the Done
  pill, and the hint line under the entry field reads "Not saved yet · Done
  saves your changes" in the accent ink, after a small accent dot.
- **Leaving with unsaved changes** (tapping outside, dragging the sheet
  down, Android's back): a card in the usual confirm style, "Save changes
  to A?", "You changed this matrix. Changes are kept only when you save
  them.", with two full-width buttons stacked: **Save changes** (primary)
  and **Discard changes** (danger). Tapping outside the card keeps editing.

Reference: `iphone/08-matrix-editor.png`,
`iphone/08b-matrix-editor-unsaved.png`,
`iphone/08c-matrix-editor-save-changes.png`.

## Done

Nothing yet.

## Adding an entry

Use the next number. Give the date, the commits, what it affects (prototype,
layout boards, store pictures, films), what changed in a designer's terms,
and the reference pictures that show it.
