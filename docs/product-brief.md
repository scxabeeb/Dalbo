# Professional Services Marketplace — Web and Mobile App Brief

> Implementation stack selected by the owner: ASP.NET Core Razor Pages + ASP.NET API, Flutter, and MySQL with EF Core. This overrides the original technology suggestions in section 9. See implementation-status.md for delivered scope.

## 1. Project overview

Build a responsive website and mobile application that connect customers with local service professionals, including electricians, plumbers, and air-conditioning and refrigeration technicians. Professionals can register, publish profiles, share their contact details, manage availability, chat with customers, and accept appointment requests. Customers can discover professionals, compare their services, contact them, and book appointments.

**Working name:** LocalPro (temporary; final branding to be selected).

**Initial scope assumption:** Start in one city or region, with service categories and locations managed by an administrator. Support expansion to additional cities, languages, and service categories later.

In this document, “available professionals” means workers offering services. Customer job postings and bidding are optional future features.

## 2. Goals

- Help customers find suitable professionals near their location.
- Give professionals a simple way to advertise services and receive inquiries.
- Make contact, conversation, and appointment booking easy.
- Build trust through clear profiles, verification status, and reviews from completed appointments.
- Give administrators tools to manage users, listings, and reports.

## 3. User roles

| Role | Main capabilities |
| --- | --- |
| Guest | Browse categories, search professionals, and view public profiles and professional contact details. |
| Customer | Manage a profile, save professionals, chat, request appointments, and review completed services. |
| Professional | Create a service profile, manage contact visibility and availability, chat, and accept or decline appointments. |
| Administrator | Manage categories, locations, users, professional approvals, reviews, reports, and platform settings. |

One account may have both customer and professional capabilities. Professional features require a completed professional profile and approval where enabled.

## 4. Initial service categories

- Electrical installation and repairs.
- Plumbing installation and repairs.
- Air-conditioning installation, servicing, and repair.
- Refrigerator, freezer, and cooling equipment repair.

Administrators can add categories such as carpentry, painting, appliance repairs, cleaning, and general maintenance without changing application code.

## 5. Core user journeys

### Customer journey

1. Open the website or mobile app.
2. Choose a service category and enter a city, neighborhood, or location.
3. Browse matching professionals and filter by availability, rating, and service area.
4. Open a profile to view services, experience, photos, pricing information, contact details, and reviews.
5. Call the professional, start an in-app conversation, or request an appointment.
6. Receive confirmation, a decline, or a proposed alternative time.
7. Receive reminders and follow the appointment status.
8. After the service is completed, submit a rating and review.

### Professional journey

1. Register and verify a contact method.
2. Choose service categories and complete a professional profile.
3. Add a service area, contact details, service descriptions, optional prices, and work photos.
4. Set working hours, appointment duration, and time off.
5. Submit the profile for approval if required.
6. Receive messages and appointment requests.
7. Accept, decline, or propose a new appointment time.
8. Complete the service and maintain the profile and calendar.

## 6. Functional requirements

### 6.1 Accounts and authentication

- Allow registration and login using a phone number with a one-time code. Email login may also be supported.
- Verify ownership of the selected contact method.
- Allow account recovery, logout, profile updates, and account deletion requests.
- Ask users to accept the terms and privacy policy during registration.
- Require authentication for chat, bookings, favorites, and reviews.
- Protect administrator accounts with multi-factor authentication.

### 6.2 Professional registration and profile

A professional profile should include:

- Full name or business name.
- Profile photo or business logo.
- Service categories and specific services offered.
- Biography, experience, and optional qualifications.
- City, neighborhoods served, and optional travel radius.
- Public business phone number and optional WhatsApp contact.
- Preferred contact methods and contact visibility settings.
- Working hours and booking availability.
- Pricing type: fixed price, starting price, hourly rate, or quote required.
- Work portfolio photos with descriptions.
- Languages spoken.
- Rating, review count, and completed appointment count.
- Approval and verification status, with a clear explanation of what was verified.

