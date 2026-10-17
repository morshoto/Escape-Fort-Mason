# Sam Altman character reference

This is a stylized, non-photoreal character brief. It uses recurring visual
cues from official Sam Altman appearances rather than copying a photograph or
claiming endorsement.

## Primary sources reviewed

- [OpenAI Forum event replay](https://forum.openai.com/public/videos/event-replay-sam-altman-on-building-the-future-of-ai-2026-04-06)
- [OpenAI Town Hall](https://www.youtube.com/watch?v=Wpxv-8nG8ec)
- [OpenAI DevDay 2025 opening keynote](https://www.youtube.com/watch?v=hS1YqcewH0c)
- [OpenAI official UN Security Council remarks](https://openai.com/index/sam-altman-un-security-council-remarks/)

The first three sources provide appearance and presentation context. The UN
remarks are an official Sam Altman text source and help anchor the public,
measured speaking tone. Appearance varies between recordings, so the model
uses shared cues instead of one frozen pose.

## Design decisions

| Feature | Observed cue | Character treatment |
| --- | --- | --- |
| Face shape | Slightly long, narrow oval with a defined chin | Quaternius male face remains visible; no oversized cartoon head |
| Hair | Short-to-medium dark hair with a natural side part or wave | Quaternius `Hair_SimpleParted` asset, recolored dark brown |
| Eyes and brows | Unobtrusive eyes and natural brows; no signature eyewear | Quaternius face and brows are retained; no visor or flashy glasses |
| Nose and chin | Subtle, human facial planes | Original Quaternius face texture is retained |
| Clothing | Simple dark technical layers, often black or muted blue | Dark jacket/top shader with a muted blue center layer and charcoal pants |
| Mood | Calm, focused, understated presenter | Neutral relaxed A-pose with restrained colors and natural proportions |

## Implementation boundary

`player/sam/sam_skin.tscn` keeps the shared `CharacterSkin` animation state
machine and uses the Quaternius Universal Base Characters male glTF as its
human base. `player/sam/sam_skin.gd` applies the fitted clothing shader and
relaxes the imported T-pose by posing both upper arms downward. No reference
photos or scraped likeness assets are committed.

## Visual review captures

- [Front](screenshots/sam-front.png)
- [45-degree](screenshots/sam-angle45.png)
- [Side](screenshots/sam-side.png)
- [Back](screenshots/sam-back.png)
- [Operated in the actual game scene](screenshots/sam-gameplay.png)
