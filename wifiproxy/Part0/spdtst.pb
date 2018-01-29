; -----------------------------------------------------------------------------
; Copyright (c) Sean Stasiak. All rights reserved.
; Developed by: Sean Stasiak <sstasiak@protonmail.com>
; Refer to license terms in LICENSE; In the absence of such a file, contact
; me at the above email address and I can provide you with one.
; -----------------------------------------------------------------------------

If OpenSerialPort(0, "COM10", 115200, #PB_SerialPort_NoParity, 8, 1, #PB_SerialPort_NoHandshake, 1024, 1024)
    Debug "Success"
Else
    Debug "Failed"
EndIf

If OpenSerialPort(1, "COM11", 115200, #PB_SerialPort_NoParity, 8, 1, #PB_SerialPort_NoHandshake, 2048, 2048)
    Debug "Success"
Else
    Debug "Failed"
EndIf

*in_buff  = AllocateMemory(1024)
*out_buff = AllocateMemory(1024)

; push some data and time it
StartTime.q = ElapsedMilliseconds()

; push 1k * n times
For i = 1 To (1024*100)            ; 100MB total
  RandomData(*in_buff, 1024)

  If(WriteSerialPortData(0,*in_buff,1024) <> 1024)
    Debug "Write error"
  EndIf

  While(AvailableSerialPortInput(1) < 1024)
    Debug "Wait!" ; block - but has never happened yet
  Wend

  If(ReadSerialPortData(1,*out_buff,1024) <> 1024)
    Debug "Read Error"
  EndIf

  If(CompareMemory(*in_buff,*out_buff,1024) = 0)
    Debug "Match Fail"
  EndIf
Next i
Debug ElapsedMilliseconds() - StartTime