Private identity documents must never appear on public profiles. If identity verification is introduced, collect only the documents needed and restrict access to authorized staff.

### 6.3 Search and discovery

- Search by category, service name, professional name, city, or neighborhood.
- Let users enter a location manually; device location access is optional.
- Filter by service area, available date, rating, and pricing type.
- Display results as cards containing a photo, name, category, area, rating, and availability summary.
- Include clear actions to view a profile, call, chat, or request an appointment.
- Provide useful empty states when no matching professionals are found.
- Add a map view later if location accuracy and map costs justify it.

Distinguish between “accepting requests,” “has an available appointment,” and “online now.” These indicators must not imply guaranteed immediate service.

### 6.4 Contact details

- Display business contact details that the professional has explicitly chosen to publish.
- Support tap-to-call on compatible devices.
- Support an optional WhatsApp link when the professional provides a WhatsApp number.
- Keep customer phone numbers and exact service addresses private unless shared for an appointment.
- Allow professionals to update or hide public contact details.

### 6.5 In-app chat

- Enable private one-to-one conversations between customers and professionals.
- Support text messages and images of the work or issue.
- Show message timestamps, unread counts, delivery status, and read status.
- Link an appointment to its conversation when applicable.
- Notify recipients of new messages according to their preferences.
- Allow users to block and report accounts or messages.
- Restrict conversation access to its participants; administrative access must be limited, justified, and audited.
- Validate image type and size and protect uploaded files from unauthorized access.

### 6.6 Appointment booking

Customers should be able to:

- Select a service, date, and available time slot.
- Describe the issue and attach optional photos.
- Provide a service address and optional location instructions.
- Review an estimated price or see “quote required” before submitting.
- Request, cancel, or reschedule an appointment.
- View upcoming and past appointments.

Professionals should be able to:

- Configure weekly working hours, slot duration, travel buffers, and unavailable periods.
- Accept or decline a request and optionally provide a reason.
- Propose a different time for customer approval.
- View appointments in list and calendar formats.
- Mark work as in progress or completed.

**Appointment statuses:** Requested, Confirmed, In Progress, Completed, Cancelled, Declined, and Expired.

**Booking rules:**

- A request becomes confirmed only when the professional accepts it.
- Validate availability again when confirming and prevent overlapping confirmed appointments on the server.
- Pending requests do not guarantee a reserved time. If one is accepted, conflicting pending requests must be declined or offered another time.
- A reschedule proposal requires the other participant’s acceptance. Keep the existing confirmed time until the replacement time is accepted and validated.
- Make the request expiration period and cancellation cutoff configurable.
- Record status changes, timestamps, and the actor responsible.
- Store timestamps consistently and display times in the appointment’s local timezone.
- Send confirmations, changes, cancellations, and reminders to both participants.

### 6.7 Ratings and reviews

- Permit one customer review per completed appointment.
- Include a rating from 1 to 5 and optional written feedback.
- Allow professionals to respond to reviews.
- Allow reporting of abusive or misleading reviews.
- Let administrators moderate reviews under a published policy.
- Calculate public ratings from published eligible reviews.

### 6.8 Notifications

- In-app notifications for messages, booking requests, confirmations, changes, and cancellations.
- Mobile push notifications for users who opt in.
- Appointment reminders at configurable intervals.
- Optional SMS or email notifications depending on delivery cost and launch needs.
- Notification preferences and quiet hours.
- Avoid exposing private message content or full addresses in lock-screen notifications by default.

### 6.9 Administrator dashboard

- View platform activity and basic usage metrics.
- Approve, reject, suspend, and restore professional profiles.
- Manage service categories and supported locations.
- Review user reports and moderation cases.
- Manage reviews and investigate appointment disputes.
- Search users and appointments with appropriate access controls.
- Maintain an audit log of sensitive administrative actions.

## 7. Required screens

