# Product Requirements Document (PRD)
Project: Post-Meeting Management System (Web + Mobile)
Date: 2026-05-11
Source: /home/tareq/Documents/GP2/frontend

## 1. Overview
A cross-platform system to create, review, sign, archive, and analyze post-meeting decisions and minutes. It supports multiple roles (Admin, Secretary, Department Head/Dean, Staff Member, Minute Taker) and a structured workflow that starts with meeting notes captured by a minute taker, proceeds through secretary review, and ends in digital signature approvals and archival, with graph-based relationship exploration.

## 2. Goals and Success Metrics
Goals:
- Standardize and speed up creation of official meeting summaries.
- Enable digital signatures and edit requests.
- Preserve and search finalized meetings in an archive.
- Capture meeting minutes with audio recording and Arabic speech-to-text.

Success Metrics:
- Percent of meetings finalized without manual editing.
- Average time from meeting creation to final signature.
- Number of meetings archived per month.
- Adoption rate of minute taker workflow (notes sent to secretary).
- Signature completion rate per meeting.

## 3. Target Users and Roles
Roles (from lib/constants/api_constants.dart):
- Admin (roleId = 1)
- Secretary (roleId = 2)
- Department Head/Dean (roleId = 3)
- Staff Member (roleId = 4)
- Minute Taker (roleId = 5)

Primary Personas:
- Admin: manages users and can access all routes.
- Secretary: manages meeting notes and edit requests; drafts meeting summaries.
- Minute Taker: records meeting minutes, transcripts, and sends notes.
- Department Head/Dean + Staff: sign meeting decisions.

## 4. Scope
In Scope (Current Functionality):
- Authentication: login, logout, password registration.
- Role-based route access control.
- Dashboard overview and meeting stats.
- Create/edit meeting summaries with recipients and signatories.
- Local draft saving (client-side).
- Review and sign meeting summaries; request edits.
- Archive list + search + filter + graph view for relationships.
- Decision graph visualization.
- Minute taker workflow with recording + Arabic STT + notes submission.
- Secretary inbox for notes and edit requests.
- User management (add/search/filter users).

Explicit Gaps / Placeholders in UI:
- Archive "Export All" button has no action.
- Archive per-row download icon has no action.
- Minute taker "Back" button has no action.
- Secretary selection in minute taker appears static.

## 5. User Journeys (End-to-End Flows)
5.1 Login and Session:
1) User enters email/password.
2) API returns JWT + roleId.
3) Token stored in secure storage and cached.
4) App routes user to / dashboard.
5) If any API call returns 401, token is cleared and user is redirected to /login.

5.2 Create Meeting Summary (Secretary/Admin):
1) Navigate to /create.
2) Fill in document metadata (title, reference, session, dates).
3) Add recipients and copy-to users.
4) Add signatories required for approval.
5) Optionally link this meeting to previous meetings (Applies/Change/Continue).
6) Preview document updates live.
7) Save draft locally or send for approval.
8) On send, meeting is posted as pending approval.

5.3 Review and Sign (All signatories):
1) Navigate to /review.
2) View pending meetings requiring signature.
3) Open detail view /review/:id with full document preview.
4) Sign digitally or request edit.
5) If signed, meeting progresses; if edit requested, secretary receives request.

5.4 Secretary Inbox (Secretary/Admin):
1) Navigate to /secretary.
2) Review meeting notes from minute takers.
3) Inspect metadata, attendees, transcript, and action items.
4) Review edit requests and open meeting in editor to update.
5) Make edits and resubmit as needed.

5.5 Archive and Decision Graph:
1) Navigate to /archive.
2) Search and filter archived meetings.
3) Open decision graph /graph?meeting=:id for relationships.
4) Explore linked meetings by relationship type.

5.6 Minute Taker Workflow:
1) Navigate to /minute.
2) Add attendees and agenda items.
3) Record audio and capture live transcript (Arabic STT).
4) Edit transcript entries and tag takes.
5) Preview handoff and send notes to secretary.
6) Optional: save to archive (client notification only).

