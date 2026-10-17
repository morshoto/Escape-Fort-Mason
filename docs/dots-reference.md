# Dots companion visual reference

Reference checked on 2026-10-17: [OpenAI — Introducing dots](https://openai.com/index/introducing-dots/).

The official page is used as a broad visual reference for a small, friendly,
rounded companion with a simple expressive face. It is not a model or texture
source for this project.

## Selected variation

- Soft teal rounded body.
- Coral rounded top accent.
- Two white eyes with dark pupils facing the player’s forward direction.
- Small scale, floating at the player’s right and rear, above ground level.

The colors and proportions are an original game-specific variation, rather
than a reproduction of an official Dots character or brand asset.

## Provenance and license

No downloadable official 3D model was identified for reuse. `Dots.tscn` uses
only Godot’s built-in `SphereMesh` and `StandardMaterial3D` resources, authored
in this repository. No third-party mesh, texture, or extracted data is
included, so there is no additional asset license to carry.

## Known differences and follow-up

This MVP has one primitive-based appearance, no facial animation, and no
obstacle avoidance. The companion is visual-only: it has no collision body and
cannot block Sam. A higher-fidelity model, expressions, and navigation-aware
positioning can be separate follow-up work.