| Area | Screens |
| --- | --- |
| Public website | Home, categories, search results, professional profile, how it works, help, terms, privacy policy. |
| Authentication | Register, login, contact verification, account recovery. |
| Customer | Dashboard, favorites, conversations, chat, appointment request, appointment details, appointment history, profile, notification settings. |
| Professional | Onboarding, profile editor, service editor, portfolio, availability calendar, booking requests, appointment details, conversations, reviews, settings. |
| Administration | Overview, professional approvals, user management, categories, locations, reports, reviews, audit history. |

The mobile application should prioritize Home/Search, Messages, Appointments, and Profile in its main navigation. Professional accounts should also have easy access to requests and availability.

## 8. Design and usability

- Use a clean interface with clear service icons and readable text.
- Make category search and location selection prominent on the home screen.
- Show call, chat, and booking actions clearly on professional profiles.
- Design for mobile screens first, then adapt the website to larger screens.
- Support keyboard navigation, screen readers, visible focus states, and accessible contrast.
- Use short forms with clear validation and progress indicators.
- Optimize images and page size for slow connections and lower-cost devices.
- Prepare all interface text for translation. Confirm launch languages before implementation.
- Provide explicit loading, empty, error, offline, and permission-denied states.

## 9. Suggested technical architecture

The following is a proposed starting point, subject to the development team’s experience and hosting requirements:

- **Web:** React with Next.js for responsive pages and searchable public professional profiles.
- **Mobile:** React Native with Expo for Android and iOS.
- **Backend:** A shared TypeScript API serving web and mobile applications.
- **Database:** PostgreSQL for accounts, profiles, availability, appointments, conversations, and reviews.
- **Real-time messaging:** WebSocket-based chat with persistent message storage.
- **File storage:** Private object storage for chat attachments and identity documents; public delivery for approved portfolio images.
- **Notifications:** A background job queue for push notifications, reminders, and optional SMS/email.
- **Administration:** A protected web dashboard using the same backend authorization rules.
- **Operations:** Separate development, staging, and production environments, automated deployments, monitoring, and backups.

Keep booking validation and authorization on the backend so that website and mobile clients follow the same rules. Select exact framework versions and service providers during implementation.

## 10. Main data entities

| Entity | Important fields or relationships |
| --- | --- |
| User | ID, name, verified contact methods, roles, account status, preferences. |
| ProfessionalProfile | User ID, business name, biography, approval status, public contacts, service area, timezone. |
| Category | Name, description, icon, active status. |
| ProfessionalService | Professional ID, category ID, description, pricing type, amount, currency, duration. |
| PortfolioImage | Professional ID, image reference, caption, publication status. |
| AvailabilityRule | Professional ID, weekday, start/end time, slot length, buffer. |
| AvailabilityException | Professional ID, date/time range, unavailable reason. |
| Appointment | Customer ID, professional ID, service ID, start/end time, timezone, status, issue description, address, price estimate. |
| AppointmentEvent | Appointment ID, actor, previous/new status, timestamp, change details. |
| Conversation | Participant IDs, optional appointment reference, last activity. |
| Message | Conversation ID, sender ID, content or attachment reference, timestamp, delivery/read state. |
| Review | Appointment ID, customer ID, professional ID, rating, text, response, moderation status. |
| Notification | Recipient ID, event type, reference, read state, delivery status. |
| Report | Reporter ID, reported account/content, reason, case status. |
| AuditLog | Administrator ID, action, target, timestamp. |

Use database constraints and transactional booking logic to protect appointment integrity. Define retention and deletion rules for personal data, messages, attachments, and audit records before launch.

## 11. Security and privacy requirements

- Enforce role-based and record-level authorization on every protected endpoint.
- Encrypt network traffic and use managed encryption for stored data.
- Use secure session storage, expiration, and revocation.
- Apply rate limits to login, verification codes, search abuse, messages, and bookings.
- Validate input and uploads; prevent injection and unauthorized file access.
- Protect exact customer addresses and private contact details.
- Obtain consent before publishing a professional’s contact information.
- Record administrative access to sensitive information.
- Provide reporting, blocking, account suspension, and data deletion workflows.
- Establish backups and verify restoration before launch.
- Prepare privacy and service terms appropriate to the launch market, including clear limits on what professional verification means.

