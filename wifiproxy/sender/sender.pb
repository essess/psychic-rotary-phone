; -----------------------------------------------------------------------------
; Copyright (c) Sean Stasiak. All rights reserved.
; Developed by: Sean Stasiak <sstasiak@protonmail.com>
; Refer to license terms in LICENSE; In the absence of such a file, contact
; me at the above email address and I can provide you with one.
; -----------------------------------------------------------------------------

EnableExplicit
XIncludeFile "assert.pbi"
XIncludeFile "test.pbi"

Structure targs_t  ; thread args
  connection.q
EndStructure

Procedure loop( *ptargs.targs_t )
  assert( *ptargs )
  #BLKSIZE = 1024
  Protected *pbuffer = AllocateMemory( #BLKSIZE ) : assert( *pbuffer )

  Repeat
    Protected slen = SendNetworkData( *ptargs\connection, *pbuffer, #BLKSIZE )
    If( (slen = -1) Or (slen <> #BLKSIZE) )
      inc_netretries()
      Delay( 5 )
    Else
      inc_chunkcntout()
    EndIf
  ForEver
EndProcedure

Procedure test()
  Protected targs.targs_t, result
  Print( "Initilizing: network, " )
  result = InitNetwork() : assert( result )

  Print( "udp junk sender"+#CRLF$ )
  targs\connection = OpenNetworkConnection( "192.168.200.100", #UDPPORT, #PB_Network_UDP, 1000, "192.168.200.139", #UDPPORT )
  assert( targs\connection )

  Protected t = CreateThread( @loop(), @targs ) : assert( t )

  Repeat
    Print( ~"\r" )
    Print( "[Uptime: "+uptime()+"] " )
    Print( "[NonData Events: "+Str(get_nondataevt())+"] " )
    Print( "[chunkcnt: "+Str(get_chunkcntout())+"] " )
    Print( "[wait: "+Str(get_netretries())+"] " )
    If IsThread(t) = 0 : Print( " [THREAD DEAD!]" ) : EndIf
    Delay( 200 )
  Until Inkey() <> ""

  KillThread( t )
EndProcedure

main()