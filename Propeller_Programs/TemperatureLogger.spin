{{
┌──────────────────────────────────────────┐
│ TemperatureLogger.spin                   │
│ Author: Justin Savala                    │
│ Copyright (c) 2015 Justin Savala         │
│ See end of file for terms of use.        │
└──────────────────────────────────────────┘

}}

CON
  _clkmode        = xtal1 + pll16x           ' Feedback and PLL multiplier
  _xinfreq        = 5_000_000                ' External oscillator = 5 MHz
  Baud            = 9_600
  ImpTx = 6  'Connection to Electric Imp.
  ImpRx = 7  'Connection to Electric Imp.
  Data  = 19
  Clk   = 11
  CS    = 20

  SeriesResistor = 10000
  ThermistorNom  = 10000
  TemperatureNom = 25
  BCoefficient   = 3950


VAR
   Long Channel0
   Long Channel1
   Long Channel2

OBJ

  COMM  : "FullDuplexSerial"
  MATH  : "Float32"                ' Float Math
  M     : "FloatStringNew"         ' Float Math
  ADC   : "MCP3208"                ' 8 Channel 12-Bit ADC
  PST   : "Parallax Serial Terminal"
   
PUB Start
  DIRA[CLK] := 1
  DIRA[CS] := 1
  PST.Start(9600)
  Math.Start                   
  Comm.Start(ImpRx,ImpTx,0,9600)
  ADC.Start(Data,Clk,CS,255)
  'M.SetPrecision(4)
  waitcnt(clkfreq + cnt)
  Main

PUB Main |TMP
  dira[3] := 1
  Repeat
    !outa[3]
    GetTemp
    Repeat Until Comm.RX == $21 'Waits for "!" from Electric Imp.
    waitcnt(10000 + CNT)
    Comm.DEC(Channel0)
    Comm.TX($2C) 'Comma 
    Comm.DEC(Channel1)
    Comm.TX($2C) 'Comma
    Comm.DEC(Channel2)
    Comm.TX($2C) 'Comma
    Comm.TX($13) 'Carriage Return

PUB GetTemp
    Channel0 := ADC.IN(0)
    Channel1 := ADC.IN(1)
    Channel2 := ADC.IN(2)
    PST.DEC(Channel0)
    PST.NewLine
    PST.DEC(Channel1)
    PST.NewLine
    PST.DEC(Channel2)
    PST.NewLine

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
