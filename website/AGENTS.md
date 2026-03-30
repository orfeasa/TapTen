# Website Notes

## Structure
- Keep documentation and maintenance notes in `website/`.
- Keep the publicly deployed static site in `website/public/`.

## Public Site Rules
- The GitHub Pages workflow deploys `website/public/`.
- Prefer plain static HTML and CSS.
- Do not add a framework or build step unless there is a strong reason.
- Keep external dependencies minimal.
- If linking to third-party services such as beta forms, make that obvious in the copy.

## Content
- The website should reflect the current shipped or beta product, not aspirational features.
- Use the same plain-language role wording as the app: `player holding the phone`, `guessing team`, `one phone`.
- Keep the landing-page hierarchy beta-first: `Join Beta` and `See How It Works` should carry the visual emphasis.
- Keep support/privacy links easy to find, but de-emphasized relative to beta signup.
- In the `Try Beta` panel, favor beta signup and privacy links over direct support actions.
