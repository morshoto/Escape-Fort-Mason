# Character asset provenance

## Sam Altman-inspired player skin

The selected reusable character model is `player/sam/sam_skin.tscn`.

- Base asset: Quaternius Universal Base Characters ([official page](https://quaternius.com/packs/universalbasecharacters.html)), Standard edition.
- Included source files: `player/sam/quaternius/` contains the selected male
  glTF, `Hair_SimpleParted` glTF, their buffers/textures, and the original
  `License_Standard.txt`.
- License: the Standard edition is CC0 1.0 Universal. The license text is
  preserved beside the imported assets.
- Adaptation: the Godot glTF source references were normalized to the bundled
  normal-map filenames; the model geometry and textures remain from Quaternius.
- Design: a fictional, cartoon Sam Altman impression using a narrow human face,
  dark parted hair, calm expression, muted blue technical layer, and charcoal
  trousers. It is not a facial likeness claim or an endorsement.
- Garment geometry: the scene adds one fitted jacket shell mesh with a front
  panel, collar, and hem to make the everyday technical layer visible as a
  garment rather than only a body color replacement.
- Reference brief: recurring cues and source links are documented in
  [sam-reference.md](sam-reference.md).
- Reuse: the scene extends the shared `CharacterSkin` contract and can replace
  the player visual without changing movement, collision, camera, or weapon
  code.
- Rights boundary: no reference photos, screenshots of real people, or scraped
  likeness assets are committed. The review screenshots are renders of the
  project-owned scene only.

## Retained baseline skin

`player/gdbot/` remains in the repository as the rollback/reference skin. It
originates from the GDQuest third-person controller sample and remains subject
to the upstream attribution and CC-BY-NC-SA 4.0 terms recorded in [LICENSE](../LICENSE).

The Sam skin does not copy or modify those baseline art assets.
