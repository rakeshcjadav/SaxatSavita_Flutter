# Future AI features

Ideas for later development. Nothing here is shipped yet.

Today the app is offline-first, Gujarati-only for kiran text, and has no live LLM. The only production “AI” is pre-generated `meta.summary` / `meta.moral` shown as “AI generated”. Any live feature should stay grounded in the book and must not invent doctrine.

**Constraints to keep**

- Reading and search must keep working offline.
- There is no custom server today — Firebase (Auth, Firestore, Remote Config) only.
- Answers and quiz items must come from the kiran (text, summary, moral, dictionary, haribhakts).
- Prefer precompute + review over open chat whenever possible.

---

## 1. Ask this kiran

**Problem.** A reader wants a teaching clarified without leaving the page. A general chatbot can invent doctrine.

**Idea.** A button on the kiran (meta panel / reader). The user asks in Gujarati. The model answers only from that kiran’s text, summary, moral, dictionary terms, and haribhakt context, and cites the passage. If the kiran does not say it, it says so.

**Needs.** Gemini (or similar) behind a Firebase callable function. Tight Gujarati prompt. Network required for the ask; the kiran itself stays local.

**Difficulty.** Medium.

---

## 2. Search by meaning

**Problem.** Keyword search misses paraphrases (e.g. મોક્ષ vs આત્યંતિક કલ્યાણ).

**Idea.** Semantic / hybrid search over ~697 kirans. Precompute embeddings at build time from full text + summary + moral + glossary. Ship a small index in the app (or fetch via Remote Config) and mix with the existing regex search.

**Needs.** Offline-friendly index. Gujarati embedding quality check.

**Difficulty.** Medium–high.

---

## 3. Today’s kiran

**Problem.** 697 kirans with no clear next step; people repeat favorites or drop the streak.

**Idea.** Suggest the next unread, resume an unfinished session, or “on this day” from the calendar. Use reading history, plans, favorites, and featured Remote Config. Optional later: similar-to-what-you-liked via summary embeddings.

**Needs.** Mostly rules on data we already have. Live AI is optional.

**Difficulty.** Low–medium.

---

## 4. Haribhakt journey and question explorer

**Problem.** “Which kirans did this person host?” or “Show every question they asked” is still manual browsing.

**Idea.** Natural-language or structured query over `haribhakts.json` (roles, questions, kiran refs, dates, places). Timeline UI. Most of this is query + UI; NLU for aliases is optional.

**Needs.** The haribhakt / question index already exists.

**Difficulty.** Low–medium.

---

## 5. Smart note assistant

**Problem.** Long Quill notes are hard to rediscover across kirans.

**Idea.** On note save (opt-in): suggest related kirans from the user’s own history + summary similarity; auto-link haribhakt names; short Gujarati recap of *their* note.

**Needs.** Cloud function. User notes only — do not send other users’ notes.

**Difficulty.** Medium.

---

## 6. Higher-quality Gujarati TTS

**Problem.** Device `flutter_tts` quality varies; pre-recorded audio is only partial.

**Idea.** Batch-generate neural Gujarati audio (existing `scripts/gemini_tts_from_kiran_txt.py`). Bundle popular kirans or download-and-cache on demand.

**Needs.** Storage, licensing, pipeline — not a conversational feature.

**Difficulty.** Medium.

---

## 7. Kiran MCQ + rewards (v1 in progress)

**Problem.** Reading can stay passive. A short check after a kiran helps memory and gives a reason to finish the sitting.

**v1 shipped on `feature/kiran-mcq`:** finish-dialog + meta-panel CTA, `KiranQuizPage`, points + first-quiz badge on dashboard/profile, seed bank for part 1 kirans 1–3, Firestore fetch/cache, `enable_quiz` Remote Config, generate/upload scripts.

**Still to do:** generate and review the remaining ~697 kirans, deploy `firestore.rules` for `kiranQuizzes`, jump-to-passage, sticker/streak rewards.

**Idea.** After the user has read a kiran (or from the meta panel), show **2–3 multiple-choice questions** about *that* kiran. Correct answers grant a small reward (points, badge, sticker, or streak bonus). Questions are **not** generated on the device at read time.

### Why precompute and put them on Firebase

