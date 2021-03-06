{{
┌──────────────────────────────────────────┐
│ Magna3_Modbus_1.1.spin                   │
│ Author: Justin Savala                    │
│ Copyright (c) 2015 Justin Savala         │
│ See end of file for terms of use.        │
└──────────────────────────────────────────┘

Based on Modbus_PAC.spin by Paul Clyne.
Reference Grundfos document number 98367081 for additional information on Modbus registers.

}}

CON
  _clkmode        = xtal1 + pll16x           ' Feedback and PLL multiplier
  _xinfreq        = 5_000_000                ' External oscillator = 5 MHz
  Baud            = 9_600
  'FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  FREQ = 80_000_000
  RX = 4     'Connection to RS485 transciever.
  TX = 5     'Connection to RS485 transciever.
  RTS = 3    'Connection to RS485 transciever.
  ImpTx = 6  'Connection to Electric Imp.
  ImpRx = 7  'Connection to Electric Imp.

VAR
   byte outbuffer[20]
   byte rawbuffer[100]
   byte inbuffer[100]
   byte PumpControl[4]  'Registers 101 through 105
   byte PumpStatus[22]  'Registers 201 through 211
   byte PumpData[90]    'Registers 301 through 345
   Long idx
   Long RChar
   Long CRCval
   Long ControlMode
   Long OperationMode
   Long Setpoint
   Long MaxPower,Rotation,OnOff,Fault,Warning,MaxSpeed,MinSpeed, PumpMax
   Long ProcessFeedback,SensorUnit,SensorMin,SensorMax, Head, Flow, Performance, Speed
   Long Frequency, ActualSet, DigitalIn, DigitalOut, Current, DCVolt, MtrVolt, WarnCode
   Long AlarmCode, ElecTemp, LiquidTemp, UserSet, DiffPressure, Watts, Load
   Long RecFlag
   Long Stack[10]

OBJ

  COMM  : "FullDuplexSerial"
  RS    : "Parallax Serial Terminal_Mod"
  MATH  : "Float32"                ' Float Math
  M     : "FloatStringNew"         ' Float Math            '
   
PUB Start  
  Math.Start                   
  Comm.Start(ImpRx,ImpTx,0,9600)
  RS.StartRXTX(RX,TX,0,Baud)
  ''cognew(Watchdog,@stack)
  M.SetPrecision(4)
  dira[TX]~~                'TX and RTS lines.
  dira[RTS]~~               'TX and RTS lines.
  dira[RX]~                 'RX Line
  byte[outbuffer][0] := $06 'Number of bytes
  byte[outbuffer][1] := $01 'Device Address, set as hex value.
  byte[outbuffer][2] := $03 'Read Command
  RecFlag := False
  waitcnt(clkfreq + cnt)
  Main

  '' AUTOadapt,Auto-Control,No Faults,No Faults,0-65.6ft,106.8,  4.9,  0.0,  0.0,  0.0,  0.0,74.51,0,0,0,0,0,

PUB Main |TMp


  Repeat
    Repeat Until Comm.RX == $21 'Waits for "!" from Electric Imp.
    'waitcnt(clkfreq/20 + cnt)
    Comm.Str(string("$,AUTOadapt,Auto-Control,No Faults,No Faults,0-65.6ft,106.8,4.9,0.0,0.0,0.0,0.0,74.51,0,0,0,0,0,"))
    Comm.TX(10) 'Carriage Return
    outa[RTS] := 1
    waitcnt(clkfreq/10 + cnt)
    outa[RTS] := 0

PUB Watchdog
  repeat
     waitcnt(clkfreq * 5 + cnt)
     if RecFlag == False
        Reboot

DAT

{{

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}
