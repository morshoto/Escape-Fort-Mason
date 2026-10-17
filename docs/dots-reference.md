# Dots companion visual reference

Reference review date: 2026-10-17. The links below were opened and visually
checked before modeling. They are inspiration sources only; no reference image
or model was downloaded or copied into this repository.

## Source review

- [OpenAI — Introducing dots](https://openai.com/index/introducing-dots/):
  the official hero presents the yellow Alfred variation with a rounded,
  slightly triangular body, black round glasses, simple closed eyes, a black
  bow tie, a soft-looking surface, and no limbs.
- [OpenAI — DevDay 2026 recap](https://openai.com/index/devday-2026-recap/):
  confirms the DevDay context for the Dots announcement, but was not used as a
  detailed geometry reference.
- [Yahoo Tech / Mashable — OpenAI introduces Dots](https://tech.yahoo.com/ai/chatgpt/articles/openai-introduces-dots-always-ai-191547387.html):
  provides a clear Alfred front view matching the glasses, closed-eye lines,
  bow tie, and yellow body selected here.
- [ITmedia image](https://www.itmedia.co.jp/news/article/limage/2609/30/2000001868/10007940):
  shows the separate green Dottie variation with dark vertical eye panels and
  bright eye highlights. It was explicitly not mixed into Alfred.
- [Gadgets360 — Dots announcement](https://www.gadgets360.com/ai/news/openai-chatgpt-dots-announced-features-availability-explained-12118050):
  shows Alfred alongside other Dots variants and was used as a cross-check only.
- [News4JAX — DevDay coverage](https://www.news4jax.com/business/2026/09/29/openai-ceo-announces-new-ai-agent-and-avoids-mention-of-security-concerns-at-developer-conference/):
  provides event context and a stage-photo carousel, but no useful Alfred
  close-up; no character geometry was taken from it.

## Selected variation and implementation

This issue intentionally models yellow Alfred, not Dottie or a blended
variant. The implementation maps the reference traits as follows:

- bright yellow custom rounded-triangular body with a small asymmetry;
- black `TorusMesh` round frames, bridge, temple arms, and simple eye lines;
- black custom bow-tie wings with a spherical knot;
- no limbs, collision shape, physics body, or camera-obstructing attachment;
- a dedicated `AlfredVisual` facing frame so the visual follows Sam without
  changing the existing follow, bob, or rotation behavior.

The model is an unofficial, original in-repository reproduction. No official
downloadable Dots 3D model was identified. Body and bow-tie geometry are
generated with Godot `SurfaceTool`; the glasses and knot use Godot built-in
mesh classes and `StandardMaterial3D`. The project does not include copied
reference images, textures, or extracted assets.

## Known differences

The result is a low-poly approximation rather than OpenAI’s rendered plush
asset. It does not reproduce the exact material response, fur/fabric detail,
facial animation, or production lighting. Those differences are deliberate so
the companion remains a small, editable, Compatibility-renderer-safe scene.

## Captured evidence

The reproducible capture helper is
[`tools/capture_dots_visuals.gd`](../tools/capture_dots_visuals.gd). It saves
all views through a 640x640 `SubViewport`:

- [front](dots-screenshots/alfred-front.png)
- [45 degrees](dots-screenshots/alfred-45.png)
- [side](dots-screenshots/alfred-side.png)
- [back](dots-screenshots/alfred-back.png)
- [Sam and Dots gameplay](dots-screenshots/dots-with-sam.png)
