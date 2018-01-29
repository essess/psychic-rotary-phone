; -----------------------------------------------------------------------------
; Copyright (c) Sean Stasiak. All rights reserved.
; Developed by: Sean Stasiak <sstasiak@protonmail.com>
; Refer to license terms in LICENSE; In the absence of such a file, contact
; me at the above email address and I can provide you with one.
; -----------------------------------------------------------------------------

#CHUNK = (1024*1024*1)

If OpenConsole()
  cnt.q   = 0
  If OpenSerialPort(0, "COM10", 115200, #PB_SerialPort_NoParity, 8, 1, #PB_SerialPort_NoHandshake, 1024, 1024)
    PrintN("Sending:")

    While Inkey() = ""          ; while nothing pressed ...
      If AvailableSerialPortOutput(0) = 0   ; this seems to always return 0
        bytes.q = WriteSerialPortString(0, LSet(Hex(ElapsedMilliseconds(),#PB_Quad),1022,"0")+#CRLF$, #PB_Ascii)
        If bytes <> 1024
          Print("[WRITE FAIL: "+bytes+" bytes]")
        EndIf
        cnt + bytes
        If cnt % #CHUNK = 0  ; dot per chunk
          Print(".")
        EndIf
      Else
        Print("[FULL]") : Delay(100)
      EndIf
    Wend
  EndIf
EndIf