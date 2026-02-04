# Taskly: iOS Task Productivity Manager - Team 12

A productivity app for iOS built with SwiftUI. Developed by Ava Saltzman, Juan Renteria, and Juan Contreras.

## Project Description

App for school; tell the app your schedule & after the class is over, pops up asking if there's any homework & if so, when it is due. Will remind of homework 2 days before it was set/due for. Another feature includes note taking, specifically for iPad apple pencil, but also works for phone with textbox, etc.

## Features

### Notes
- Create, view, and delete notes
- Each note has a title, content, and creation date
- Simple list view with navigation

### Calendar
- Create, view, and delete tasks
- Mark tasks as complete/incomplete
- Interactive calendar date picker
- Tasks filtered by selected date
- Time-based scheduling

## File Structure

```
Taskly/
├── TasklyApp.swift            # Main app entry point (SwiftData setup)
├── ContentView.swift          # Tab view container
├── Models.swift               # Data models (Note, Task, Msgs)
├── Item.swift                 # SwiftData model
├── NotesView.swift            # Notes list and creation
├── CalendarView.swift         # Calendar and task management
└── msgsView.swift             # Messages view (in progress)
```

## Requirements

- iOS 26.2+
- Xcode 26.2+
- Swift 5.0+

## Usage

### Notes Tab
- Tap "+" to create a new note
- Tap on a note to view its details
- Swipe left on a note to delete

### Calendar Tab
- Select a date from the calendar picker
- Tap "+" to create a new task for that date
- Tap the circle to mark tasks as complete
- Swipe left on a task to delete

## Note

This is a barebone implementation. Data is not persisted between app launches. SwiftData is configured but not yet integrated with the views.

## TODO

-- IMPLEMENT MSGS VIEW
-- research feasible & low cost

-- implement add courses tab
-- create classes for "classes"

## Languages Used

SwiftUI

## IDE

Xcode
