# Stage 4 — Delivery (how to think)

**Goal of the stage:** show the result to the user so that (a) they actually see the images in chat on the first try, (b) they understand what it is and why it was done this way, (c) they can quickly decide "ok / redo / iterate".

This is not just `Read`-ing a file. It is the final artifact of the work — present it like a product, not like raw output.

## Hard rules (violation = delivery failure)

1. **Every generated frame is shown via `Read` as a separate call.** Not just paths as links, not "images in folder X", not a markdown link instead of a render. If you wrote "files are here: …" and did not `Read` — you did NOT deliver the result, redo it.
2. **An anchor caption above each `Read`** in the format `**N. <type> — <role>:**`. Without an anchor the user can't refer to a frame when requesting edits.
3. **A clean path without colons.** Before showing, copy from `<event_id>/image_N.png` (contains `:`) to `<sku>/slide_N_<label>.png`. The colon breaks rendering.
4. **All N frames, not just the first.** A photoshoot/infographic with 5 frames = 5 `Read` calls. One after another.
5. **The summary comes after all images, not instead of them.**

## Images first, text second

The user wants to see the result. Don't write "generation complete, paths below" — they won't go open files in Finder. Show them in chat via `Read`.

## Clean paths for rendering

Scripts save to `~/.claude/output/photo-editor/<event_id>/`, where `event_id` has the form `image:abc123` or `group:abc123`. **A colon in the path** breaks image rendering in some clients with a Read-tool (observed: the first Read does not display visually, then nothing).

Before showing, copy the files to a clean per-SKU/per-task path (not `/tmp` — the user will want to find them later):

```bash
DEST="$HOME/.claude/output/photo-editor/<sku>"
mkdir -p "$DEST"
i=1
for f in "$HOME/.claude/output/photo-editor/<event_id>"/image_*.png; do
  cp "$f" "$DEST/slide_${i}_<label>.png"
  i=$((i+1))
done
```

`<label>` is a short descriptive suffix (`hero`, `feature_glass`, `vs_others`, `in_car`). It helps the user understand what's what and reopen later without searching by `event_id`.

## All frames, not just the first

A photoshoot or infographic with N frames — show **all N**. One `Read` = one image; you cannot "collapse" them into one.

## A caption above each image

One line before each `Read`:

```
**N. <Type> — <short role>:**
```

Examples:
- `**1. Infographic — cover:**`
- `**2. Infographic — features (glass + seatbelt):**`
- `**3. Photoshoot — lifestyle in a car:**`

The caption is an anchor. If the generation is to be redone, the user can say "redo #2, #4 stays good".

## Final block after all frames

Below the last image — a compact summary:

```
Done: <what was made>, model=<X>, aspect=<Y>
Output: ~/.claude/output/photo-editor/<event_id>/
Brief: ~/.claude/output/photo-editor/<sku>/brief.md
```

And **on a new line** a short phrase about the next step:
- "If something's off — tell me which frame and what to change, I'll redo it."
- Or: "Ready to do the next variant / another model / final tweaks?"

This lowers the barrier to iterating.

## What NOT to do

- **"Images are in folder X, open them"** instead of `Read` → the user won't. If they ask → it means the images didn't appear in chat and you did something wrong. Copy to a clean path and try again.
- **Dumping base64 / raw JSON / event_id into the main flow** → technical data, put it in meta.json or the brief file.
- **Staying silent about errors** → if the content filter returned an empty array, say so explicitly and offer to rephrase. Don't pretend everything is fine.
- **Embellishing the result** → if the product is distorted or the text is unreadable on one of the frames, say "here's the batch, on frame 3 the product lost its proportions a bit — worth redoing?". The user decides.
