; -----------------------------------------------------------------------------
; Copyright (c) Sean Stasiak. All rights reserved.
; Developed by: Sean Stasiak <sstasiak@protonmail.com>
; Refer to license terms in LICENSE; In the absence of such a file, contact
; me at the above email address and I can provide you with one.
; -----------------------------------------------------------------------------

EnableExplicit

#ONEKB     = (1*1024)
#ONEMB     = (#ONEKB*1024)
#CHUNKSIZE = (#ONEKB*64)

#UDPPORT = 6100

Structure counts_t  ; counters
  chunkcntout.q
  chunkcntin.q
  netretries.q
  nondataevt.q
EndStructure

Global counts.counts_t, m = CreateMutex() ; todo : wipe counts

Procedure.q get_chunkcntout()
  assert( m ) : LockMutex( m )
  Protected value.q = counts\chunkcntout
  UnlockMutex( m )
  ProcedureReturn value
EndProcedure

Procedure.q get_chunkcntin()
  assert( m ) : LockMutex( m )
  Protected value.q = counts\chunkcntin
  UnlockMutex( m )
  ProcedureReturn value
EndProcedure

Procedure.q get_netretries()
  assert( m ) : LockMutex( m )
  Protected value.q = counts\netretries
  UnlockMutex( m )
  ProcedureReturn value
EndProcedure

Procedure.q get_nondataevt()
  assert( m ) : LockMutex( m )
  Protected value.q = counts\nondataevt
  UnlockMutex( m )
  ProcedureReturn value
EndProcedure

Procedure inc_chunkcntout()
  assert( m ) : LockMutex( m )
  counts\chunkcntout + 1
  UnlockMutex( m )
EndProcedure

Procedure inc_chunkcntin()
  assert( m ) : LockMutex( m )
  counts\chunkcntin + 1
  UnlockMutex( m )
EndProcedure

Procedure inc_netretries()
  assert( m ) : LockMutex( m )
  counts\netretries + 1
  UnlockMutex( m )
EndProcedure

Procedure inc_nondataevt()
  assert( m ) : LockMutex( m )
  counts\nondataevt + 1
  UnlockMutex( m )
EndProcedure

Global start.q = ElapsedMilliseconds()
Procedure.s uptime( )
  Protected deltasec.q = (ElapsedMilliseconds()-start)/1000
  Protected seconds.q  = (deltasec/1)    % 60
  Protected minutes.q  = (deltasec/60)   % 60
  Protected hours.q    = (deltasec/3600) % 24
  Protected days.q     = (deltasec/86400)
  ProcedureReturn      Str(days)          +":"+
                  RSet(Str(hours),2,"0")  +":"+
                  RSet(Str(minutes),2,"0")+":"+
                  RSet(Str(seconds),2,"0")
EndProcedure

Declare test()
Procedure main()
  Protected isopen = OpenConsole( GetFilePart(ProgramFilename(),
                                              #PB_FileSystem_NoExtension) )
  assert( isopen )
  PrintN( "#CHUNKSIZE : "+StrD(#CHUNKSIZE/#ONEKB,1)+" KB - Press any key To stop (Or Ctrl+C)." )
  test()
EndProcedure