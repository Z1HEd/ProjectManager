# ProjectManager

ProjectManager is a Godot 4.5 app for organizing teamwork through task management and team communication.

It uses Firebase Authentication and Realtime Database as the backend, with Firebase rules protecting project data.

## Features

- Account creation, editing, and deletion
- Project creation and management
- Realtime project synchronization
- Role-based project permissions
- Multiple task management views
- Integrated per-project chat system

## Project Views

ProjectManager includes 5 different project views:

- **Summary** — project description, member list, and basic project stats
- **Kanban** — drag-and-drop task board
- **Task List** — dynamic task table with sorting and filtering features
- **Timeline** — view for timed tasks
- **Chat** — realtime per-project chat with clickable links

## Project Roles

Projects support 4 different member roles:

- **Owner** — full project control, including project settings and member roles
- **Manager** — can manage tasks and members, but cannot edit project details or change member roles
- **Member** — can edit tasks assigned to them
- **Viewer** — read-only access

## Technical Details

- Built with Godot 4.5
- Uses HTTPS/REST for data fetching
- Uses SSE listeners for realtime updates
- Uses Firebase RTDB and Firebase Auth backend
- Includes modified versions of:
  - [DynamicDataTable](https://github.com/jospic/dynamicdatatable)
  - [Calendar Button](https://github.com/BuckWildGames/Godot4xCalendarButton)
