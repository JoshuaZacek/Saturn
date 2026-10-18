# Frontend parity: old `titan/` (main) → redesign (`frontend`)

Inventory of everything the old frontend does, and where the redesign stands.
Snapshot: 2026-10-18. "New" includes the uncommitted work currently in the tree
(comment threads on the post page, `CommentThread.vue`, `types/comment.ts`, `utils/relativeTime.ts`).

Legend: ✅ done · 🟡 partial · ❌ missing · ❓ needs a decision (see [Questions](#questions))

---

## 1. Routes

| Old route                | New route                                              | Status | Notes                                                                    |
| ------------------------ | ------------------------------------------------------ | ------ | ------------------------------------------------------------------------ |
| `/` (all-posts feed)     | `/all?sort=new`, `/all?sort=top&t=day` (sidebar Feeds) | ✅     | `/` itself is a placeholder page with dev links ❓Q1                      |
| `/:moon`                 | `/:moon?sort=…&t=…`                                    | 🟡     | see §4                                                                   |
| `/post/:id/:comment?`    | `/post/:post_id/:comment_id?`                          | 🟡     | see §5                                                                   |
| `/@:username`            | `/@:username`                                          | ❌     | placeholder page, see §6                                                 |
| `/settings`              | —                                                      | ❌     | see §7                                                                   |
| `/create/post`           | `/create/post`                                         | 🟡     | see §8                                                                   |
| `/create/moon`           | `/create/moon`                                         | ✅     | see §9                                                                   |
| `/404` + catch-all       | catch-all `not-found`                                  | 🟡     | placeholder content, see §11                                             |
| —                        | `/unauthorized` (new only)                             | ✅     | replaces old "redirect logged-out users to 404"                          |

## 2. Layout, auth and session

| Feature                                                                                                   | Status | Notes                                                                                                                                                                 |
| --------------------------------------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Logo → home                                                                                               | ✅     | sidebar logo                                                                                                                                                          |
| Log in: email + password, both required, loading state                                                   | ✅     | `AccountCard`                                                                                                                                                         |
| Log in server errors on fields ("Email not found", "Incorrect password")                                   | ✅     |                                                                                                                                                                       |
| Sign up: email format, username `^\w+$`, password ≥ 8, all required                                       | ✅     |                                                                                                                                                                       |
| Sign up server errors on fields (email/username taken)                                                    | ✅     |                                                                                                                                                                       |
| Switch between log in and sign up                                                                          | ✅     |                                                                                                                                                                       |
| Login persists across reloads                                                                              | ✅     | `localStorage['auth-user']` (old: vuex-persistedstate)                                                                                                                 |
| Logged-in menu → **Settings**                                                                              | ❌     | `AccountCard` logged-in state only has "Log out"                                                                                                                      |
| Logged-in menu → **Profile**                                                                               | ❌     |                                                                                                                                                                       |
| Logged-in menu → Create post / Create moon                                                                 | ✅     | sidebar "Create" menu (`CreateActionsSelect`)                                                                                                                         |
| Log out (`DELETE /user/logout`)                                                                            | 🟡     | If the request fails (e.g. session already expired → 403), nothing happens and the user stays "logged in" locally. Old had the same bug. Proposal: clear local auth regardless. |
| Stale session (cookie expired but `localStorage` says logged in)                                           | ❌     | Both old and new: UI shows logged in, every action 403s. Backend gap B1 ❓Q7                                                                                           |
| Full page reload after log in / sign up / log out (`router.go(0)`)                                         | ❓     | Hack in old, copied into new. Q6                                                                                                                                      |
| Sidebar "Currently viewing" label                                                                          | 🟡     | Label is empty on the profile page (and would be on settings)                                                                                                         |
| Action feedback                                                                                            | ❓     | Old: full-screen overlay (loading/success/error) on every action. New: inline spinners + `alert()` (17 call sites). Q3                                                 |

## 3. Feeds (old Home → new `/all`)

| Feature                                                                    | Status | Notes                                                                                     |
| -------------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------- |
| Sort New / Top                                                             | ✅     | sidebar Feeds                                                                             |
| Top time period: Today / This Week / This Month / This Year / All Time     | ✅     | `CustomSelect`, mapped to `time_period` seconds                                           |
| Pagination (`next_cursor`; old: infinite scroll)                           | ❌     | Only the first 10 posts are ever shown; `nextCursor` is stored but never used. ❓Q2       |
| Loading state                                                              | ❌     | "Hmmm... empty." is shown while the first page is loading                                 |
| Empty state ("Hmmm... empty")                                              | ✅     |                                                                                           |
| End of list ("That's all folks")                                           | ✅     | "You've reached the end." Only meaningful once pagination exists                         |
| Load error ("Posts couldn't be loaded")                                    | 🟡     | `alert()`                                                                                 |
| Deleting own post removes it from the list                                 | ✅     |                                                                                           |
| `/all` with missing/invalid query                                          | ❓     | New: goes to Not Found. Moon page instead redirects to defaults. Q10                       |

## 4. Moon page (`/:moon`)

| Feature                                                    | Status | Notes                                                                                                                  |
| ---------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------- |
| Load moon `GET /moon/:name`; 404 → Not Found              | ✅     |                                                                                                                        |
| Moon load error                                            | 🟡     | `alert()`                                                                                                              |
| Loading state                                              | ❌     | "Hmmm... empty." is shown while loading                                                                                |
| Header `/name`                                             | ✅     |                                                                                                                        |
| "Create post" button on the moon                           | 🟡     | Only the global sidebar menu. ❓Q9 (proposal: button that pre-fills the moon)                                           |
| Sort New / Top + time period                               | ✅     | Default is Top/Today (old default was New): a deliberate redesign choice, kept                                          |
| Pagination                                                 | ❌     | same as §3                                                                                                             |
| Empty / end states                                         | ✅     |                                                                                                                        |
| Navigating from one moon page to another                   | ❌     | **Bug:** the moon is fetched only in `onBeforeMount`, and `<RouterView>` reuses the component, so `/a` → `/b` (link or back/forward) keeps showing moon `a`'s posts. |

## 5. Post page (`/post/:post_id/:comment_id?`)

| Feature                                                                         | Status | Notes                                                                                                                    |
| ------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------ |
| Load post; 404 → Not Found; error; loading state                                | ✅     |                                                                                                                          |
| Title, moon link, author link, relative time, image                             | ✅     | `PostCard` in `postPageMode`                                                                                             |
| Full text body                                                                  | 🟡     | **Bug:** on the post page the body is still clipped to 7rem, with a "Read more" link that points back to the same page   |
| Vote on post                                                                    | ✅     |                                                                                                                          |
| Delete own post → leave the page                                                | ❌     | `PostCard` emits `deleted` but `PostPage` ignores it, so the deleted post stays on screen. Old: redirect home              |
| Comment count heading (singular/plural)                                         | ✅     |                                                                                                                          |
| Comment box (logged in) / "Log in to post a comment" (logged out)               | ✅     |                                                                                                                          |
| Post comment: empty check, error, prepend, count + 1                            | ✅     | (old had no empty check)                                                                                                 |
| Comment sort New / Top                                                          | ✅     |                                                                                                                          |
| Comment pagination                                                              | ✅     | "Load more comments" button (old: infinite scroll)                                                                        |
| Comments loading / empty / error                                                | ✅     |                                                                                                                          |
| Nested replies auto-loaded to depth 3, "See more replies" → single-comment view | ✅     |                                                                                                                          |
| Single-comment view + "See all comments on this post"; comment 404              | ✅     |                                                                                                                          |
| Reply: composer, logged-out prompt, cancel, empty check, error, count + 1       | ✅     | (old had no error handling for replies)                                                                                   |
| Vote on comments; author link                                                   | ✅     |                                                                                                                          |
| Replies beyond the first 10 of any comment                                      | ❌     | Old couldn't load them either. The API supports a cursor. ❓Q8                                                           |

## 6. Profile page (`/@:username`): all ❌

| Feature                                                                                                                                         | Status |
| ----------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| Load user `GET /user/:username`; 404 → Not Found; error; loading                                                                                | ❌     |
| Header `@username`                                                                                                                              | ❌     |
| Tabs Overview / Posts / Comments (`GET /profile/overview\|posts\|comments`)                                                                     | ❌     |
| Sort New / Top                                                                                                                                  | ❌     |
| Posts shown as `PostCard`; deleting own post removes it                                                                                         | ❌     |
| Comments shown as "Commented on *post title*" (link), author, time, clipped content + Read more, votes, "See replies" → single-comment view     | ❌     |
| Pagination (cursor), empty, end, error                                                                                                          | ❌     |
| Switching tab/sort mid-request (old race bug: results could mix): fix with a request-id guard like the other pages                              | ❌     |

## 7. Settings (`/settings`): all ❌ ❓Q4

| Feature                                                                                                                                                                   | Status |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| Logged-out guard (old: → 404; will use the new `/unauthorized` pattern)                                                                                                   | ❌     |
| Show current email                                                                                                                                                        | ❌     |
| Change email: new + confirm; required, format, must match; server errors ("Email cannot be the same", taken) on the field; update stored email. `POST /user/email` `newemail` | ❌     |
| Change password: old + new; required, new ≥ 8, must differ; server "Incorrect password" on the old field. `POST /user/password` `oldpassword`, `newpassword`              | ❌     |
| Delete account: explicit confirmation that lists what is deleted (posts, comments, moons, votes); hard to dismiss by accident; `DELETE /user`; clear auth; go home; error | ❌     |

## 8. Create post (`/create/post`)

| Feature                                                                         | Status | Notes                                                                                                                                                                          |
| ------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Logged-out guard                                                                | ✅     |                                                                                                                                                                                |
| Text / Image toggle                                                             | ✅     |                                                                                                                                                                                |
| Title required, ≤ 100; body required, ≤ 5000; image required, type, ≤ 15 MB      | ✅     | new adds limits and drag-and-drop                                                                                                                                              |
| Submit → redirect to new post; server field errors                              | ✅     |                                                                                                                                                                                |
| Moon picker                                                                     | 🟡     | Old: search-as-you-type dropdown (`GET /moon/search/:name`, 5 prefix matches, keyboard navigation). New: exact-name text input checked against `GET /moon/:name`, no suggestions. ❓Q5 |
| Unsupported file rejected by the server                                         | ❌     | **Bug:** backend returns a plain-text 400, the handler finds no `errors` object, so the spinner stops and **nothing is shown**                                                   |
| Not logged in on submit                                                         | 🟡     | Code checks for 401, backend sends 403, so it falls through to the generic alert                                                                                                |

## 9. Create moon (`/create/moon`): ✅

Name rules (`^\w+$`), ≤ 20, live availability check, server errors, redirect to the new moon. All done.

## 10. Votes and post cards

| Feature                                                                    | Status | Notes                                                                       |
| -------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------- |
| Up / down / toggle off, score update                                       | ✅     |                                                                             |
| Logged-out vote → "You must be logged in to vote."                         | ✅     |                                                                             |
| Rapid double-click                                                         | 🟡     | No in-flight guard, so the score can be double-counted (old had the same). Proposal: ignore clicks while a vote is pending |
| Post card: clip long text + "Read more", image posts, comment count link   | ✅     |                                                                             |
| Delete own post (author only)                                              | ✅     | no confirmation in old or new (parity kept)                                 |

## 11. Not Found / Home / Unauthorized

| Feature                                                                                         | Status | Notes                                                                                                         |
| ----------------------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------- |
| Not Found message: "Content does not exist… may have been modified, deleted…" + "Go to the front page" | 🟡     | Placeholder with dev links (`/news`, `/post/123`)                                                              |
| Not Found redirect keeps the URL                                                                | 🟡     | `router.replace({ name: 'not-found' })` rewrites the address bar to `/`. Proposal: keep the original path (standard vue-router pattern) |
| Home `/`                                                                                        | ❓     | Placeholder with dev links. Q1                                                                                 |
| Unauthorized page                                                                               | ✅     | Has leftover dev nav links; tidy up                                                                            |

---

## Old behaviour deliberately not copied

- `window.onscroll = …` assigned per page and never removed, so it leaked across pages. In the redesign the scroll container is `.page-content`, not the window, so this wouldn't fire anyway. Infinite scroll (if chosen) will use an `IntersectionObserver` sentinel.
- `VoteButtons` mutated its parent's prop (`content.votes += 1`).
- Sign-up modal was titled "Log in".
- Comment votes passed `type="type"` and only worked because anything other than `"post"` meant comment.
- Reply requests had no error handling.
- Logged-out access to settings/create redirected to 404 (the redesign's `/unauthorized` is better).

## Backend gaps and observations

Moved to `enceladus/PARITY.md`, with contracts and acceptance checks, for a separate backend pass:
subscriptions + subscriber feed (§1), `GET /user/me` (§2, B1), the protected-route halting bug
(§3, B2), consistent error shapes (§4, B3), comment length limit (§5, B4), and hardening notes (§6).

## Decisions

Answers from the review of the first draft. ❓ markers above refer to these.

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
- Simplify error parsing once error shapes are consistent
- Comment/reply character limit + counter

## Implementation order

1. Commit existing comments WIP
2. `ErrorBanner` component; replace `alert()`
3. Infinite-scroll composable; `/all` and moon page (loading, empty, end, error); moon-to-moon navigation; `/all` default redirect; moon "Create post" button
4. Post page: full body, delete → leave page, infinite scroll for comments and replies
5. Not Found / Unauthorized pages, keep URL on 404; account card Profile + Settings links; sidebar label
6. Profile page (+ profile comment card)
7. Settings page (email, password, delete account)
8. Create post: moon suggestions, error handling fixes, `?moon=` pre-fill; vote in-flight guard

Each commit type-checks (`vue-tsc --build`) and lints clean.
