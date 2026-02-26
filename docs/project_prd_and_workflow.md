# FixIt PRD and Project Workflow

## 1. Product Overview
FixIt is a collaborative web application for tracking and resolving API failures, inspired by Postman-style team workflows.

Users can:
- Register and sign in
- Create an organization
- Create projects inside an organization
- Log API error events per project
- Invite teammates by email to collaborate
- Claim, update, and resolve error logs together

---

## 2. Problem Statement
Teams often debug API failures in scattered tools (chat, logs, tickets). This causes:
- Slow triage
- Duplicate investigation work
- Missing context (request payload, headers, stack traces)
- Poor ownership tracking

FixIt centralizes API failure collaboration in one workspace.

---

## 3. Goals
- Provide a clear onboarding path: auth -> empty dashboard -> organization -> project -> error logs
- Make API failure logging fast and structured
- Support team collaboration with project-level membership
- Improve visibility of status and ownership of incidents

---

## 4. Non-Goals (Current Scope)
- Full API request testing client (collections, environments, runners)
- Production alerting integrations (Slack, PagerDuty) in v1
- Advanced RBAC beyond owner/admin/collaborator baseline

---

## 5. Target Users
- Backend engineers debugging failing endpoints
- Frontend engineers reporting API issues
- QA engineers validating API behavior
- Team leads managing project incidents

---

## 6. Core Features (MVP)

### 6.1 Authentication
- User registration, login, logout
- Session-based authenticated dashboard access

### 6.2 Workspace Structure
- Organizations as tenant/workspace boundary
- Projects scoped under organizations
- Default team auto-created on organization creation (to reduce setup friction)

### 6.3 Error Log Management
- Create error logs with:
  - HTTP method
  - Endpoint path
  - Status (open, in_progress, resolved)
  - Error code
  - Description
  - Payload
  - Error response
  - Headers
  - Stack trace
- Filter by organization/project/status
- Claim/unclaim logs
- Update status to in progress/resolved

### 6.4 Collaboration
- Invite project members by email (existing users)
- Role assignment (admin/collaborator)
- Project member list and invited-by tracking

---

## 7. User Stories
- As a new user, I can register and sign in so I can access a private dashboard.
- As a signed-in user, I can see an empty setup flow when no workspace data exists.
- As a workspace owner, I can create an organization and then projects for API domains.
- As a team member, I can log API failures with full request/response context.
- As a collaborator, I can claim an error log to indicate ownership.
- As a project admin, I can invite teammates to collaborate on logs.
- As a team, we can track progress from open -> in progress -> resolved.

---

## 8. Functional Requirements

### 8.1 Routing and Access
- Public home page for unauthenticated users
- Authenticated users redirected to `/dashboard`
- Organization/project/error-log routes in authenticated live session

### 8.2 Data Integrity
- Error logs must belong to valid organization + project scope
- Users can only access projects they own or are members of
- Invite action allowed for project admins

### 8.3 UX Requirements
- Dashboard displays setup flow and workspace counters
- Organization and project pages show empty states and collaboration-focused cards
- Error log UI uses clear status badges and action buttons

---

## 9. Success Metrics
- Time-to-first-log: median time from signup to first error log
- Setup completion rate: % users creating organization + project
- Collaboration rate: % projects with >1 member
- Resolution flow adoption: % logs moved to resolved

---

## 10. Risks and Dependencies
- Email invite currently requires invited user to already exist
- Team/role model may need simplification or expansion based on usage
- High log volume may require pagination/search tuning

---

## 11. Future Enhancements
- Invite tokens for pre-registration email invites
- API ingestion endpoint for automatic log capture
- Slack/Discord notifications for new/open critical logs
- Saved filters and per-project dashboards
- SLO/SLA reporting and trend analytics

---

## 12. Project Workflow

### 12.1 End-to-End User Workflow
1. User registers account
2. User signs in
3. User lands on `/dashboard` (empty setup flow shown if no data)
4. User creates organization
5. User creates project inside organization
6. User logs first API error
7. User invites team members by email
8. Team members collaborate: claim, update, resolve logs

### 12.2 Operational Workflow (Per Error Log)
1. Log created (status: `open`)
2. Engineer claims log (status moves to `in_progress`)
3. Engineer investigates using payload/headers/stack trace
4. Fix is deployed
5. Log marked `resolved`
6. Team can review history in project view

### 12.3 Team Collaboration Workflow
1. Project admin opens project details page
2. Admin invites teammate by email with role
3. Teammate joins project access scope
4. Teammate can view and act on project logs

---

## 13. Delivery Phases

### Phase 1 (Done / Current)
- Auth flow
- Dashboard route + empty-state setup
- Organization/project/error-log core CRUD
- Project member invite for existing users
- Error log status + claim workflow

### Phase 2
- Tokenized pre-registration invites
- Better team management UX
- Sorting, pagination, and search for logs

### Phase 3
- Automated ingestion + integrations
- Analytics and operational insights

