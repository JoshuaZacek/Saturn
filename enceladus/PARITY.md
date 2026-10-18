# Backend changes needed by the frontend redesign

Companion to `titan/PARITY.md`. That file inventories the frontend; this one lists the backend
work the redesign needs (or that turned up while mapping the API). The frontend agent does not
modify `enceladus/`, so everything here is for a separate backend pass.

Each item has: **why**, **the contract the frontend will code against**, and **acceptance
checks**. Paths are relative to `enceladus/`. Keep the existing conventions: plug routers in
`lib/web/`, business logic in `lib/business/`, Ecto schemas in `lib/schemas/`, migrations in
`priv/repo/migrations/`, `Tarams` for query-param validation, `format_changeset/1` for errors.

Priority: 1 and 2 block frontend features; 3–4 are bugs; 5–6 are hardening.

## Status (2026-10-18)

Items 1–5 are implemented and item 6 is implemented except the cookie `secure` flag. All were
verified end to end over HTTP against a scratch database (160 checks, including every acceptance
check below). Migrations: `20261018172844_create_subscriptions_table`,
`20261018172845_add_comment_content_length_constraint`.

Where the implementation differs from or adds to the contracts below:

- §1 `GET /subscriptions` orders by name case-insensitively (`alpha`, `Beta`, `Zeta`).
  `subscribed` accepts `true`/`false`/`1`/`0`; anything else is `400 "Bad request"`. With
  `subscribed=true` plus `moon_id`, the `400` takes precedence over the logged-out `403`.
- §2 `GET /user/me` lives in `AuthRouter`; `Router` skips `/user/:username` for `me` with a route
  guard. The username `me` is reserved: sign-up returns
  `{"errors": {"username": ["Username is reserved"]}}`.
- §3 `AuthRouter` runs `AuthRequiredPlug` as a plug before dispatch. Side effect: an unknown path
  returns `403` (not `404`) when logged out.
- §5 The 5000 limit counts Unicode code points (what Postgres `char_length` counts), so a
  frontend counter should use `[...text].length`, not `text.length` (UTF-16 units).