## 6. Functional Requirements
6.1 Authentication and Authorization:
- Login via /auth/login.
- Register password via /auth/registerPass.
- Logout via /auth/logout.
- Store token + roleId in secure storage.
- Route guard restrictions:
  - /users admin-only
  - /minute admin or minute taker
  - /secretary admin or secretary

6.2 Dashboard:
- Display counts for drafts, pending signatures, total meetings, finalized.
- Show meetings requiring user signature.
- Show pending approvals and progress.
- "Create meeting summary" CTA.

6.3 Meeting Creation:
- Editable document metadata and decision text.
- Add recipients, copy-to users, and signatories.
- Link meetings with relationship type (Applies/Change/Continue).
- Document preview panel with live updates.
- Save local draft (SharedPreferences).
- Send meeting to API (create/edit).

6.4 Review and Sign:
- List pending meetings.
- Detailed document view with signatory progress.
- Sign digitally (/meetings/signature/verify).
- Request edit (/meetings/editMeeting).
- PDF download for a meeting.

6.5 Archive:
- List archived meetings.
- Search by title/keywords.
- Filter by meeting type.
- View decision graph.
- Export/download actions appear but currently no handler.

6.6 Decision Graph:
- Visualize relationships for selected meeting.
- Filter edges by type: Applies, Change, Continue.
- Pan/zoom and drag nodes.
- Open document preview on node double-click.

6.7 Minute Taker:
- Attendance and agenda management.
- Audio recording with pause/resume/stop.
- Arabic speech-to-text capture.
- Transcript editing and action/take annotations.
- Handoff preview.
- Send notes to secretary.
- Optional archive save (notification only).

6.8 Secretary Inbox:
- View meeting notes list with search.
- Document preview for selected note.
- Metadata panel (speaker activity, action items).
- Edit requests list with document preview and edit action.

6.9 User Management:
- List and filter users by role.
- Search by name/email.
- Add new users with role selection.

## 7. Data Entities
Meeting:
- id, title, meetingDate, status, content, councilType, sessionNumber, decisionNumber
- signatories, requiredSignatures, recipients
- relationships (Applies/Change/Continue)
- requestedEdit, signatureStatus

Meeting Notes:
- notes (JSON payload), attendeeIds, recorderId, date
- content: title, titleAr, meetingType, department, attendees, agenda, transcript

Users:
- id, fullName, email, roleId, department

## 8. Integrations and APIs
Base URL: http://localhost:5065/api (lib/constants/api_constants.dart)

Core Endpoints (from services):
- POST /auth/login
- POST /auth/registerPass
- POST /auth/logout
- GET /meetings
- GET /meetings/GetPendingSignMeetings
- GET /meetings/getMeeting?meetingId=
- POST /meetings/
- POST /meetings/signature/verify
- POST /meetings/editMeeting
- GET /meetings/users
- POST /meetings/search
- GET /meetings/Relationships?meetingID=
- GET /meetings/getMeetingNotes
- GET /meetings/getMeetingData
- POST /meetings/MeetingNotes

## 9. Non-Functional Requirements
- Cross-platform: iOS/Android/Web supported.
- Session handling: Redirect to login on 401.
- Performance: Cache meetings list and pending sign list for 2 minutes.
- Accessibility: Uses scalable text in minute taker view.
- Security: JWT stored in secure storage, role-based routing.
- Localization: Arabic and English content supported in UI.

## 10. UX and UI Principles
- Two-panel layouts on desktop; stacked layouts on mobile.
- Live document previews where applicable.
- High-contrast status banners (draft, pending, finalized).
- Smooth transition animations for routing.

## 11. Risks and Constraints
- Export/download actions in archive are UI-only.
- Meeting draft persistence is local only (not synced).
- Minute taker "Save to Archive" does not call backend.
- Some fields are hardcoded in minute taker (meeting title/date).

## 12. Open Questions
1) Should archive export/download be implemented as PDF or CSV?
2) Are minute taker meeting title/date supposed to be editable or fetched?
3) What is the expected approval flow for edit requests (e.g., resubmit and re-sign)?
4) Should secretary be able to create meetings directly from minute taker notes?
5) Is /auth/registerPass intended for self-service or admin-invited users only?

