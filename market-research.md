# Market Research: iOS Meeting-Context Planner App

## 1. Competitive Landscape

Your app sits at the intersection of three categories. No single competitor covers all three well:

### Category A: AI Meeting Assistants (cloud-based transcription + recall)

| App | Price | Key Differentiator | Gap for You |
|---|---|---|---|
| [Otter.ai](https://otter.ai) | Free / $17/mo Pro | Real-time transcription, live collaboration | Cloud-dependent, requires bot in calls, no planner |
| [Fireflies.ai](https://www.outdoo.ai/blog/otter-vs-fireflies) | Free / $10-19/mo | 40+ integrations, CRM sync | Enterprise-focused, no personal context |
| [Fathom](https://www.meetjamie.ai/blog/ai-note-taker) | Free / $19/mo | Fast highlights, zero setup | Video calls only, no calendar planner |
| [Jamie](https://www.meetjamie.ai) | Free / ~$24/mo | No bot (device audio), cross-meeting recall | Desktop-first, no on-device AI, no planner |
| [Granola](https://www.lindy.ai/blog/ai-note-taking-app) | Free / $14/mo | macOS/iOS native, secure | Meeting notes only, not a planner |
| [Fellow](https://fellow.ai/blog/ai-meeting-assistants-ultimate-guide/) | $7-9/mo | Compliance, admin controls | Team-focused, not personal context recall |

### Category B: AI Planners & Calendar Apps

| App | Price | Key Differentiator | Gap for You |
|---|---|---|---|
| [Reclaim.ai](https://reclaim.ai) | Free / paid tiers | AI time-blocking, auto-scheduling | No meeting recall or notes |
| [Motion](https://www.usemotion.com) | ~$19/mo | AI daily schedule builder | Task-focused, no meeting context |
| [Morgen](https://www.morgen.so) | $15-30/mo | Multi-calendar consolidation | No RAG, no meeting memory |
| [Fantastical](https://flexibits.com/pricing) | $5-7/mo | Natural language input, beautiful UI | Calendar only, no AI intelligence layer |
| [Structured](https://structured.app) | Free / ~$1.50-30 lifetime | Visual timeline planner | No calendar sync in free tier, no AI |
| [Calendars by Readdle](https://readdle.com/blog/calendars-lifetime-purchase-option) | $20/yr or $60 lifetime | Gesture-based, offline | No AI features |
| [Sunsama](https://reclaim.ai/blog/best-planner-apps) | $20/mo | Calm daily planning ritual | No meeting recall |

### Category C: Personal CRM / Relationship Trackers

| App | Price | Key Differentiator | Gap for You |
|---|---|---|---|
| [Dex](https://apps.apple.com/us/app/dex-rolodex-and-personal-crm/id1472132715) | $12-20/mo | LinkedIn sync, keep-in-touch reminders | No meeting context, no planner |
| [Clay](https://www.bigcontacts.com/blog/best-personal-crm/) | Free / $10-20/mo | AI enrichment, web data | Desktop-first, not a planner |
| [Mem](https://get.mem.ai/blog/top-10-ai-meeting-assistants-in-2025-which-tool-is-best-for-your-meetings) | Subscription | AI-powered knowledge recall | Note-taking focused, no calendar integration |

---

## 2. Pricing Tiers in This Space

Based on the competitive landscape:

| Tier | Price Range | What's Included |
|---|---|---|
| **Free** | $0 | Basic calendar view, limited notes, no AI |
| **Personal/Pro** | $5-15/mo | Full planner + meeting recall + RAG search |
| **Premium** | $15-25/mo | AI summarization + Siri + Spotlight + unlimited history |
| **Lifetime** | $30-60 one-time | All features, popular with indie iOS apps |

**Recommendation**: A freemium model with a **$7-10/mo** (or ~$50-70/yr) Pro tier would be competitive. The on-device/privacy angle justifies a lifetime purchase option ($50-80) since you have zero server costs.

---

## 3. Market Size & Opportunity

- The global **productivity apps market** is valued at [~$12 billion in 2025](https://www.businessresearchinsights.com/market-reports/productivity-apps-market-117791), growing at **9.2% CAGR**
- [AI apps generated $4.5B in 2024](https://www.businessofapps.com/data/productivity-app-market/), expected to **triple in 2025**
- [North America holds 38% market share](https://www.mordorintelligence.com/industry-reports/productivity-apps-market)
- [AI integration influences 32% of new app functionalities](https://www.fortunebusinessinsights.com/productivity-apps-market-110254)
- Apple's Foundation Models framework provides [free on-device AI inference](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/) — meaning your AI features have **zero marginal cost**

---

## 4. The Gap Your App Fills

The biggest opportunity is that **no app combines all three categories** — planner + meeting recall + relationship context — while being **fully on-device and privacy-first**.

| Gap | Why It Matters |
|---|---|
| **On-device AI (no cloud)** | Every competitor uses cloud transcription. Apple Intelligence + NLEmbedding = zero data exposure. This is a unique selling point, especially post-GDPR/privacy backlash. |
| **Meeting *context*, not transcription** | Users don't need another transcript. They need "why did I meet with Sarah?" and "what did we decide last time?" — that's RAG, not recording. |
| **Planner + recall in one app** | Currently requires 2-3 apps (calendar + meeting notes + CRM). Your app consolidates this. |
| **No meeting bot required** | Otter/Fireflies/Fathom all join calls with a bot. Your app works from calendar data + user notes — no awkward bot in meetings. |
| **Relationship tracking built-in** | Personal CRMs (Dex, Clay) don't connect to meeting history. Your Person model with meeting frequency fills this. |
| **Apple-native experience** | Most competitors are cross-platform Electron/web apps. A native SwiftUI app with Siri, Spotlight, and Dynamic Type stands out on iOS. |
| **Free AI inference** | Competitors pay for OpenAI/cloud APIs and pass costs to users. Your on-device Foundation Models cost nothing per request. |

---

## 5. Positioning Summary

**One-liner**: "The meeting planner that remembers everything so you don't have to — privately, on your device."

**Target user**: Professionals with 5+ meetings/day who forget context between meetings and currently juggle a calendar app + notes app + maybe a CRM.

**Competitive moat**: On-device RAG + Apple Intelligence = privacy + zero API costs + offline capability. No competitor offers this combination.

---

## Sources

- [Business of Apps - Productivity App Market](https://www.businessofapps.com/data/productivity-app-market/)
- [Business Research Insights - Market Size](https://www.businessresearchinsights.com/market-reports/productivity-apps-market-117791)
- [Mordor Intelligence - Market Forecast](https://www.mordorintelligence.com/industry-reports/productivity-apps-market)
- [Fortune Business Insights - Growth Drivers](https://www.fortunebusinessinsights.com/productivity-apps-market-110254)
- [Apple Foundation Models Framework](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/)
- [Apple Privacy-First AI Strategy](https://apple.gadgethacks.com/news/apples-privacy-first-ai-strategy-reshapes-tech-future/)
- [Fellow - AI Meeting Assistants Guide](https://fellow.ai/blog/ai-meeting-assistants-ultimate-guide/)
- [Jamie - AI Notetakers](https://www.meetjamie.ai/blog/ai-notetakers-for-iphone)
- [Morgen - Calendar Tools](https://www.morgen.so/blog-posts/best-calendar-management-tools)
- [Reclaim - Planner Apps](https://reclaim.ai/blog/best-planner-apps)
- [Flexibits - Fantastical Pricing](https://flexibits.com/pricing)
- [Structured App](https://structured.app)
- [Readdle - Calendars Lifetime](https://readdle.com/blog/calendars-lifetime-purchase-option)
