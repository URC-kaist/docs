---
title: "Velocity Control Algorithm"
weight: 1
draft: false
---
# Velocity Control Algorithm

## RPM Measurement Algorithm

The `DriveSystem` class’s `measureRpm()` function is responsible for RPM measurement.

1. **Using DMA Input Capture Buffer**

   - DMA stores capture values in a circular buffer (`m_icDataCh`).
   - The latest measurement index is identified using the DMA's `NDTR` value.

2. **Calculate the Period ({{< katex >}}\Delta t{{< /katex >}})**

   - Compute the difference between timer values at the latest and previous indices.  
   - {{< katex >}}\Delta t{{< /katex >}} (seconds) = (current capture value - previous capture value) / timer frequency (`TIMER_FREQ`)

3. **Convert Frequency to RPM**

   {{< katex display=true >}}
   RPM = \frac{60 \times f}{PULSE\_PER\_REV}
   {{< /katex >}}

   - For example, for an encoder with 1024 pulses per revolution, `PULSE_PER_REV = 1024`

4. **Determine Stop Condition**

   - If there is no data change in the DMA or if the pulse interval is abnormal, the system is considered to be stopped.

### RPM Measurement Code

```cpp
double DriveSystem::measureRpm()
{
    uint32_t ndtr = __HAL_DMA_GET_COUNTER(&m_hdmaIC);
    int currentIndex = wrapIndex(IC_BUF_SIZE - ndtr - 1, IC_BUF_SIZE);
    int prevIndex = wrapIndex(currentIndex - 2, IC_BUF_SIZE);

    uint32_t currentTime = m_icDataCh[currentIndex];
    uint32_t prevTime    = m_icDataCh[prevIndex];

    if (prevTime == 0)
        return 0.0f;

    double dt = static_cast<double>(currentTime - prevTime) / static_cast<double>(TIMER_FREQ);
    if (dt <= 0.0f || isZeroSpeedDetected(currentIndex, 0.4f))
        return 0.0f;

    double frequency = 1.0f / dt;
    double rpm = (60.0f * frequency) / PULSE_PER_REV;
    return rpm;
}
```

### Stop Detection Code

```cpp
bool DriveSystem::isZeroSpeedDetected(int currentIndex, double threshold)
{
    if (m_icDataCh[m_prev_index] == m_icDataCh[currentIndex])
        m_zero_sampling_stack += 1;
    else
        m_zero_sampling_stack = 0;

    if (m_zero_sampling_stack > 50)
        return true;

    m_prev_index = currentIndex;

    // Additional logic to check for abnormal pulse intervals
    return false;
}
```

## STM32 Timer Settings

### TIM2 Settings

```c
void MX_TIM2_Init(void)
{
    htim2.Instance = TIM2;
    htim2.Init.Prescaler = 1700 - 1;  // Example: 170 MHz → 100 kHz (10 µs)
    htim2.Init.CounterMode = TIM_COUNTERMODE_UP;
    htim2.Init.Period = 4294967295;
    htim2.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
    // Configure Input Capture, detect both edges
}
```

### PWM Timer Settings

- Configure PWM mode for TIM1, TIM4, etc.
- Control motor speed and direction by changing the PWM duty cycle.

## Conclusion

- Accurate RPM measurement using input capture and DMA.
- Precise motor control achieved through PID control.
- Efficient and accurate speed control implemented via timer settings.

