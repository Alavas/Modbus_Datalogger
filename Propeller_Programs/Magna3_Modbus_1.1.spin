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
  PST   : "Parallax Serial Terminal"
  MATH  : "Float32"                ' Float Math
  M     : "FloatStringNew"         ' Float Math            '
   
PUB Start  
  Math.Start
  ''PST.Start(9600)
  Comm.Start(ImpRx,ImpTx,0,9600)
  RS.StartRXTX(RX,TX,0,Baud)
  cognew(Watchdog,@stack)
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

PUB Main |TMP

  Repeat
    RequestData
    EvalData
    ''PST.BIN(PumpData[2],8)
    ''PST.BIN(PumpData[3],8)
    ''PST.NewLine
    ''PST.DEC(Flow)
    ''PST.NewLine
    Repeat Until Comm.RX == $21 'Waits for "!" from Electric Imp.
    Comm.Str(string("$,"))
    Comm.Str(ControlMode)
    Comm.TX($2C) 'Comma 
    Comm.str(OperationMode)
    Comm.TX($2C) 'Comma
    Comm.str(AlarmCodes(WarnCode))
    Comm.TX($2C) 'Comma
    Comm.str(AlarmCodes(AlarmCode))
    Comm.TX($2C) 'Comma
    Comm.str(m.floattostring(math.FDiv(math.FFloat(SensorMin),100.0)))
    Comm.str(string("-")) 
    Comm.str(m.floattostring(math.FDiv(math.FFloat(SensorMax),100.0)))
    Comm.Str(SensorUnit)
    Comm.TX($2C) 'Comma
    If PumpMax == 265.7
      TMP := SensorMax-SensorMin
      TMP := (math.FMul((math.FFloat(TMP)),(math.FDiv(math.FFloat(UserSet),10000.0))))  'Sensor Feedback
      Comm.Str(m.floattoformat(math.FDiv(math.FAdd(TMP,math.FFloat(SensorMin)),100.0),5,1))
    Else  
      Comm.str(m.floattoformat(math.FMul((PumpMax),(math.FDiv(math.FFloat(UserSet),10000.0))),5,1))  'User Setpoint
    Comm.TX($2C) 'Comma
    TMP := SensorMax-SensorMin 
    TMP := (math.FMul((math.FFloat(TMP)),(math.FDiv(math.FFloat(ActualSet),10000.0))))  'Actual Setpoint
    Comm.Str(m.floattoformat(math.FDiv(math.FAdd(TMP,math.FFloat(SensorMin)),100.0),5,1))
    Comm.TX($2C) 'Comma
    TMP := SensorMax-SensorMin
    TMP := (math.FMul((math.FFloat(TMP)),(math.FDiv(math.FFloat(ProcessFeedback),10000.0))))  'Sensor Feedback
    Comm.Str(m.floattoformat(math.FDiv(math.FAdd(TMP,math.FFloat(SensorMin)),100.0),5,1))
    Comm.TX($2C) 'Comma
    'Convert m^3/h to GPM
    Comm.str(m.floattoformat(math.FMul(math.FFloat(Flow),0.4403),5,1))
    Comm.TX($2C) 'Comma
    'Convert bar to ft
    Comm.str(m.floattoformat(math.FMul(math.FFloat(Head),0.03345),5,1))
    Comm.TX($2C) 'Comma
    'Convert bar to ft
    Comm.str(m.floattoformat(math.FMul(math.FFloat(DiffPressure),0.03345),5,1))
    Comm.TX($2C) 'Comma
    Comm.str(m.floattostring(math.FDiv(math.FFloat(LiquidTemp),100.0)))
    Comm.TX($2C) 'Comma
    Comm.DEC(Speed)
    Comm.TX($2C) 'Comma
    Comm.str(m.floattostring(math.FDiv(math.FFloat(Frequency),10.0)))
    Comm.TX($2C) 'Comma
    Comm.str(m.floattostring(math.FDiv(math.FFloat(Performance),100.0)))
    Comm.TX($2C) 'Comma
    Comm.DEC(Watts)
    Comm.TX($2C) 'Comma
    Comm.str(m.floattostring(math.FDiv(math.FFloat(Current),10.0)))
    Comm.TX($2C) 'Comma
    Comm.TX(10) 'Carriage Return
  
