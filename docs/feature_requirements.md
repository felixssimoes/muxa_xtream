# muxa_xtream — Product Feature Requirements (PM)

A product-level specification for a Dart/Flutter library that enables the **Muxa** app (and other Flutter apps) to connect to IPTV providers that use **Xtream-style portals**, browse content, fetch program guides, and play streams — with a strong emphasis on reliability, security, and developer experience. This document intentionally avoids prescribing specific implementation details or internal APIs.

---

## 1) Vision
Provide a **trustworthy, lightweight, and cross-platform** streaming integration layer that “just works” with the most common Xtream-style IPTV portals so app developers can focus on UX, not plumbing.

---

## 2) Target Users & Personas
- **Primary:** Muxa app developers (Flutter). Need a dependable package to power onboarding, catalog browsing, and playback.
- **Secondary:** Other Flutter developers building IPTV clients or utilities.
- **Indirect:** End users of these apps benefit via faster, safer, more stable experiences.

---

## 3) Problem Statement
Connecting to Xtream-style portals is messy and inconsistent across providers. Developers struggle with:
- Unclear or shifting portal behaviors
- Large catalogs and heavy EPG feeds
- Fragile error handling and poor reliability
- Security/privacy gaps (credentials in logs, etc.)
- Cross-platform differences (mobile/desktop/web)

**muxa_xtream** should package these concerns into predictable, safe outcomes.

---

## 4) Goals (What we want to achieve)
1. **Easy Connection:** Accept typical portal inputs and credentials, validate access, and report clear account/server status.
2. **Complete Catalog Access:** Provide reliable access to live channels, VOD (movies), and series catalogs, including category information.
3. **Program Guide Support:** Offer both quick “now/next” guide data and the option to obtain extended guide data for richer experiences.
4. **Playback Ready:** Enable the app to obtain playable stream URLs for live, VOD, and series content.
5. **Resilience:** Behave predictably under slow networks, very large catalogs, and provider quirks.
6. **Security & Privacy:** Keep user credentials and personal data safe by design.
7. **Great DX:** Make it fast for developers to integrate, test, and troubleshoot.
8. **Portability:** Work consistently across Flutter targets (Android, iOS, macOS, Windows, Linux; web where feasible).
9. **Clarity:** Provide clear, human-readable errors and statuses that enable good in-app messaging.

---

## 5) Non-Goals (Out of Scope for this library)
- Building media players, custom playback controls, or transcoding pipelines.
- Caching, persistent storage, or sync layers (apps can add their own).
- DRM or content protection features beyond what providers natively expose.
- Opinionated UI components; this is a backend integration library.
- Integrations with non-Xtream IPTV standards (could be future add-ons).

---

## 6) Key Use Cases
- **Connect to a portal** with username/password and confirm subscription status and server availability.
- **List live channels** and filter by category.
- **List VOD movies** and filter by category; fetch details for a selected item.
- **List TV series** and navigate seasons/episodes; fetch details for a selected series.
- **Show “now/next” information** for a channel quickly.
- **Load extended guide data** when an app wants more depth (e.g., day view).
- **Start playback** of a selected item by obtaining a playable stream URL.
- **Handle failure cases** (bad credentials, expired account, blocked access, network failures) with actionable messages.

---

## 7) Functional Requirements (Outcome-oriented)

### 7.1 Onboarding & Connection
- Accept common portal inputs (base URL or similar) and user credentials.
- Validate that the portal is reachable and the account is usable.
- Provide a concise, human-readable connection status (e.g., active, expired, blocked, unreachable).
- Surface server/portal traits that are relevant to app behavior (e.g., whether certain data is available).
**Acceptance Criteria**
- Connection flow reports success or a clear reason for failure within a reasonable time.
- The app can display account expiry/active info when provided by the portal.
- No credentials are exposed via logs or error messages.

### 7.2 Catalog Browsing (Live, VOD, Series)
- Expose content lists for live channels, VOD, and series.
- Provide categories for each content type.
- Surface essential metadata (names, images/posters where available, grouping information).
- Allow the app to fetch details for a single VOD item or series (including seasons/episodes when available).
**Acceptance Criteria**
- For a typical provider, the app can render lists of live channels, movies, series, and categories.
- For a selected movie/series, the app can show basic detail information and list episodes/seasons where provided.
- Large catalogs do not lock the UI; the library remains responsive while loading.

### 7.3 Program Guide (EPG)
- Provide a fast “short guide” ideal for now/next displays.
- Provide a way to obtain extended guide data for deeper timelines.
**Acceptance Criteria**
- Apps can show now/next without requiring large downloads.
- Extended guide data is attainable for providers that offer it; when not available, the library communicates that clearly.

### 7.4 Playback Readiness
- Provide a playable URL for live channels, VOD, and series episodes based on provider data.
- Ensure the app can distinguish between common stream types when necessary.
**Acceptance Criteria**
- Starting playback from a selected catalog item is feasible with data returned by the library.
- If a stream is unavailable or misconfigured, the library returns a clear failure reason.

