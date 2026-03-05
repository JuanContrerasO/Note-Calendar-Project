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
## File Structure

Taskly/
├── TasklyApp.swift            # SwiftData configuration
├── ContentView.swift          # Main tabs (adaptive)
├── Models.swift               # Models: Note, TaskItem DrawingNote, Course
├── NotesView.swift            # Text notes management
├── CalendarView.swift         # Calendar with EventKit integration
├── CalendarManager.swift      # Calendar access management
├── DrawingNotesView.swift     # Drawn notes with PencilKit
├── CanvasView.swift           # Custom view for PencilKit
└── ScheduleView.swift         # Course schedule management
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


# TASKLY: ios task productivity manager - Team 12

A productivity app for ios. Developed by Ava Saltzman, Juan Renteria, and Juan Contreras.

## Project Description

App for school; tell the app your schedule & after the class is over, pops up asking if there's any homework & if so, when it is due. Will remind of homework 2 days before it was set/due for. Another feature includes note taking, specifically for Ipad apple pencil, but also works for phone with textbox, etc.

## Languages used

SwiftUI

## IDE