PUB SendReceive | ExeceptionCode,Flag, FrameEndCountOffset, FrameEndFlag,i,FrameEndTgt,FrameCheck
    RecFlag := False
    FrameEndCountOffset := (FREQ / Baud * 11 * 35 / 10) ' you can't multiply by a decimal so use integer and then divide by 10
                                                      ' * 35 / 10 == *3.5
    FrameCheck := False
    bytefill(@Inbuffer, 0, 100)
    bytefill(@RawBuffer, 0, 100)
    idx := 1
    GenCRC
    Flag := False
    outa[RTS]~~
    waitcnt(2000 + cnt)
    RS.TX(byte[outbuffer][1])
    RS.TX(byte[outbuffer][2])
    RS.TX(byte[outbuffer][3])
    RS.TX(byte[outbuffer][4])
    RS.TX(byte[outbuffer][5])                                                    
    RS.TX(byte[outbuffer][6])
    RS.TX(byte[@CRCVal][0])
    RS.TX(byte[@CRCVal][1])             
    waitcnt(750_000 + cnt)   ''Delay needed to allow other cog to finish.
    outa[RTS]~

    RS.rxflush
    repeat until Flag == True
      RChar := RS.rxcheck
      if RChar <> -1                                    'A new char has arrived
        rawbuffer[idx++] := RChar                       'so put it in the buffer @ position idx and increment idx
        FrameEndTgt := cnt + FrameEndCountOffset        ' we know that we have got a frame time timing
        FrameCheck := True
      if ((cnt >= FrameEndTgt) AND FrameCheck )OR (idx > 99)
        bytefill (@Inbuffer, 0, 25)
        bytemove (@InBuffer,@RawBuffer,100)              'Copy Incomming Raw Buffer to InBuffer
        InBuffer[0] := idx-1
        bytefill (@RawBuffer, 0, 90)                    'Clear Raw Buffer
        RChar := RS.rxcheck
        Flag := True
'        repeat i from 0 to (idx-1)
'          Comm.NewLine
'          Comm.BIN(inbuffer[i],8)
'          Comm.Str(string(" Test HEX = ")) 
'          Comm.HEX(inbuffer[i],2)
    RecFlag := True

PUB RequestData

  'Registers 201 through 211.
  byte[outbuffer][3] := $00 'Start Address High Byte
  byte[outbuffer][4] := $C8 'Start Address Low Byte
  byte[outbuffer][5] := $00 'Quantity High Byte
  byte[outbuffer][6] := $0B 'Quantity Low Byte (11 registers).
  SendReceive 'Receive current requested registers.
  bytemove(@PumpStatus[0],@inbuffer[4],22)
  'Registers 301 through 345.
  byte[outbuffer][3] := $01 'Start Address High Byte
  byte[outbuffer][4] := $2C 'Start Address Low Byte
  byte[outbuffer][5] := $00 'Quantity High Byte
  byte[outbuffer][6] := $2D 'Quantity Low Byte (11 registers).
  SendReceive 'Receive current requested registers.
  bytemove(@PumpData[0],@inbuffer[4],90)

