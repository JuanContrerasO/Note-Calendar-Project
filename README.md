# Taskly

Taskly is a SwiftUI productivity app that combines notes, drawing, calendar tasks, and course schedules in one place.

## Features

- Notes: create, view, edit, and delete text notes
- Folders: organize notes into folders with colors and expand/collapse lists
- Drag and drop: reorder notes and folders, or move a note into a folder by dragging
- Export: export notes as PDF or .txt, and drawings as PDF
- Drawings: create and save PencilKit drawings
- Calendar: add tasks by date/time and optionally save them to the system calendar
- Events: view system calendar events for a selected day
- Reminders: set local notifications for tasks
- Schedule: create and manage course schedules with optional calendar sync
- Home: personalized welcome screen with an overview of notes, tasks, and courses

## Requirements

- iOS 17+ (SwiftData)
- Xcode 15+

Note: Some UI styles may require newer OS versions depending on deployment target.

## Usage

- Notes tab: tap "+" to create a note or folder
- Folders: tap to expand/collapse, drag notes onto a folder to file them
- Edit mode: tap Edit, then tap a note or folder to edit
- Swipe left to delete notes or folders
- Export: open a note and tap the export icon to save as PDF or .txt
- Draw tab: tap "+" to create a new drawing; open a drawing and tap the export icon to save as PDF
- Calendar tab: pick a date, add tasks, and toggle completion
- Schedule tab: add courses with days and times; toggle calendar sync per course

## Data and Permissions

- Local data is stored using SwiftData
- Calendar integration uses EventKit and requires user permission
- Reminders use UserNotifications and require notification permission

## Project Structure

```
Taskly/
├── App/TasklyApp.swift
├── Models/Models.swift
├── ContentView.swift
├── Home/HomeView.swift
├── Notes/NotesView.swift
├── Calendar/CalendarView.swift
├── Calendar/CalendarManager.swift
├── CanvasView.swift
├── DrawingNotesView.swift
├── Schedule/ScheduleView.swift
├── Utilities/
│   ├── CancelButton.swift
│   ├── EditCourseView.swift
│   ├── Extensions.swift
│   ├── NoteSaver.swift
│   └── NotificationManager.swift
├── Assets.xcassets
├── Info.plist
└── Taskly.entitlements
```

## License

See `LICENSE`.
