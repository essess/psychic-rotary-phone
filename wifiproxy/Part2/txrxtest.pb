; -----------------------------------------------------------------------------
; Copyright (c) Sean Stasiak. All rights reserved.
; Developed by: Sean Stasiak <sstasiak@protonmail.com>
; Refer to license terms in LICENSE; In the absence of such a file, contact
; me at the above email address and I can provide you with one.
; -----------------------------------------------------------------------------

EnableExplicit
XIncludeFile "assert.pbi"
XIncludeFile "test.pbi"

#PORTSTR = "COM10" ; this app behaves as a TunerStudio stub

Structure targs_t  ; thread args
  serport.q
EndStructure

Global stats.s = "", sm = CreateMutex()

Procedure set_stats( str.s )
  assert( sm ) : LockMutex( sm )
  stats = str
  UnlockMutex( sm )
EndProcedure

Procedure.s get_stats()
  assert( sm ) : LockMutex( sm )
  Protected value.s = stats
  UnlockMutex( sm )
  ProcedureReturn value
EndProcedure

Procedure thread( *ptarg.targs_t )
  assert( *ptarg )
  Protected *psendbuff = AllocateMemory( #CHUNKSIZE ) : assert( *psendbuff )
  Protected *precvbuff = AllocateMemory( #CHUNKSIZE ) : assert( *precvbuff )
  Protected bytes = 0

  Protected prev.q = ElapsedMilliseconds()
  Repeat
    #LOOPS = (1000)
    Protected i.q
    For i = 1 To #LOOPS
      RandomData( *psendbuff, #CHUNKSIZE )
      bytes = WriteSerialPortData( *ptarg\serport, *psendbuff, #CHUNKSIZE ) : assert( bytes = #CHUNKSIZE )
      inc_chunkcntout()
      bytes = ReadSerialPortData( *ptarg\serport, *precvbuff, #CHUNKSIZE ) : assert( bytes = #CHUNKSIZE )
      inc_chunkcntin()
      assert( CompareMemory( *psendbuff, *precvbuff, #CHUNKSIZE ) <> 0 )
      RandomData( *psendbuff, #CHUNKSIZE )
    Next i
    Protected curr.q = ElapsedMilliseconds(), delta.d = (curr-prev)/#LOOPS ; correct delta for loops!
    If delta > 0.0
      ; correct for 2x #CHUNKSIZE because each loop does a rd AND wr
      set_stats( "["+RSet(StrD(delta,2),6)+"ms]  ["+StrD(((#CHUNKSIZE*2)/((delta)/1000))/#ONEMB,1)+" MB/s]")
    EndIf
    prev = curr
  ForEver

EndProcedure

Procedure test()

  Protected targs.targs_t
  Print( "Initilizing: virtual com port, " )
  targs\serport = OpenSerialPort( #PB_Any, #PORTSTR, 115200, #PB_SerialPort_NoParity, 8, 1,
                                  #PB_SerialPort_NoHandshake, #CHUNKSIZE, #CHUNKSIZE )
  assert( targs\serport )

  Print( "I/O thread"+#CRLF$ )
  Protected t = CreateThread( @thread(), @targs ) : assert( t )

  Repeat
    Print( ~"\r" )
    Print( "[Uptime: "+uptime()+"] " )
    Print( "[chunkcntout: "+Str(get_chunkcntout())+"] " )
    Print( "[chunkcntin: "+Str(get_chunkcntin())+"] " )
    Print( get_stats()+" " )
    If IsThread(t)  = 0 : Print( "[I/O THREAD DEAD!] " ) : EndIf
    Delay( 200 )
  Until Inkey() <> ""

  KillThread( t )
EndProcedure

main()