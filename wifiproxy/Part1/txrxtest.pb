; -----------------------------------------------------------------------------
; Copyright (c) Sean Stasiak. All rights reserved.
; Developed by: Sean Stasiak <sstasiak@protonmail.com>
; Refer to license terms in LICENSE; In the absence of such a file, contact
; me at the above email address and I can provide you with one.
; -----------------------------------------------------------------------------

EnableExplicit
XIncludeFile "assert.pbi"
XIncludeFile "test.pbi"

#PORTSTR = "COM10"

Procedure test()
  Protected retval = 0
  Protected *psendbuff = AllocateMemory( #CHUNKSIZE ) : assert( *psendbuff )
  Protected *precvbuff = AllocateMemory( #CHUNKSIZE ) : assert( *precvbuff )
  Protected sp = OpenSerialPort( #PB_Any, #PORTSTR, 115200, #PB_SerialPort_NoParity,
                                 8, 1, #PB_SerialPort_NoHandshake, #CHUNKSIZE, #CHUNKSIZE )
  assert( sp )

  ; quick hack to get minimum up ---
  Protected prev.q = ElapsedMilliseconds()
  Repeat
    #LOOPS = (10000)
    Protected i.q
    For i = 1 To #LOOPS
      RandomData( *psendbuff, #CHUNKSIZE )
      retval = WriteSerialPortData( sp, *psendbuff, #CHUNKSIZE ) : assert( retval = #CHUNKSIZE )
      retval =  ReadSerialPortData( sp, *precvbuff, #CHUNKSIZE ) : assert( retval = #CHUNKSIZE )
      retval = CompareMemory( *psendbuff, *precvbuff, #CHUNKSIZE ) : assert( retval <> 0 )
      RandomData( *psendbuff, #CHUNKSIZE )
    Next i
    Protected curr.q = ElapsedMilliseconds(), delta.d = (curr-prev)/#LOOPS ; correct delta for loops!
    If delta > 0.0
      ; correct for 2x #CHUNKSIZE because each loop does a rd AND wr
      Print(~"\r["+RSet(StrD(delta,2),6)+"ms]  ["+StrD(((#CHUNKSIZE*2)/((delta)/1000))/#ONEMB,1)+" MB/s]")
    EndIf
    prev = curr
  Until Inkey() <> ""
  ; --------------------------------

EndProcedure

main()