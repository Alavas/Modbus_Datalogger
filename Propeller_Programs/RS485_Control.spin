
CON

  _clkmode        = xtal1 + pll16x           ' Feedback and PLL multiplier
  _xinfreq        = 5_000_000                ' External oscillator = 5 MHz
  Baud            = 9_600
  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq

VAR
   Long Transmit
   byte outbuffer[25]   
   byte rawbuffer[25]   
   byte inbuffer[25]
   byte testbuffer[25]
   Long idx
   Long RChar
   Long CRCval


OBJ

  COMM  : "Parallax Serial Terminal"
  RS    : "Parallax Serial Terminal_Mod"
   
PUB Start  

  Comm.Start(19_200)
  RS.StartRXTX(4,5,0,9600)
  dira[5]~~ ''TX and RTS lines.
  dira[3]~~
  dira[4]~      ''RX Line
  byte[outbuffer][0] := $06 'Number of bytes
  byte[outbuffer][1] := $01 'Device Address
  byte[outbuffer][2] := $06 'Write Command
  byte[outbuffer][3] := $00 'Start Address High Byte
  ''byte[outbuffer][4] := $64 'Start Address Low Byte
  byte[outbuffer][5] := $00 'Quantity High Byte
  ''byte[outbuffer][6] := $01 'Quantity Low Byte
  Comm.Clear
  SendReceive
  
PUB SendReceive | ExeceptionCode, FrameEndCountOffset, FrameEndFlag,i,FrameEndTgt,FrameCheck

  FrameEndCountOffset := (CLK_FREQ / Baud * 11 * 35 / 10) ' you can't multiply by a decimal so use integer and then divide by 10
                                                          ' * 35 / 10 == *3.5
  FrameCheck := False
  bytefill(@Inbuffer, 0, 25)
  bytefill(@RawBuffer, 0, 25)
  bytefill(@testbuffer,0,25)
  idx := 1  
  Repeat
    Comm.NewLine
    Comm.Str(string("Register?",13))
    byte[outbuffer][4] := Comm.DECIN
    byte[outbuffer][4] :=     byte[outbuffer][4] - 1
    Comm.NewLine
    Comm.Str(string("High Value?",13))
    byte[outbuffer][5] := Comm.DECIN
    Comm.NewLine
    Comm.Str(string("Low Value?",13))
    byte[outbuffer][6] := Comm.DECIN
    Comm.BIN(byte[outbuffer][6],8)
    GenCRC

    outa[3]~~
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
    outa[3]~

    RS.rxflush
    repeat
      RChar := RS.rxcheck
      if RChar <> -1                                    'A new char has arrived
        rawbuffer[idx++] := RChar                       'so put it in the buffer @ position idx and increment idx
        FrameEndTgt := cnt + FrameEndCountOffset        ' we know that we have got a frame time timing
        FrameCheck := True
      if ((cnt >= FrameEndTgt) AND FrameCheck )OR (idx > 24)
        bytefill (@Inbuffer, 0, 25)
        bytemove (@InBuffer,@RawBuffer,25)              'Copy Incomming Raw Buffer to InBuffer
        InBuffer[0] := idx-1
        bytefill (@RawBuffer, 0, 25)                    'Clear Raw Buffer
        RChar := RS.rxcheck
        repeat i from 0 to (idx-1)
          Comm.NewLine
          Comm.BIN(inbuffer[i],8)
          Comm.Str(string(" Test HEX = ")) 
          Comm.HEX(inbuffer[i],2)
        SendReceive

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

PUB Display

    Comm.BIN(byte[outbuffer][0],8)
    Comm.Str(string(" Hex = "))
    Comm.HEX(byte[outbuffer][0],2)
    Comm.NewLine
    Comm.BIN(byte[outbuffer][1],8)
    Comm.Str(string(" Hex = "))
    Comm.HEX(byte[outbuffer][1],2)
    Comm.NewLine
    Comm.BIN(byte[outbuffer][2],8)
    Comm.Str(string(" Hex = "))
    Comm.HEX(byte[outbuffer][2],2)
    Comm.NewLine
    Comm.BIN(byte[outbuffer][3],8)
    Comm.Str(string(" Hex = "))
    Comm.HEX(byte[outbuffer][3],2)
    Comm.NewLine
    Comm.BIN(byte[outbuffer][4],8)
    Comm.Str(string(" Hex = "))
    Comm.HEX(byte[outbuffer][4],2)
    Comm.NewLine
    Comm.BIN(byte[outbuffer][5],8)
    Comm.Str(string(" Hex = "))
    Comm.HEX(byte[outbuffer][5],2)
    Comm.NewLine
    Comm.BIN(byte[outbuffer][6],8)
    Comm.Str(string(" Hex = "))
    Comm.HEX(byte[outbuffer][6],2)
    Comm.NewLine
    Comm.BIN(byte[@CRCVal][0],8)
    Comm.Str(string(" Hex = "))
    Comm.HEX(byte[@CRCVal][0],2)
    Comm.NewLine
    Comm.BIN(byte[@CRCVal][1],8)
    Comm.Str(string(" Hex = "))
    Comm.HEX(byte[@CRCVal][1],2)

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