PUB EvalData|X,TMP

  'Current status, register 201.
  MaxPower := (PumpStatus[1] & %0010_0000)>>5
  Rotation := (PumpStatus[1] & %0100_0000)>>6
  TMP := ((PumpStatus[0] & %0000_0010)>>1)
  Case TMP
    0:   OnOff := string("Off")
    1:   OnOff := string("On")               
  Fault := (PumpStatus[0] & %0000_0100)>>2
  Warning := (PumpStatus[0] & %000_1000)>>3
  MaxSpeed := (PumpStatus[0] & %0010_0000)>>5
  MinSpeed := (PumpStatus[0] & %1000_0000)>>7
  'Process Feedback, register 202. Percentage of sensor max.
  ProcessFeedback := ((PumpStatus[2] <<8) + PumpControl[3])
  'Control Mode, register 203.
  Case PumpStatus[5]
    0:   ControlMode := string("Constant Speed")
    1:   ControlMode := string("Constant Frequency")
    3:   ControlMode := string("Constant Head")
    4:   ControlMode := string("Constant Pressure")
    5:   ControlMode := string("Constant Differential Pressure")
    6:   ControlMode := string("Proportional Pressure")
    7:   ControlMode := string("Constant Flow")
    8:   ControlMode := string("Constant Temperature")
    10:  ControlMode := string("Constant Level")
    128: ControlMode := string("AUTOadapt")
    129: ControlMode := string("FLOWadapt")
    130: ControlMode := string("Closed Loop Sensor")
    255: ControlMode := string("Control Mode = TEST")
  'Operation Mode, register 204.
  Case PumpStatus[7]
    0:   OperationMode := string("Auto-Control")
    4:   OperationMode := string("Open Loop Min")
    6:   OperationMode := string("Open Loop Max")
    255: OperationMode := string("Operation Mode = TEST")
  'Alarm Code, register 205.
  AlarmCode := ((PumpStatus[8]<<8)+PumpStatus[9])
  'Warning Code, register 206.
  WarnCode := ((PumpStatus[10]<<8)+PumpStatus[11])
  'Feedback Sensor Min, register 210.
  SensorMin := ((PumpStatus[18] <<8) + PumpStatus[19])
  'Feedback Sensor Max, register 211.
  SensorMax := ((PumpStatus[20] <<8) + PumpStatus[21])
  'Head, register 301. 0.001 bar
  Head := ((PumpData[0] <<8) + PumpData[1])
  'Volume Flow, Register 302. 0.1m^3/h
  Flow := ((PumpData[2] <<8) + PumpData[3])
  'Relative Performance, register 303. 0.01%
  Performance := ((PumpData[4] <<8) + PumpData[5])
  'Speed, register 304. 1 rpm
  Speed := ((PumpData[6] <<8) + PumpData[7])
  'Frequency, register 305. 0.1Hz
  Frequency := ((PumpData[8] <<8) + PumpData[9])
  'Digital Inputs, register 306.
  DigitalIn := ((PumpData[10] <<8) + PumpData[11])
  'Digital Outputs, register 307.
  DigitalOut := ((PumpData[12] <<8) + PumpData[13])       
  'Actual Setpoint 308, 0.01%
  ActualSet := ((PumpData[14] <<8) + PumpData[15])
  'Motor Current, register 309. 0.1A
  Current := ((PumpData[16] <<8) + PumpData[17])
  'DC-Link Voltage, register 310. 0.1V
  DCVolt := ((PumpData[18] <<8) + PumpData[19])
  'Motor Voltage, register 311. 0.1V
  MtrVolt := ((PumpData[20] <<8) + PumpData[21])
  'Power Used, register 312&313. 1 W
  Watts :=   ((PumpData[22] <<24) + (PumpData[23] <<16)+ (PumpData[24] << 8) + PumpData[25]) 
  'Electronics Temp, register 321. 0.01K
  ElecTemp := ((PumpData[40] <<8) + PumpData[41])
  ElecTemp := ConvertK(ElecTemp)
  'Liquid Temp, register 322. 0.01K
  LiquidTemp := ((PumpData[42] <<8) + PumpData[43])
  LiquidTemp := ConvertK(LiquidTemp)
  'User Setpoint, register 338. 0.01%
  UserSet := ((PumpData[74] <<8) + PumpData[75])
  'Diff Pressure, register 339. 0.001 bar
  DiffPressure := ((PumpData[76] <<8) + PumpData[77])
  'Load percentage, register 342. 0.01%
  Load := ((PumpData[82] <<8) + PumpData[83])   
  'Sensor Unit, register 209.   
  Case PumpStatus[17]
    0:    SensorUnit := string("bar")
    1:    SensorUnit := string("mbar")
    2:    'm, convert to ft.
          SensorUnit := string("ft")
          SensorMin := ConvertM(SensorMin)
          SensorMax := ConvertM(SensorMax)
          PumpMax := 16.3
    3:    SensorUnit := string("kPa")
    4:    SensorUnit := string("psi")
    5:    SensorUnit := string("ft")
    6:    SensorUnit := string("m^3/h")
    7:    SensorUnit := string("m^3/s")
    8:    SensorUnit := string("l/s")
    9:    SensorUnit := string("gpm")
    10:   SensorUnit := string("C")
    11:   SensorUnit := string("F")
    12:   SensorUnit := string("%")
    13:   'K, convert to F.
          SensorUnit := string("F")
          SensorMin := ConvertK((SensorMin*100))
          SensorMax := ConvertK((SensorMax*100))
          PumpMax := 265.7
    14:   SensorUnit := string("W")  
  

