; -----------------------------------------------------------------------------
; Copyright (c) Sean Stasiak. All rights reserved.
; Developed by: Sean Stasiak <sstasiak@protonmail.com>
; Refer to license terms in LICENSE; In the absence of such a file, contact
; me at the above email address and I can provide you with one.
; -----------------------------------------------------------------------------

#CHUNK           = (1024*1024*50) ; 50MB
#ONE_TENTH_CHUNK = #CHUNK/10

If OpenConsole()
  *buff   = AllocateMemory(1024)
  cnt.q   = 0
  prev.q  = ElapsedMilliseconds()

  If OpenSerialPort(0, "COM11", 115200, #PB_SerialPort_NoParity, 8, 1, #PB_SerialPort_NoHandshake, 2048, 2048)
    PrintN("Receiving:")
    While Inkey() = ""    ; while nothing pressed ...
      bytes.q = ReadSerialPortData(0, *buff, 1024)
      If bytes <> 1024
        Print("[READ FAIL]")
      EndIf
      cnt + bytes
      If cnt % #ONE_TENTH_CHUNK = 0
        Print(".")
      EndIf
      If cnt % #CHUNK = 0    ;  show xfer rate per chunk
        curr.q = ElapsedMilliseconds()
        Print("["+StrD((#CHUNK/((curr-prev)/1000))/(1024*1024),1)+" MB/s]")
        prev = curr
      EndIf
    Wend
  EndIf
EndIf