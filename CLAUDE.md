This project has split into two major parts: the frontend "./titan" and the backend "./enceladus"

titan is a Vue 3 project using the Composition API.

enceladus is an Elixir project using the cowboy/plug libraries for the HTTP server.

## Errors from API calls (titan)

When an API call fails (a network error, a 5xx, an upload that couldn't be stored, anything
that isn't the person's input being invalid), show it in the `ErrorBanner` component, never as
plain text on the page:

- On a page, call `useErrorBannerStore().show(message, action?)`; it renders the banner at the
  top of the page. Pass an `action` (e.g. `{ label: 'Log in', run: ... }`) when there's an obvious
  next step.
- Inside a modal sheet (`SheetDialog`), render `<ErrorBanner :message @dismiss>` inside the
  sheet instead, because the page's banner sits behind the modal (see `AvatarEditor.vue`).
- Messages say what failed and what to do, e.g. "Your image couldn't be uploaded. Please try
  again."

Validation errors (a 400 about a specific field, or a check before sending) stay as inline
`.fieldMessage.error` text under that field. So a `catch` checks for a field error first and
otherwise shows the banner; it never falls back to a generic "couldn't be saved" under the field.

- Keep what the person wrote (an open editor, a composer's text) so they can retry.
- Keep each failure message in a constant, and call `errorBanner.dismissMessage(THAT_MESSAGE)`
  when a retry succeeds, so the banner doesn't outlive the problem.
- Content that fails to load (a post, its comments) is different: it's shown in place of the
  missing content as an `EmptyState` with a "Try again" button, not in the banner.

