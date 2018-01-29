; -----------------------------------------------------------------------------
; Copyright (c) Sean Stasiak. All rights reserved.
; Developed by: Sean Stasiak <sstasiak@protonmail.com>
; Refer to license terms in LICENSE; In the absence of such a file, contact
; me at the above email address and I can provide you with one.
; -----------------------------------------------------------------------------

EnableExplicit
XIncludeFile "assert.pbi"
XIncludeFile "test.pbi"

#PORTSTR = "COM11"

Procedure test()
  Protected retval = 0
  Protected *pbuff = AllocateMemory( #CHUNKSIZE ) : assert( *pbuff )
  Protected sp = OpenSerialPort( #PB_Any, #PORTSTR, 115200, #PB_SerialPort_NoParity,
                                 8, 1, #PB_SerialPort_NoHandshake, #CHUNKSIZE, #CHUNKSIZE )
  assert( sp )

  ; quick hack to get minimum up ---
  Repeat
    retval =  ReadSerialPortData( sp, *pbuff, #CHUNKSIZE ) : assert( retval = #CHUNKSIZE )
    retval = WriteSerialPortData( sp, *pbuff, #CHUNKSIZE ) : assert( retval = #CHUNKSIZE )
  Until Inkey() <> ""
  ; --------------------------------

EndProcedure

main()