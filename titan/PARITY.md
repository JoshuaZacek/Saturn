# Frontend parity: old `titan/` (main) → redesign (`frontend`)

Inventory of everything the old frontend does, and where the redesign stands.
First drafted 2026-10-18, then updated after the parity work landed on `frontend` the same day.

Legend: ✅ done · 🟡 partial · ❌ missing · ⏸ deferred until the backend work in
`enceladus/PARITY.md` lands · (Dn) refers to [Decisions](#decisions)

---

## 1. Routes

| Old route             | New route                                              | Status | Notes                                                              |
| --------------------- | ------------------------------------------------------ | ------ | ------------------------------------------------------------------ |
| `/` (all-posts feed)  | `/all?sort=new`, `/all?sort=top&t=day` (sidebar Feeds) | ✅     | `/` itself will be the subscriber feed ⏸ (D1); still a placeholder |
| `/:moon`              | `/:moon?sort=…&t=…`                                    | ✅     | see §4                                                             |
| `/post/:id/:comment?` | `/post/:post_id/:comment_id?`                          | ✅     | see §5                                                             |
| `/@:username`         | `/@:username?tab=…&sort=…`                             | ✅     | see §6                                                             |
| `/settings`           | `/settings/:step(email\|password\|delete)?`            | ✅     | see §7                                                             |
| `/create/post`        | `/create/post?moon=…`                                  | ✅     | see §8                                                             |
| `/create/moon`        | `/create/moon`                                         | ✅     | see §9                                                             |
| `/404` + catch-all    | catch-all `not-found`                                  | ✅     | see §11                                                            |
| —                     | `/unauthorized` (new only)                             | ✅     | replaces old "redirect logged-out users to 404"                    |

## 2. Layout, auth and session

| Feature                                                                   | Status | Notes                                                                                                                                                  |
| ------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Logo → home                                                               | ✅     | sidebar logo                                                                                                                                           |
| Log in: email + password, both required, loading state                    | ✅     | `AccountCard`                                                                                                                                          |
| Log in server errors on fields ("Email not found", "Incorrect password")  | ✅     |                                                                                                                                                        |
| Sign up: email format, username `^\w+$`, password ≥ 8, all required       | ✅     |                                                                                                                                                        |
| Sign up server errors on fields (email/username taken)                    | ✅     |                                                                                                                                                        |
| Switch between log in and sign up                                         | ✅     |                                                                                                                                                        |
| Login persists across reloads                                             | ✅     | `localStorage['auth-user']` (old: vuex-persistedstate)                                                                                                 |
| Logged-in menu → **Settings**                                             | ✅     | `AccountCard`                                                                                                                                          |
| Logged-in menu → **Profile**                                              | ✅     | `AccountCard`                                                                                                                                          |
| Logged-in menu → Create post / Create moon                                | ✅     | sidebar "Create" menu (`CreateActionsSelect`)                                                                                                          |
| Log out (`DELETE /user/logout`)                                           | ⏸      | If the request fails (e.g. session already expired → 403), nothing happens and the user stays "logged in" locally. Old had the same bug. Fix with D7.   |
| Stale session (cookie expired but `localStorage` says logged in)          | ⏸      | UI shows logged in, every action 403s. Needs `GET /user/me` (`enceladus/PARITY.md` §2). D7                                                             |
| Full page reload after log in / sign up / log out / delete account        | ✅     | Kept `router.go(0)` (D6). Future: re-fetch on auth change instead                                                                                      |
| Sidebar "Currently viewing" label                                         | ✅     | includes `@username` and Settings                                                                                                                      |
| Action feedback                                                           | ✅     | `ErrorBanner` (minimal styling, mockups to follow) replaces every `alert()` (D3); inline spinners and field errors as before                           |

## 3. Feeds (old Home → new `/all`)

| Feature                                                                | Status | Notes                                                                                       |
| ---------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------- |
| Sort New / Top                                                         | ✅     | sidebar Feeds                                                                               |
| Top time period: Today / This Week / This Month / This Year / All Time | ✅     | `CustomSelect`, mapped to `time_period` seconds                                             |
| Pagination                                                             | ✅     | Infinite scroll (D2): `PostFeed` + `InfiniteScrollFooter` + `usePaginatedList`              |
| Loading state                                                          | ✅     | spinner; the empty message only shows after a response                                      |
| Empty state ("Hmmm... empty.")                                         | ✅     |                                                                                             |
| End of list ("You've reached the end.")                                | ✅     |                                                                                             |
| Load error                                                             | ✅     | banner + "Try again" at the end of the list                                                 |
| Deleting own post removes it from the list                             | ✅     |                                                                                             |
| `/all` with missing/invalid query                                      | ✅     | redirects to Top/Today (D10)                                                                |

## 4. Moon page (`/:moon`)

| Feature                                       | Status | Notes                                                                           |
| --------------------------------------------- | ------ | ------------------------------------------------------------------------------- |
| Load moon `GET /moon/:name`; 404 → Not Found | ✅     | URL is kept                                                                     |
| Moon load error                               | ✅     | banner                                                                          |
| Loading state                                 | ✅     |                                                                                 |
| Header `/name`                                | ✅     |                                                                                 |
| "Create post" button on the moon              | ✅     | opens `/create/post?moon=<name>`, which pre-fills and checks the moon (D9)      |
| Sort New / Top + time period                  | ✅     | Default is Top/Today (old default was New): a deliberate redesign choice, kept  |
| Pagination, empty, end                        | ✅     | shared `PostFeed`                                                               |
| Navigating from one moon page to another      | ✅     | moon reloads when the route param changes (was stuck on the first moon)         |
| Subscribe / unsubscribe                       | ⏸      | new feature, needs `enceladus/PARITY.md` §1                                     |

## 5. Post page (`/post/:post_id/:comment_id?`)

| Feature                                                                         | Status | Notes                                                              |
| ------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------ |
| Load post; 404 → Not Found; error; loading state                                | ✅     | URL is kept on 404                                                 |
| Title, moon link, author link, relative time                                    | ✅     | `PostCard` in `postPageMode`                                       |
| Full text body and full-width image                                             | ✅     | was clipped to the feed preview with a "Read more" to itself       |
| Vote on post                                                                    | ✅     |                                                                    |
| Delete own post → leave the page                                                | ✅     | goes to the post's moon (old: home; `/` is not built yet)          |
| Comment count heading (singular/plural)                                         | ✅     |                                                                    |
| Comment box (logged in) / "Log in to post a comment" (logged out)               | ✅     |                                                                    |
| Post comment: empty check, error, prepend, count + 1                            | ✅     | (old had no empty check)                                           |
| Comment sort New / Top                                                          | ✅     |                                                                    |
| Comment pagination                                                              | ✅     | infinite scroll (D8)                                               |
| Comments loading / empty / error                                                | ✅     |                                                                    |
| Nested replies auto-loaded to depth 3, "See more replies" → single-comment view | ✅     |                                                                    |
| Single-comment view + "See all comments on this post"; comment 404              | ✅     |                                                                    |
| Reply: composer, logged-out prompt, cancel, empty check, error, count + 1       | ✅     | (old had no error handling for replies)                            |
| Vote on comments; author link                                                   | ✅     |                                                                    |
| Replies beyond the first 10 of any comment                                      | ✅     | infinite scroll per thread (D8); the old frontend couldn't load them |
| Comment/reply length limit + counter                                            | ⏸      | needs `enceladus/PARITY.md` §5                                     |

## 6. Profile page (`/@:username`)

| Feature                                                                                                                                       | Status | Notes                                                                 |
| --------------------------------------------------------------------------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------- |
| Load user `GET /user/:username`; 404 → Not Found; error; loading                                                                              | ✅     | reloads when navigating between profiles                              |
| Header `@username`                                                                                                                            | ✅     |                                                                       |
| Tabs Overview / Posts / Comments (`GET /profile/overview\|posts\|comments`)                                                                   | ✅     | `?tab=posts\|comments` (Overview is the default)                      |
| Sort New / Top                                                                                                                                | ✅     | `?sort=top` (New is the default)                                      |
| Posts shown as `PostCard`; deleting own post removes it                                                                                       | ✅     |                                                                       |
| Comments shown as "Commented on *post title*" (link), author, time, clipped content + Read more, votes, "View thread" → single-comment view  | ✅     | `ProfileCommentCard`                                                  |
| Pagination, empty, end, error                                                                                                                 | ✅     | infinite scroll; overview entries are de-duplicated (see `enceladus/PARITY.md` §6) |
| Switching tab/sort mid-request                                                                                                                | ✅     | stale responses are dropped (old could mix results)                   |

## 7. Settings (`/settings`)

| Feature                                                                                                                                         | Status | Notes                                                                                                    |
| ----------------------------------------------------------------------------------------------------------------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------- |
| Reached from the account card; steps replace the page content with a back button (D4)                                                           | ✅     | `/settings/email`, `/settings/password`, `/settings/delete`; success notice on return                    |
| Logged-out guard                                                                                                                                | ✅     | `/unauthorized` (shared `requireLogin` guard)                                                            |
| Show current email                                                                                                                              | ✅     |                                                                                                          |
| Change email: new + confirm; required, format, must match, must differ; server errors on the field; update stored email                         | ✅     | `POST /user/email` `newemail`                                                                            |
| Change password: current + new; required, new ≥ 8, must differ; "Incorrect password" on the current field, other server errors on the new field | ✅     | `POST /user/password` `oldpassword`, `newpassword` (old put every server error on the old field)          |
| Delete account: explicit confirmation listing what is deleted; `DELETE /user`; clear auth; leave; error                                         | ✅     | goes to Top/Today and reloads                                                                            |

## 8. Create post (`/create/post`)

| Feature                                                                    | Status | Notes                                                                                                |
| -------------------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------- |
| Logged-out guard                                                           | ✅     |                                                                                                      |
| Text / Image toggle                                                        | ✅     |                                                                                                      |
| Title required, ≤ 100; body required, ≤ 5000; image required, type, ≤ 15 MB | ✅     | new adds limits and drag-and-drop                                                                    |
| Submit → redirect to new post; server field errors                         | ✅     |                                                                                                      |
| Moon picker suggestions                                                    | ✅     | `GET /moon/search/:name` list under the input; mouse, arrow keys, Enter, Escape (D5)                 |
| `?moon=` pre-fill                                                          | ✅     | used by the moon page button                                                                         |
| Unsupported file / image storage failure from the server                   | ✅     | plain-text 400/502/503 now shows on the image field (it used to show nothing)                        |
| Not logged in on submit                                                    | ✅     | detects the API's 403 (code checked 401)                                                             |

## 9. Create moon (`/create/moon`): ✅

Name rules (`^\w+$`), ≤ 20, live availability check, server errors, redirect to the new moon. Unchanged.

## 10. Votes and post cards

| Feature                                                                  | Status | Notes                                             |
| ------------------------------------------------------------------------ | ------ | ------------------------------------------------- |
| Up / down / toggle off, score update                                     | ✅     |                                                   |
| Logged-out vote → "You must be logged in to vote."                       | ✅     | banner                                            |
| Rapid double-click                                                       | ✅     | clicks are ignored while a vote is pending        |
| Post card: clip long text + "Read more", image posts, comment count link | ✅     |                                                   |
| Delete own post (author only)                                            | ✅     | no confirmation in old or new (parity kept)       |

## 11. Not Found / Home / Unauthorized

| Feature                                                  | Status | Notes                                                                                           |
| -------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------- |
| Not Found message + way back                             | ✅     | "Content does not exist…" + "Browse top posts" (the old "front page" link; `/` isn't built yet) |
| Not Found redirect keeps the URL                         | ✅     | `notFoundLocation()` in `router/index.ts`                                                        |
| Home `/`                                                 | ⏸      | Subscriber feed (D1). Still the placeholder with dev links                                       |
| Unauthorized page                                        | ✅     | dev links replaced with a hint and a link to top posts                                          |

---

## Old behaviour deliberately not copied

- `window.onscroll = …` assigned per page and never removed, so it leaked across pages. The redesign scrolls inside `.page-content`, and `useInfiniteScroll` observes a sentinel with an `IntersectionObserver` rooted there.
- `VoteButtons` mutated its parent's prop (`content.votes += 1`).
- Sign-up modal was titled "Log in".
- Comment votes passed `type="type"` and only worked because anything other than `"post"` meant comment.
- Reply requests had no error handling.
- Logged-out access to settings/create redirected to 404 (the redesign's `/unauthorized` is better).
- Change password showed every server error on the old-password field.
- Modals and the full-screen overlay (D3, D4).

## Backend gaps and observations

Moved to `enceladus/PARITY.md`, with contracts and acceptance checks, for a separate backend pass:
subscriptions + subscriber feed (§1), `GET /user/me` (§2), the protected-route halting bug (§3),
consistent error shapes (§4), comment length limit (§5), and hardening notes (§6, including the
profile overview pagination tie-breaker).

## Decisions

1. **`/`** will be a subscriber feed. That needs backend work (see `enceladus/PARITY.md` §1), so it stays **unimplemented** in the frontend for now.
2. **Feed pagination:** infinite scroll.
3. **`alert()`:** replace every call with a new banner error component (`ErrorBanner`), styled minimally. UI mockups will follow.
4. **Settings:** no modals. A settings page reached from the account card. Each further step (change email, change password, delete account) replaces the page content and has a back button at the top that returns to the main settings page.
5. **Moon picker:** add suggestions from `/moon/search`.
6. **Full reload after log in / log out:** keep `router.go(0)` for now. Future: engineer around it, e.g. pages re-fetching on auth change.
7. **Stale sessions:** unchanged for now. The backend will add `GET /user/me` (`enceladus/PARITY.md` §2). Once the backend changes land, fix stale-session and logout-failure handling.
8. **Comments:** infinite scroll for top-level comments and for replies beyond the first page.
9. **Moon page "Create post"** button that pre-fills the moon: yes.
10. **`/all` with a bad or missing query:** redirect to the defaults.
11. **Uncommitted WIP:** commit it first as its own commit. Leave the enceladus migration and root `CLAUDE.md` untouched.

## Deferred until the backend work in `enceladus/PARITY.md` lands

- `/` subscriber feed, subscribe/unsubscribe on moon pages, sidebar subscription list
- Validate the stored login with `GET /user/me`; clear local auth on 403; always clear local auth on log out
- Simplify error parsing once error shapes are consistent (e.g. the plain-text handling in `CreatePostPage`)
- Comment/reply character limit + counter

## How it was verified

Every commit type-checks (`vue-tsc --build`) and passes oxlint and eslint, and `vite build` succeeds.
Each flow was also driven in headless Chromium against the local backend: feeds and infinite
scroll (with page size forced to 2), the `/all` redirects, moon-to-moon navigation, the moon
pre-fill, Not Found keeping the URL, the error banner, post page body and comment/reply infinite
scroll, all profile tabs (counts match the API), the account card links, and the whole settings
flow (sign up → change email → change password → log in with the new credentials → delete).
Moon suggestions, plain-text upload errors and the vote double-click guard were tested with
mocked responses, so no posts or votes were written.
