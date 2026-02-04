# Notes & Calendar App

A barebone iOS app for note-taking and task scheduling built with SwiftUI.

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
NotesCalendarApp/
├── NotesCalendarApp.swift    # Main app entry point
├── ContentView.swift          # Tab view container
├── Models.swift              # Data models (Note, Task)
├── NotesView.swift           # Notes list and creation
└── CalendarView.swift        # Calendar and task management
```

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

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

This is a barebone implementation. Data is not persisted between app launches. To add persistence, consider implementing UserDefaults, Core Data, or SwiftData.


## TODO

-- IMPLEMENT MSGS VIEW. 
-- research feasible & low cost 

-- implment add courses tab 
--create classes for "classes"


#IMPORTANT CLASSIFIERS 