### 7.5 Reliability, Scale & Network Behavior
- Handle slow or flaky networks gracefully.
- Work with very large catalogs and extended guide data sets without exhausting memory.
- Avoid redundant downloads in common flows.
**Acceptance Criteria**
- Reasonable default responsiveness for typical European broadband and mobile conditions.
- The library remains usable when catalogs include tens of thousands of entries.
- The app can cancel lengthy operations (e.g., extended guide retrieval) without instability.

### 7.6 Security & Privacy
- Never emit logs or errors containing raw credentials.
- Avoid storing credentials or personal data unless explicitly provided by the host app.
- Support secure connections where possible; clearly signal when a connection may be insecure.
**Acceptance Criteria**
- Redaction of secrets is consistent in all observable outputs.
- No background analytics or telemetry; the package is silent by default.

### 7.7 Cross-Platform Compatibility
- Support Flutter targets on mobile and desktop; web support where feasible given typical IPTV constraints.
- Respect platform-specific constraints (e.g., background execution, network permissions).
**Acceptance Criteria**
- The same app code using this library behaves consistently on major Flutter targets (Android/iOS/desktop).

### 7.8 Diagnostics & Developer Experience
- Provide concise, categorized errors (e.g., authentication failed, account expired, access blocked, network unreachable, provider unsupported).
- Provide minimal, opt-in logging hooks that help developers troubleshoot without exposing sensitive data.
- Offer clear documentation, examples, and guidance for common flows and pitfalls.
**Acceptance Criteria**
- Developers can identify root causes of connection/playback issues without reading package source.
- Quick-start examples enable a working connection and list rendering within minutes.

---

## 8) Performance & Quality Targets
- **Connection feedback:** within ~3–6 seconds under typical conditions.
- **Catalog listing:** initial visible results within ~2–4 seconds; large lists can continue loading progressively.
- **Short guide:** now/next data available within ~1–2 seconds per channel request path under normal conditions.
- **Resource usage:** should not cause noticeable UI jank in a Flutter app on mid-range mobile hardware.
- **Stability:** no crashes attributable to the library in normal use; well-defined behavior for cancellations/timeouts.

> Targets are directional and should guide prioritization and testing; they are not strict SLAs across all providers and geographies.

---

## 9) Error Handling & Messaging
- Errors are **actionable** and mapped to categories the app can display (e.g., “Check your username/password”, “Your subscription appears expired”, “Provider blocked access”, “Network issue, please retry”).
- When provider data is missing or unsupported, the library communicates capability gaps clearly so the app can adapt (e.g., hide EPG).
- Timeouts, cancellations, and rate limits are distinguishable from generic failures.

---

## 10) Compatibility & Versioning
- Follow semantic versioning for public behaviors.
- Aim for backward-compatible additions; breaking behavioral changes require a major version.
- Communicate provider compatibility expectations (e.g., “Xtream-style portals and common forks”).

---

## 11) Documentation Deliverables
- **Overview Guide:** What the library does and when to use it.
- **Getting Started:** Minimal steps to connect and list content.
- **Concepts:** Accounts, catalogs, program guides, playback readiness.
- **Troubleshooting:** Common failure categories and likely fixes.
- **Security Notes:** Handling credentials safely in apps using the library.

---

## 12) Release Plan
- **MVP (0.1):** Connection, basic catalog listing (live/VOD/series), short guide, playback readiness, core error categories, minimal docs.
- **v1.0:** Categories for all content types, details for VOD/series, extended guide option, robust failure mapping, polished docs and examples.
- **1.x:** Resilience improvements, broader provider compatibility coverage, portability refinements, optional features (e.g., catch-up/timeshift) based on demand.

---

## 13) Success Metrics
- **Integration speed:** Time for a new developer to connect and list content using the docs (goal: ≤ 30 minutes).
- **Crash-free rate:** ≥ 99.9% attributable to the library in telemetry collected by host apps.
- **Support volume:** Fewer “can’t connect / can’t list / can’t play” issues after adoption in Muxa.
- **Performance perception:** Positive qualitative feedback from Muxa on responsiveness and reliability.
- **Adoption:** Number of external projects using the library (if open-sourced).

---

## 14) Risks & Mitigations
- **Provider variance:** Different portal forks behave differently. → Mitigate with graceful degradation and clear capability signaling.
- **Large data sizes:** Catalogs/EPG can be huge. → Mitigate with progressive loading expectations and cancelability.
- **Security expectations:** Apps may misconfigure logging. → Provide redaction by default and clear guidance.
- **Web constraints:** CORS/mixed-content may limit web usage. → Document expectations and recommend app-level proxies where necessary.

---

## 15) Open Questions
- Do we want optional usage analytics (opt-in) to understand real-world provider quirks? (Default would remain no telemetry.)
- Should we ship an example Flutter app as a separate repository to demonstrate end-to-end usage?
- What minimum compatibility matrix do we want to publicly claim at v1.0 (e.g., top N portal forks)?

---

*This PM document defines **what** outcomes muxa_xtream must deliver, not **how** to build them. Implementation details, internal APIs, and architectural choices are intentionally left unspecified here.*
