# Task Management Application

## 1. Project Overview

This project is a comprehensive mobile Task Management Application developed using Flutter and SQLite. The app is designed to help users organize daily work through task creation, progress tracking, repeat scheduling, and local reminders.

The application supports a clean and user-friendly interface with dedicated sections for:

- Today Tasks
- Completed Tasks
- Repeated Tasks

The focus of this project is to provide practical task management features with reliable offline storage and smooth mobile usability.

## 2. Objective

The objective of this project is to build a fully functional task management app that allows users to:

- Create and manage tasks efficiently
- Categorize tasks by current, completed, and repeated status
- Track progress using subtasks and completion percentage
- Receive local notifications for upcoming tasks
- Customize app theme and notification preferences
- Export task data in useful formats

## 3. Project Scope

The app covers both basic and advanced task management operations.

### In Scope

- Add, edit, delete, and complete tasks
- Daily and custom repeat scheduling
- Progress tracking using subtasks
- Theme customization (light/dark)
- Notification sound customization
- Local notifications by due date and time
- Data export to CSV, PDF, and email sharing

### Out of Scope

- Cloud sync and multi-device login
- Real-time collaboration between users
- Online authentication system

## 4. Technology Stack

- Framework: Flutter (Dart)
- Local Database: SQLite (`sqflite`)
- State Management: `setState` / provider-based pattern (as implemented)
- Notifications: `flutter_local_notifications`
- Date/Time Handling: `intl`
- Export Utilities:
	- CSV generation
	- PDF generation
	- Email integration (device mail client)

## 5. Functional Requirements

### 5.1 Setup and Configuration

- Configure Flutter development environment
- Create Flutter project structure
- Integrate SQLite database
- Define task data model and table schema

### 5.2 User Interface

- Simple, responsive, and intuitive layout
- Dedicated sections/screens:
	- Today Tasks
	- Completed Tasks
	- Repeated Tasks
- Easy navigation and quick actions

### 5.3 Task Management

- Add Tasks:
	- Title
	- Description
	- Due date and time
	- Repeat settings
- Edit Tasks:
	- Update task details anytime
- Delete Tasks:
	- Remove unwanted tasks
- Mark as Completed:
	- Move tasks automatically to completed category

### 5.4 Advanced Features

- Customization Options:
	- Light and dark themes
	- Notification sound selection
- Progress Tracking:
	- Add subtasks/checklist items
	- Show completion percentage or progress bar
- Export Functionality:
	- Export tasks to CSV
	- Export tasks to PDF
	- Share tasks via email
- Repeat Tasks:
	- Daily repeats
	- Weekly repeats (selected days)
	- Interval-based repeats

### 5.5 Notifications

- Schedule local notifications for upcoming due tasks
- Trigger reminders based on date and time
- Respect user customization settings

### 5.6 Testing

- Validate all core user flows
- Verify responsiveness on different screen sizes
- Test data persistence and retrieval from SQLite
- Test notification scheduling and triggering
- Test repeat and progress behaviors

### 5.7 Documentation and Submission

- Maintain clean project documentation
- Use clear code structure and comments where needed
- Upload source code to GitHub
- Provide build and demo assets as required

## 6. Non-Functional Requirements

- Usability: Interface should be easy for first-time users
- Performance: Smooth interactions with minimal lag
- Reliability: Stable local data persistence
- Maintainability: Modular code for easy extension
- Compatibility: Android-first implementation, adaptable to iOS

## 7. System Architecture

The app follows a layered approach:

- Presentation Layer:
	- Screens/widgets for task list, forms, settings, and reports
- Business Logic Layer:
	- Task validation, filtering, repeat calculation, progress computation
- Data Layer:
	- SQLite helper/service handling CRUD operations

Data flow:

1. User action from UI
2. Validation and business rules applied
3. SQLite read/write operation
4. Updated data reflected in UI
5. Optional notification/export processing

## 8. Database Design (SQLite)

### 8.1 Main Task Table

Suggested schema fields:

- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `title` (TEXT NOT NULL)
- `description` (TEXT)
- `due_date` (TEXT)
- `due_time` (TEXT)
- `is_completed` (INTEGER DEFAULT 0)
- `repeat_type` (TEXT) // none, daily, weekly, interval
- `repeat_days` (TEXT) // comma-separated weekdays if weekly
- `repeat_interval` (INTEGER) // for interval repeats
- `progress` (REAL DEFAULT 0)
- `created_at` (TEXT)
- `updated_at` (TEXT)

### 8.2 Subtasks Table

- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `task_id` (INTEGER)
- `title` (TEXT NOT NULL)
- `is_done` (INTEGER DEFAULT 0)

Relationship: one task can have many subtasks.

## 9. Core Modules

- Task Module:
	- Create, update, delete, complete, and list tasks
- Repeat Engine:
	- Evaluate repeat settings and generate next occurrences
- Progress Module:
	- Manage subtasks and calculate completion percentage
- Notification Module:
	- Schedule, update, and cancel local reminders
- Export Module:
	- Generate CSV/PDF and share via email
- Settings Module:
	- Theme and notification customization

## 10. User Flow

1. User opens app
2. Home screen shows Today Tasks
3. User adds a new task with due date and repeat options
4. Task appears in relevant list
5. User adds subtasks and tracks progress
6. Notification triggers before due time
7. User marks task complete
8. Task moves to Completed Tasks
9. User can export task data anytime

## 11. Testing Strategy

### 11.1 Unit Tests

- Task model conversion and validation
- Repeat calculation logic
- Progress percentage computation

### 11.2 Widget Tests

- Task list rendering
- Add/edit form validation
- Theme switching behavior

### 11.3 Integration Tests

- End-to-end task lifecycle (add -> edit -> complete -> export)
- Notification scheduling flow
- SQLite persistence across app restarts

## 12. Risk Management

- Risk: Incorrect repeat logic
	- Mitigation: Isolated repeat engine tests with edge cases
- Risk: Notification not firing on some devices
	- Mitigation: Device-level testing and permission checks
- Risk: Data inconsistency after edits/deletes
	- Mitigation: Transaction-safe database operations

## 13. Deployment and Run Instructions

### Prerequisites

- Flutter SDK installed
- Android Studio / VS Code
- Android emulator or physical device

### Run Steps

1. Clone repository
2. Open project in IDE
3. Run:

```bash
flutter pub get
flutter run
```

### Build APK

```bash
flutter build apk
```

## 14. Proposed Folder Structure

```text
lib/
	main.dart
	core/
		constants/
		theme/
		utils/
	data/
		db/
		models/
		repositories/
	features/
		tasks/
			views/
			widgets/
			controllers/
		settings/
		notifications/
		export/
```

## 15. Deliverables

- Complete Flutter source code
- SQLite integrated task management app
- Working features for task CRUD, repeat, progress, notification, and export
- GitHub repository with clean commits
- APK build for demonstration
- Short demo video showing major features

## 16. Future Enhancements

- Cloud backup and sync
- Account login and data sync across devices
- AI-based task prioritization suggestions
- Calendar integration
- Team collaboration and shared task boards

## 17. Conclusion

This project delivers a practical and extensible task management solution using Flutter and SQLite. It demonstrates mobile app development concepts including local storage, notification handling, repeat task logic, progress tracking, and export services. The architecture and module separation make the system maintainable and ready for future upgrades.

## 18. Current Implementation Status

- Phase 1 complete: project setup, architecture, routing, and base theme
- Phase 2 complete: SQLite schema, models, and CRUD data layer
- Phase 3 complete: professional task UI with add/edit/delete/complete flows
- Phase 4 complete: completed and repeated views with filtering/categorization
- Phase 5 complete: repeat engine and subtask-based progress tracking
- Phase 6 complete: notifications and user customization settings
- Phase 7 complete: CSV/PDF/email export flow
- Phase 8 in progress: testing expansion, polish, and submission prep

## 19. Submission Checklist
