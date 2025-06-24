---
title: "STM32 Motor Velocity Control"
weight: 1
draft: false
---
# Velocity Control STM32

## Basic Communication Settings

- **Baudrate**: 921600
- **CRC**: CRC32 (Input/Output Reflected)
- **UART**: Uses UART2

## UART Communication Protocol

The following command modes are supported over UART:

- **INIT_STATE**: System Initialization
- **SET_SPEED**: Set Motor Speed
- **CURRENT_SPEED**: Transmit Current Speed
- **SET_BRAKE**: Set Brake
- **SET_PID**: Set PID Parameters
- **CURRENT_PID**: Transmit Current PID Parameters

## CRC Verification Method

- Uses CRC32 (input/output reflected) to verify the integrity of UART data.
- In the event of a CRC error, an error message is returned to prompt a retry.

## Code Components

Key files:

- **UART_handler.cpp**  
  - Receives UART data and parses packets  
  - Handles command modes and data transmission

- **Drive_system.cpp**  
  - PID-based motor speed and brake control  
  - Includes logic for speed measurement and control

- **real_main.cpp**  
  - Main entry point, system initialization, and main loop  
  - Handles HAL setup (TIM, UART, etc.) and interrupt processing

## Usage

1. **Build and Upload using STM32CubeIDE**
2. **UART Communication Settings**
   - Default RX/TX buffer size: 24 bytes
3. **Example Commands**:
   - System Initialization: ``INIT_STATE``
   - Set Speed: ``SET_SPEED``
   - Set Brake: ``SET_BRAKE``
   - Set PID: ``SET_PID``

## Cautions

- An error code is returned in the event of a CRC error.
- If the ID is 0, the command applies to all motors.
- Incomplete DMA initialization may result in reception errors.

## Inquiries and Modifications

For further questions, please contact the project manager or use the team issue tracker.