- §6 Sessions expire server-side one year after creation (the cookie's `max_age`); a user's expired
  rows are deleted at their next login. `DELETE /vote` always answers `200 "Downvote removed"`.
  Not done: cookie `secure: true`, because it breaks login if production is ever served over plain
  HTTP. Set it once production is confirmed HTTPS.
- Also fixed: `GET /posts?sort=top` without `time_period` no longer returns 500, and
  `DELETE /user/logout` and `DELETE /user` now really clear the `session_id` cookie (the
  `delete_resp_cookie` result was being discarded).

Found while testing and fixed afterwards (outside this list):

- **Security** (`dd6d7fa`): the `Comment`, `Post` and `Vote` changesets cast `:user_id` from
  request params, so a logged-in user could post, comment and vote as anyone. They no longer cast it.
- Cursors (`69ccf5b`): the posts, comments and profile cursors skipped rows whose id was higher
  than the cursor's but which sorted after it (in "top", a newer post with fewer votes). They now
  compare `(sort key, id)` as a row.
- Malformed input (`30da22d`): non-integer or out-of-range ids, tampered cursors and missing
  `post_id`/`user_id` raised and returned 500. They now return `404` (`GET /post/:id`,
  `/comments/:id`), `400 "Bad request"` (other ids in paths and query params), or
  `{"errors": {"<field>": ["<Field> does not exist"]}}` (ids in request bodies). A bad cursor
  returns the first page, and a `time_period` reaching back before 1970 means all time.

> Note: `priv/repo/migrations/20260907025428_add_moon_name_length_constraint.exs` is currently
> untracked in the working tree. It belongs to the moon-name-length change already on the
> `frontend` branch (`lib/schemas/moon.ex` references the `name_length` constraint). Make sure it
> gets committed alongside the backend work.

---

## 1. Moon subscriptions and the subscriber home feed

**Why.** `/` in the frontend is meant to be a personal feed of posts from moons the user
subscribes to. There's no subscription concept in the backend today. The frontend leaves `/`
unimplemented until this lands.

### Data model

- New table `subscriptions`: `id`, `user_id` → `users` (`on_delete: :delete_all`),
  `moon_id` → `moons` (`on_delete: :delete_all`), `timestamps(type: :utc_datetime)`.
- Unique index on `[:user_id, :moon_id]`.
- New schema `Saturn.Subscription` (`lib/schemas/subscription.ex`) with `belongs_to :user`,
  `belongs_to :moon`, a changeset with `unique_constraint([:user_id, :moon_id])` and FK constraints.
- `Saturn.User`: `has_many(:subscriptions, Subscription, on_delete: :delete_all)`, so
  `DELETE /user` keeps cleaning up everything the user owns.
- `Saturn.Moon`: `has_many(:subscriptions, Subscription, on_delete: :delete_all)`.
- Business module `Saturn.Subscriptions` (`lib/business/subscriptions.ex`).

### Endpoints

All authenticated endpoints go in `AuthRouter` and return `403 "Unauthorized"` without a session
(same as today; see item 3 for the halting bug).

| Method + path | Auth | Request | Success | Errors |
| --- | --- | --- | --- | --- |
| `POST /subscription` | yes | JSON/form `moon_id` (integer) | `200 {"moon_id": 1, "subscribed": true}`. Idempotent: subscribing twice is still 200 | `400 {"errors": {"moon_id": ["Moon_id does not exist"]}}` for an unknown moon; `400 "Bad request"` for missing/invalid `moon_id` |
| `DELETE /subscription?moon_id=1` | yes | query `moon_id` | `200 {"moon_id": 1, "subscribed": false}`. Idempotent: unsubscribing when not subscribed is still 200 | `400 "Bad request"` for missing/invalid `moon_id` |
| `GET /subscriptions` | yes | — | `200 {"moons": [{"id": 1, "name": "news"}, …]}` ordered by `name` ascending | — |

### Changes to existing endpoints

- **`GET /moon/:name`** gains two fields:
  - `subscribed`: boolean, `true` if the session user is subscribed, `false` when logged out
  - `subscribers`: integer count of subscriptions
  Existing fields (`id`, `name`, `inserted_at`, `updated_at`) are unchanged.
- **`GET /posts`** gains an optional boolean query param `subscribed` (Tarams `type: :boolean`).
  - With `subscribed=true`, return only posts whose `moon_id` is in the session user's
    subscriptions. Every other param (`sort`, `limit`, `cursor`, `time_period`) and the response
    shape `{"posts": [...], "next_cursor": ...}` stay exactly the same.
  - With `subscribed=true` and **no session**: `403 "Unauthorized"`.
  - `subscribed=true` together with `moon_id` → `400 "Bad request"` (mutually exclusive).
  - A user with zero subscriptions gets `{"posts": [], "next_cursor": null}`.
  - Implementation hint: in `Posts.get/2`, add a dynamic
    `where: p.moon_id in subquery(from s in Subscription, where: s.user_id == ^user_id, select: s.moon_id)`.
    The cursor/order logic is reused untouched.

### Acceptance checks

- Subscribe → `GET /moon/:name` shows `subscribed: true`, `subscribers` + 1; unsubscribe reverses it.
- `GET /posts?subscribed=true&sort=new&limit=10` returns only subscribed moons' posts and paginates
  with `next_cursor` the same way as the global feed (also for `sort=top&time_period=…`).
- Deleting a user or a moon removes its subscription rows.
- Logged out: `POST`/`DELETE /subscription`, `GET /subscriptions` and `GET /posts?subscribed=true`
  all return 403, and `GET /moon/:name` returns `subscribed: false`.

---

## 2. `GET /user/me`: current session user

**Why.** The frontend persists the logged-in user in `localStorage`. When the session cookie
expires or the session row is deleted (logout on another device, account deleted elsewhere), the
UI still shows the user as logged in and every action fails with 403. There's no way to check the
session. The frontend will call this on app start and drop its local login when it gets a 403.

**Contract**

- `GET /user/me` (protected)
  - With a valid session: `200` with the **same shape as the login/sign-up response**:
    `{"id": 1, "username": "joshua", "email": "me@example.com", "inserted_at": "…"}`.
    Never include the password hash.
  - Without one: `403 "Unauthorized"`.
- Route placement: `Router` already matches `get "/user/:username"` **before** forwarding to
  `AuthRouter`, so `/user/me` would currently be treated as the username "me". Define
  `get "/user/me"` **above** `get "/user/:username"` in `lib/web/router.ex` (and protect it there),
  or otherwise make sure it can't be shadowed. Note that `me` is a valid username today
  (`^\w+$`), so the profile of a user called "me" would become unreachable. Either reserve the
  name in `User.changeset/2` or accept and document it.

**Acceptance checks**

- Log in → `GET /user/me` returns the user; log out → `GET /user/me` returns 403.
- After `POST /user/email`, `GET /user/me` returns the new email.

---

## 3. Bug: protected routes keep executing after the 403

**Where.** `lib/web/auth_router.ex`: `defp protected(conn), do: Saturn.AuthRequiredPlug.call(conn, [])`.

**What happens.** For an unauthenticated request, `AuthRequiredPlug` sends `403` and calls
`halt/1`. But `protected/1` is called *inside* the route body, so halting doesn't stop it. The
body carries on with `conn.assigns.user == nil` and raises (e.g. `nil.id` in
`Comments.create/2`), or tries to send a second response. The client still sees the 403, but every
unauthenticated write logs an exception.

**Repro.** `curl -i -X POST localhost:<port>/comment -d 'post_id=1&content=hi'` (no cookie). It
returns 403, and the server logs an error.

**Fix (suggested).** Check `conn.halted` before running the body, for example a small macro or
`with %Plug.Conn{halted: false} = conn <- protected(conn) do … end` in each protected route.
Alternatively, move protected routes into their own router that runs `AuthRequiredPlug` as a real
plug.

**Acceptance check.** The repro above returns 403 and logs no exception, for every protected route.

---

## 4. Consistent JSON error responses

**Why.** The frontend has to special-case several error shapes. Today:

| Endpoint | Current 400 body | Problem |
| --- | --- | --- |
| `POST /comment` | `{"content": ["Content can't be blank"]}` | not wrapped in `errors` (`Comments.create/2` returns `{:error, format_changeset(...)}` instead of `{:error, %{errors: ...}}`) |
| `POST /post` (unsupported file) | `File type not supported` (plain text) | not JSON; the frontend currently shows nothing for it |
| `POST /post` (S3 not configured / upload failed) | plain text, 503 / 502 | not JSON |
| Tarams validation failures (many routes) | `Bad request` (plain text) | acceptable, but see below |

**Contract**

- Every **validation** failure returns `400` with `Content-Type: application/json` and body
  `{"errors": {"<field>": ["<Human readable message>", ...]}}`.
  - `POST /comment` → `{"errors": {"content": [...]}}`
  - `POST /post` unsupported file → `{"errors": {"file": ["File type not supported"]}}`
  - `POST /post` upload failure → `502 {"errors": {"file": ["Image upload failed"]}}`;
    storage not configured → `503 {"errors": {"file": ["Image storage is not configured"]}}`
- Successful JSON responses should also set `Content-Type: application/json` (most currently
  don't; axios happens to parse them anyway).
- Malformed requests (`Tarams` failures, missing params) may stay plain-text `400 "Bad request"`.

**Acceptance check.** Each row above returns the new shape. Login/sign-up/email/password/moon/post
validation errors are already `{"errors": …}` and must not change.

---

## 5. Maximum length for comments

**Why.** Posts have title ≤ 100 and body ≤ 5000, and moons ≤ 20, but comment `content` is
unbounded.

**Contract.** `content` ≤ **5000** characters (to match post bodies; adjust if you prefer, and
tell the frontend). Enforce it in `Saturn.Comment.changeset/2` (`validate_length`) and with a DB
check constraint (same pattern as `add_moon_name_length_constraint`). The error comes back as
`{"errors": {"content": ["Content should be at most 5000 character(s)"]}}` (after item 4). The
frontend will add a character counter to the comment/reply boxes once this exists.

---

## 6. Hardening and observations (lower priority)

- **Sessions never expire server-side.** The cookie has `max_age: 31_536_000` (1 year), but
  `sessions` rows live forever. Consider an `expires_at` or a max age check in
  `Session.get_by_id/1`, plus cleanup. Item 2 makes expiry visible to the frontend.
- **Cookie flags.** `put_resp_cookie` relies on Plug defaults (`http_only: true`); consider setting
  `secure: true` in production explicitly.
- **`GET /profile/overview` pagination has no tie-breaker.** `Profiles.overview/2` numbers rows
  with `row_number() OVER (ORDER BY votes DESC)` (or `inserted_at DESC`) only, so rows with equal
  votes can come back in a different order on the next request, and an entry can repeat or be
  skipped across pages. Add a deterministic tie-breaker (e.g. `contentType`, then `id`) to the
  window ordering. The frontend de-duplicates entries for now.
- **`DELETE /vote` returns `400` when there was no vote to delete.** The frontend never does this
  on purpose, but a double click can cause it. Returning `200` (idempotent) would be friendlier.
- **Out of scope for parity** (neither frontend has it): deleting comments, editing posts/comments.

---

## Frontend follow-ups once this lands (tracked in `titan/PARITY.md`)

1. Implement `/` as the subscriber feed (`GET /posts?subscribed=true`), add Subscribe/Unsubscribe
   on the moon page, and optionally list subscriptions in the sidebar (`GET /subscriptions`).
2. Validate the stored login on startup with `GET /user/me`; clear local auth on 403 (stale session).
3. Simplify error handling once item 4 makes the shapes consistent.
4. Character counter + limit for comments and replies (item 5).
