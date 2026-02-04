## LED Drivers Example - PCA9685 PWM LED Demo
##
## Demonstrates the PCA9685 16-channel PWM LED driver with smooth brightness fading.
## This example creates a wave pattern across 16 LEDs.
##
## Hardware setup:
## - Daisy Seed
## - PCA9685 breakout board
## - 16 LEDs connected to PCA9685 channels
## - I2C: SCL=D11, SDA=D12
## - Optional: Output Enable pin on D10

import panicoverride
import std/math
import ../src/nimphea
import ../src/per/i2c
import ../src/dev/leddriver

useNimpheaNamespace()

# Allocate DMA buffers in D2 memory for the LED driver
var bufferA {.codegenDecl: "$# $# __attribute__((section(\".sram_d2\")))".}: LedDriverDmaBuffer[1]  # Single PCA9685 chip
var bufferB {.codegenDecl: "$# $# __attribute__((section(\".sram_d2\")))".}: LedDriverDmaBuffer[1]

var 
  driver: LedDriverPca9685[1, true]  # 1 chip, persistent buffers
  phase: float32 = 0.0
  hw: DaisySeed

proc audioCallback(input_buffer, output_buffer: AudioBuffer, size: int) {.cdecl.} =
  for i in 0 ..< size:
    output_buffer[0][i] = 0.0
    output_buffer[1][i] = 0.0

# Main program
hw.init()

# Configure LED driver
var config: LedDriverConfig[1]
config.i2c_config.periph = I2C_1
config.i2c_config.speed = I2C_400KHZ
config.i2c_config.mode = I2C_MASTER
config.i2c_config.pin_config.scl = D11()
config.i2c_config.pin_config.sda = D12()
config.addresses = [0'u8]  # PCA9685 address 0 (jumpers all open)
config.oe_pin = D10()  # Output enable (active low)

# Initialize LED driver
driver.init(config, addr(bufferA), addr(bufferB))

# Start audio (not used but keeps system running)
hw.startAudio(audioCallback)

# Main loop - create wave pattern across LEDs
while true:
  phase += 0.02  # Animation speed
  if phase > 6.28318:  # 2*PI
    phase = 0.0
  
  # Set each LED brightness based on sine wave
  for led in 0 ..< 16:
    let 
      ledPhase = phase + (led.float32 * 0.4)  # Offset each LED
      brightness = (sin(ledPhase) + 1.0) * 0.5  # 0.0 to 1.0
    driver.setLed(led, brightness)
  
  # Update LEDs (non-blocking DMA transfer)
  if not driver.swapBuffersAndTransmit():
    # Timeout occurred - LED update may be delayed but continue anyway
    discard
  
  # Update at 10Hz
  delayMs(100)