PUB ConvertK(K) 'Converts Kelvin to Fahrenheit
  Return K := ((((K-27315)*18)+32000)/10)

PUB ConvertM(L) 'Converts Meters to Feet
  Return L := L*328

PUB AlarmCodes(Code)
  Case Code
    0:  Return string("No Faults")
    1:  Return string("Leakage Current")
    2:  Return string("Missing Phase")
    3:  Return string("External Fault Signal")
    4:  Return string("Too Many Restarts")
    5:  Return string("Regenerative Braking")             
    6:  Return string("Mains Fault")
    7:  Return string("Too Many Hardware Shutdowns")
    8:  Return string("PWM Switching Frequency Reduced")
    9:  Return string("Phase Sequence Reversal")
    10: Return string("Communication Fault-Pump")
    11: Return string("Water-In-Oil Fault")
    12: Return string("Time For Service")
    13: Return string("Moisture Alarm-Analog")
    14: Return string("Electronic DC-Link Protection")
    15: Return string("Communication Fault-SCADA")
    16: Return string("Other")
    17: Return string("Performance Requirement Cannot Be Met")
    18: Return string("Commanded Alarm Standby")
    19: Return string("Diaphragm Break-Dosing Pump")
    20: Return string("Insulation Resistance Low")
    21: Return string("Too Many Starts Per Hour")
    22: Return string("Moisture Switch Alarm-Digital")
    23: Return string("Smart Trip Gap Alarm")
    24: Return string("Vibration")
    25: Return string("Setup Conflict")
    26: Return string("Load Continues With Motor Off")
    27: Return string("External Motor Protection Activated")
    28: Return string("Battery Low")
    29: Return string("Turbine Operation")
    30: Return string("Change Bearings")
    31: Return string("Change Veristor")
    32: Return string("Overvoltage")
    35: Return string("Gas In Pump Head")
    36: Return string("Discharge Valve Leaking")
    37: Return string("Suction Valve Leaking")
    38: Return string("Vent Valve Defective")
    40: Return string("Undervoltage")
    41: Return string("Undervoltage Transient")
    42: Return string("Cut-In Fault-dVdT")
    45: Return string("Voltage Asymmetry")
    48: Return string("Overload")
    49: Return string("Overcurrent")
    50: Return string("Motor Protection Function")
    51: Return string("Bocked Motor or Pump")
    52: Return string("Motor Slip High")
    53: Return string("Stalled Motor")
    54: Return string("Motor Protection Function-3 Sec Limit")
    55: Return string("motor Current Protection")
    56: Return string("Underload")
    57: Return string("Dry Running")
    58: Return string("Low Flow")
    59: Return string("No Flow")
    60: Return string("Low Input Power")
    64: Return string("Overtemperature")
    88: Return string("Sensor Fault")


PUB GenCRC|i
  CRCVal := 0
  CRCVal := $FFFF
  i:= 1
  repeat while i < (byte[outbuffer][0]+1)
      CRCVal ^= byte[outbuffer][i++] 'XOR and store back in
      repeat 8
        if CRCVal & $01 == 1
          CRCVal := CRCVal >>1
          CRCVal := CRCVal ^ $A001
        else
          CRCVal := CRCVal >> 1

PUB Watchdog
  repeat
     waitcnt(clkfreq * 10 + cnt)
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
