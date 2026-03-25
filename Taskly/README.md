# Taskly

Taskly is a SwiftUI productivity app that combines notes, drawing, calendar tasks, and course schedules in one place.

## Features

- Notes: create, view, and delete text notes
- Drawings: create and save PencilKit drawings
- Calendar: add tasks by date/time and optionally save them to the system calendar
- Events: view system calendar events for a selected day
- Schedule: create and manage course schedules

## Requirements

- iOS 17+ (SwiftData)
- Xcode 15+

Note: Some UI styles may require newer OS versions depending on deployment target.

## Usage

- Notes tab: tap "+" to create a note, swipe left to delete
- Draw tab: tap "+" to create a new drawing
- Calendar tab: pick a date, add tasks, and toggle completion
- Schedule tab: add courses with days and times

## Data and Permissions

- Local data is stored using SwiftData
- Calendar integration uses EventKit and requires user permission

## Project Structure

```
Taskly/
├── App/TasklyApp.swift
├── Models/Models.swift
├── Views/
│   ├── ContentView.swift
│   ├── Notes/NotesView.swift
│   ├── Calendar/CalendarView.swift
│   ├── Calendar/CalendarManager.swift
│   ├── Canvas/CanvasView.swift
│   ├── Canvas/DrawingNotesView.swift
│   └── Schedule/ScheduleView.swift
├── Assets.xcassets
├── Info.plist
└── Taskly.entitlements
```

## License

See `LICENSE`.