## 12. Minimum viable product (MVP)

The first release includes:

1. Responsive website and Android/iOS app using one shared backend.
2. Customer and professional registration with contact verification.
3. Professional profiles, categories, service areas, portfolio photos, and public business contacts.
4. Search and filters by category, location, and availability.
5. One-to-one text and image chat.
6. Appointment requests, acceptance/decline, rescheduling, cancellation, and completion.
7. In-app and mobile push notifications.
8. Reviews linked to completed appointments.
9. Administrator approval, category management, and report handling.

**Payment assumption:** Customers pay professionals directly outside the platform for the MVP. Display pricing information clearly, but do not collect card details or imply that payment has been processed in the application.

## 13. Future features

- In-app payments, deposits, refunds, and platform commissions.
- Professional subscriptions or clearly labeled promoted listings.
- Customer job postings and professional quotations.
- Map search and optional travel tracking during an active appointment.
- Team accounts for service companies.
- Recurring appointments and maintenance plans.
- More languages, cities, and service categories.
- Advanced identity or qualification verification.

## 14. Acceptance criteria

- A professional can register, verify a contact method, complete a profile, and submit it for approval.
- An approved professional appears in matching category and location searches.
- A visitor can view the professional’s published services and chosen public contact details.
- A signed-in customer can send a message, and only authorized conversation participants can retrieve it.
- A customer can request a valid appointment and receive its status updates.
- A professional can accept, decline, or propose a different time.
- Two simultaneous acceptance attempts cannot create overlapping confirmed appointments for the same professional.
- A reschedule takes effect only after acceptance and availability validation.
- Cancellation and reminder notifications reflect the current appointment state.
- Only the customer linked to a completed appointment can review that appointment.
- A suspended professional cannot receive new appointment requests and is removed from public discovery.
- Administrators can process approvals and reports, with sensitive actions recorded.
- Core browsing, chat, and booking flows work on supported mobile devices and desktop browsers.
- Users receive clear feedback for network failures, unavailable slots, invalid input, and empty search results.

## 15. Delivery stages

1. **Discovery:** Confirm launch market, languages, branding, verification rules, and booking policies.
2. **Design:** Create user flows, wireframes, and web/mobile screen designs.
3. **Foundation:** Build authentication, roles, database, profiles, and administration.
4. **Marketplace:** Implement categories, search, contact actions, and portfolio uploads.
5. **Communication and booking:** Implement chat, calendars, appointments, and notifications.
6. **Quality and pilot:** Test permissions, booking concurrency, usability, accessibility, and backup restoration with a small group of professionals and customers.
7. **Launch:** Deploy the website, submit mobile apps to their stores, monitor failures, and collect feedback.

Estimate schedule and cost after the launch decisions and designs are approved.

## 16. Decisions to confirm before development

- Final platform name and branding.
- Launch country, city, currency, and supported languages.
- Whether both Android and iOS must launch together.
- Whether professionals are individuals, companies, or both.
- Which professional checks are required before publication.
- Whether public contact details are visible to everyone or only signed-in users.
- Cancellation rules, request expiration period, and appointment durations.
- Whether prices are fixed, estimated, or agreed through chat.
- Who provides customer support and handles reports.
- Preferred hosting region, operating budget, and launch target.

## 17. Implementation handoff prompt

> Build the professional services marketplace described in this document. Deliver a responsive website, Android/iOS application, shared backend, and protected administrator dashboard. Prioritize the MVP and acceptance criteria. Use configurable categories and locations, enforce authorization on the backend, and prevent overlapping confirmed bookings. Provide database migrations, setup instructions, environment variable examples without secrets, meaningful tests for permissions and booking rules, and deployment instructions. Start by confirming the open product decisions and producing the user flows and data model. Do not introduce paid features or payment processing without an explicit scope decision.