- Spiritual wording can be reviewed once, then reused.
- We can fix a bad question without an app-store release.
- The app stays offline-first: cache the quiz bank locally after first fetch (and optionally ship a seed JSON in assets).
- Live generation at quiz time would cost money, need network, and risk wrong answers.

### Generation pipeline (dev / admin, not in the app)

1. For each kiran, send text + `meta.summary` + `meta.moral` + haribhakt questions to Gemini (or similar).
2. Ask for 2–3 Gujarati MCQs: one fact (place / host / reader), one teaching, one optional “what was asked” if the kiran has recorded questions.
3. Each item: question, 4 options, `correctIndex`, short explanation tied to the passage, optional `sourceHint` (paragraph / heading).
4. Human review before publish (doctrine and Gujarati).
5. Upload to Firestore. Bump `version` when a kiran’s set changes.

Suggested bank document (content, **not** under `users/{uid}`):

```
kiranQuizzes/{part}_{kiranIndex}
{
  "part": 1,
  "kiranIndex": 42,
  "version": 1,
  "locale": "gu",
  "questions": [
    {
      "id": "p1-42-q1",
      "prompt": "…",
      "options": ["…", "…", "…", "…"],
      "correctIndex": 0,
      "explanation": "…",
      "sourceHint": ""
    }
  ]
}
```

Suggested per-user progress (syncs like history):

```
users/{uid}/quizResults/{part}_{kiranIndex}
{
  "score": 2,
  "total": 3,
  "completedAt": <timestamp>,
  "quizVersion": 1,
  "rewardIds": ["points_10", "badge_first_quiz"]
}
```

Remote Config gates the feature (`enable_quiz`) and tunes `quiz_points_per_correct` / `quiz_perfect_bonus`.

### Rewards (first version can stay small)

No points system exists today (streaks and reading plans are the closest). A first version:

| Reward | When |
|--------|------|
| Points on the profile / dashboard | Per correct answer (e.g. 5) + bonus for 3/3 |
| First-quiz / part-complete badge | One-time |
| Streak bonus day or reading-plan credit | Optional later |
| Unlock a quote sticker or template | Optional later |

Rules to decide before build:

- One scored attempt per kiran (retry for practice, no extra points).
- Unlock the quiz only after a minimum read (time or scroll), so it is not a skip-to-points game.
- Wrong answers show the explanation and a jump back into the kiran.

### App behaviour

- Fetch + cache quiz bank (Firestore snapshot or one JSON blob per part).
- If offline and uncached, hide the quiz CTA.
- Logged-out users can try locally; rewards persist after sign-in if we keep a local queue (same pattern as other sync).

**Difficulty.** Medium. Generation + review is the bulk of the work; the in-app quiz UI is straightforward once the bank exists.

---

## Suggested order

1. **Kiran MCQ + rewards** — precomputed, reviewable, Firebase-hosted, feels new without a live chatbot.
2. **Ask this kiran** — first live LLM, scoped to one kiran.
3. **Today’s kiran** — high value, little or no model.
4. **Search by meaning** — larger index / embedding work.
5. Haribhakt explorer, note assistant, TTS pipeline as capacity allows.

---

## Related code and data

| What | Where |
|------|--------|
| Kiran text, summary, moral | `assets/book/saxatsavita/part{N}/kiran_{index}.json` |
| Indexes / haribhakts / questions | `_kirans_.json`, `haribhakts/haribhakts.json` |
| Dictionary | `assets/book/saxatsavita/meanings/meanings.json` |
| Reader + meta panel | `lib/pages/kiranreadpage.dart`, `lib/widgets/kiran_meta_panel.dart` |
| Search | `lib/pages/kiransearchpage.dart` |
| History / streaks | `lib/services/reading_history_service.dart`, dashboard |
| Notes | `lib/pages/note_editor_page.dart` |
| Firebase user sync | `lib/services/firebase_sync_service_mobile.dart` |
| Remote Config | `lib/services/remote_config_service.dart` |
| Dev Gemini TTS | `scripts/gemini_tts_from_kiran_txt.py` |
| Haribhakt extraction | `scripts/inject_haribhakt_names.py` |
| Quiz seed / generate / upload | `assets/book/saxatsavita/quizzes/kiran_quizzes.json`, `scripts/generate_kiran_quizzes.py`, `scripts/upload_kiran_quizzes.py` |
