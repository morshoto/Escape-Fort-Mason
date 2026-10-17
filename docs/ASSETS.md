# Character asset provenance

## Sam-inspired player skin

The selected reusable character model is `player/sam/sam_skin.tscn`.

- Source: locally authored in this repository from Godot primitive meshes.
- License: the scene and script are project-authored source covered by the MIT
  license in [LICENSE](../LICENSE).
- No third-party model, texture, or animation is included by the Sam skin.
- Design: a fictional Sam-inspired caricature using dark hair, glasses, a red
  hoodie, navy pants, and light shoes. It is not a facial likeness or an
  endorsement.
- Reuse: the scene extends the shared `CharacterSkin` contract and can replace
  the player visual without changing movement, collision, camera, or weapon
  code.

## Retained baseline skin

`player/gdbot/` remains in the repository as the rollback/reference skin. It
originates from the GDQuest third-person controller sample and remains subject
to the upstream attribution and CC-BY-NC-SA 4.0 terms recorded in [LICENSE](../LICENSE).

The Sam skin intentionally does not copy or modify those art assets.
