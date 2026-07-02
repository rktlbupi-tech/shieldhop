# Employee App API — Peer chat (employee → employee)

Lets an employee start a chat **from the app** with another team member in their
own organisation (1:1) or several (group), on top of the existing chat-v2 stack.
Same conversations / messages / realtime socket as every other chat surface -
this adds a **colleague picker** and enforces **same-organisation** membership.

---

## 1. Basics

**Base URL**

```
https://dev-api.presshop.news:5019/chat-v2
```

**Auth** — the employee's login token (chat-v2 accepts the ENTERPRISE_USER token):

```
Authorization: Bearer <token>
Content-Type: application/json
```

Response shape: `{ "success": true, "data": ... }` on success, `{ "success": false, "code", "message" }` on error. The org is taken from the token - you never send an org id.

---

## 2. Pick a colleague — `GET /chat-v2/app/colleagues`

Search / paginate the caller's **same-org** team members (excludes self). Use this
to choose the recipient(s) before starting a chat.

Query: `search` (optional), `page` (default 1), `limit` (default 20, max 100).

```jsonc
{
  "success": true,
  "data": {
    "data": [
      {
        "id": "6a1fd734e96730abbc8ddaec",
        "name": "Bajaj Four",
        "avatar_url": "https://.../avatar.jpg",   // null if none
        "designation": "Field Officer",            // null if unset
        "department": "Operations"                 // null if unset
      }
    ],
    "totalCount": 24,
    "page": 1,
    "limit": 20,
    "totalPages": 2
  }
}
```

Only `approved` employees in the caller's organisation are returned.

---

## 3. Start a chat — `POST /chat-v2/conversations`

Reuses the shared create endpoint. Members are `enterprise_user` (the picked
colleagues). The caller is added automatically as owner - **do not** include
yourself in `members`.

**1:1 (direct)** — exactly one other member:

```jsonc
{
  "channelType": "direct",
  "members": [
    { "memberType": "enterprise_user", "memberId": "<colleagueId>" }
  ]
}
```

**Group** — one or more members + a title:

```jsonc
{
  "channelType": "group",
  "title": "Night shift crew",
  "members": [
    { "memberType": "enterprise_user", "memberId": "<colleagueId1>" },
    { "memberType": "enterprise_user", "memberId": "<colleagueId2>" }
  ]
}
```

Returns `201 { success: true, data: <conversation> }`. A direct chat is
idempotent - creating the same 1:1 again returns the existing conversation.

**Same-org enforcement:** every member must be an `enterprise_user` in the
caller's organisation. Anything else (a member from another org, or a non-employee
member type) is rejected with `403 ORG_SCOPE_FORBIDDEN`.

---

## 4. List / read / send (existing chat-v2 endpoints)

Once a conversation exists, use the standard chat-v2 endpoints (unchanged):

| Action | Endpoint |
|--------|----------|
| List my conversations | `GET /chat-v2/conversations` |
| Get one | `GET /chat-v2/conversations/:id` |
| Messages (history) | `GET /chat-v2/conversations/:id/messages` |
| Send a message | `POST /chat-v2/conversations/:id/messages` |
| Mark read | `POST /chat-v2/conversations/:id/read` |
| Attach media | `POST /chat-v2/media/prepare` → `POST /chat-v2/media/:assetId/confirm` |

**Realtime:** the same socket events the app already uses -
`conversation.subscribe`, `message.new`, `message.updated`, `message.read`,
`conversation.sync`. No new socket protocol. Unread = `lastSeq - lastReadSeq`.

---

## 5. Errors

| Status | code | When |
|--------|------|------|
| 401 | `UNAUTHORIZED` | missing / invalid token |
| 403 | `FORBIDDEN` | colleague picker called by a non-employee (admin) account |
| 403 | `ORG_SCOPE_FORBIDDEN` | a member is outside the caller's org, or not an employee |
| 422 | `INVALID_DIRECT_CONVERSATION` | `direct` without exactly two members (self + one) |

---

## 6. Notes for the app

- Post-creation group member add/remove for employee-owned groups is **not**
  enabled yet (create the group with all members up front). Follow-up if needed.
- Field names are identical to the marketplace side; org is always resolved from
  the token.

---

> **Repo note:** all chat-v2 paths are relative to `AppConfig.apiBaseUrl`, so the
> `ApiClient` calls use `chat-v2/app/colleagues`, `chat-v2/conversations`,
> `chat-v2/conversations/:id/messages` (no leading slash). The colleague list is
> **double-nested**: `res.data['data']['data']` is the array.
