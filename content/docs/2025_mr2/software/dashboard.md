---
title: "Dashboard"
weight: 1
draft: false
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---
# Dashboard Application

## Overview

The [**Dashboard Application**](https://github.com/URC-kaist/urckaist-dashboard) is a modern desktop application built with [Tauri](https://tauri.app/), [React](https://reactjs.org/), [Typescript](https://www.typescriptlang.org/), and [Vite](https://vitejs.dev/). It is designed to interact with a ROS (Robot Operating System) backend, leveraging [ROSLIB](http://wiki.ros.org/roslibjs) for communication over WebSockets. The interface offers multiple tabs to monitor, control, and visualize data such as video streams, network pings, logs, and various ROS topics.

## Installation

The dashboard application is cross-compiled and bundled for multiple OS platforms including:

- Windows
- macOS (x86_64 / arm64)
- Linux

The bundled application can be downloaded from the [Releases](https://github.com/URC-kaist/urckaist-dashboard/releases) section.

## Installation from Source

**Prerequisites:**

- Node.js and pnpm
- Rust toolchain (required by Tauri)
- A running ROS environment (if you intend to connect to a ROS master)

**Steps to Install:**

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/URC-kaist/urckaist-dashboard.git
   cd urckaist-dashboard
   ```

2. **Install Node Dependencies:**


   ```bash
   pnpm install
   ```

3. **Setup Rust Environment:**

   Ensure you have the Rust toolchain installed. Follow instructions at [https://www.rust-lang.org/tools/install](https://www.rust-lang.org/tools/install).

4. **Build the Application:**

   Build the frontend using Vite and bundle the application with Tauri:

   ```bash
   pnpm tauri build
   ```

5. **Run in Development Mode:**

   Start the development server:

   ```bash
   pnpm tauri dev
   ```

## Project Structure

Below is a simplified overview of the project structure:

```none
.
├── App.css
├── App.tsx
├── MainPage.css
├── MainPage.tsx
├── ROSContext.tsx
├── VideoStream.tsx
├── main.tsx
└── src/
    ├── tabs/
    │   ├── Dashboard/
    │   │   ├── Dashboard.tsx
    │   │   ├── Logs.tsx
    │   │   └── Bms.tsx
    │   ├── Drive/
    │   │   └── Drive.tsx
    │   ├── PID/
    │   │   └── PID.tsx
    │   ├── Science/
    │   │   └── Science.tsx
    │   └── Misc/
    │       └── Misc.tsx
    └── components/
        ├── GamePadVisualizer.tsx
        └── NetworkPing.tsx
```

The project also includes various assets (icons, images, GLB models) and configuration files specific to Tauri, Cargo, and Vite.

## ROS Integration

The application integrates ROS communication using **ROSLIB**. A central context, defined in `ROSContext.tsx`, manages the connection state and exposes helper functions.

**Key Components:**

- **ROSProvider:** Wraps the application to provide ROS connection state and functions.
- **useROS Hook:** Allows components to access ROS connection details, initialize connections, and handle connection events (e.g., connection, error, close).

**Example Usage in `ROSContext.tsx`:**

```typescript
import { createContext, useContext, useState, ReactNode } from 'react';
import ROSLIB from 'roslib';

interface ROSContextType {
  ros: ROSLIB.Ros | null;
  server: string;
  loading: boolean;
  status: 'Connected' | 'Disconnected' | null;
  message: string | null;
  initializeROS: (ip: string, port: string) => void;
}

const ROSContext = createContext<ROSContextType | undefined>(undefined);

export function ROSProvider({ children }: { children: ReactNode }) {
  // State and initialization logic here...
}

export function useROS(): ROSContextType {
  const context = useContext(ROSContext);
  if (!context) {
    throw new Error('useROS must be used within a ROSProvider');
  }
  return context;
}
```

## Screens and Tabs

The main interface is structured as a tabbed dashboard (see `MainPage.tsx`):

- **Dashboard Tab:** Displays an overview of connected ROS topics, nodes, video stream, network ping, logs, and gamepad visualization.
- **Drive Tab:** Provides driving control functionalities.
- **PID_Debug Tab:** For PID debugging tasks.
- **Science Tab:** Handles functionalities related to science missions.
- **Misc Tab:** Contains additional miscellaneous features.

Each tab dynamically loads its corresponding component based on the active connection status. When a ROS connection is established, the tabs are displayed; otherwise, a connection form is presented.

## Dependencies

The project relies on the following dependencies:

### TS Dependencies
- **Leaflet**: A JavaScript library for creating interactive maps.
- **Three.js**: A 3D rendering library.
- **ROSLIB**: A JavaScript library for ROS communication.
- **React**: A JavaScript library for building user interfaces.

### Rust Dependencies
- **ping**: A Rust library for sending ICMP echo requests.
- **macaddr**: A Rust library for working with MAC addresses.
- **wol-rs**: A Rust library for sending Wake-on-LAN packets.

## Usage

1. **Launching the Application:**
   - Run the development server or build the application for production.
2. **Connecting to ROS:**
   - When the application starts, you will be prompted to enter the IP address and port for your ROS master.
   - Upon successful connection, the dashboard will display real-time data from ROS topics and nodes.
3. **Navigating Tabs:**
   - Use the tab bar at the top of the screen to switch between functionalities (Dashboard, Drive, PID_Debug, Science, Misc).
4. **Disconnecting:**
   - Click the **Disconnect** button in the header to close the ROS connection.

## Conclusion

This dashboard application leverages modern web technologies and ROS integration to provide a powerful and intuitive interface for monitoring and controlling robotic systems. For further customization or contribution details, please refer to the source code and inline documentation.
