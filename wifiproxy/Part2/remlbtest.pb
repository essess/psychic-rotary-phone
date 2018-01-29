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
  server.q
EndStructure

Procedure loop( *ptargs.targs_t )
  assert( *ptargs )
  #BLKSIZE = #ONEKB*128
  Protected *pbuffer = AllocateMemory( #BLKSIZE ) : assert( *pbuffer )

  Repeat
    Select NetworkServerEvent( *ptargs\server )
      Case #PB_NetworkEvent_Data
        Protected rlen = ReceiveNetworkData( EventClient(), *pbuffer, #BLKSIZE )
        assert( rlen < #BLKSIZE ) : assert( rlen > 0 )
        Protected slen = SendNetworkData( EventClient(), *pbuffer, rlen )
        assert( slen <> -1 ) : assert( slen = rlen )
        inc_chunkcntout()
      Case #PB_NetworkEvent_None
        ; ignore
      Default
        inc_nondataevt()
    EndSelect
  ForEver
EndProcedure

Procedure test()
  Protected targs.targs_t, result
  Print( "Initilizing: network, " )
  result = InitNetwork() : assert( result )

  Print( "udp loopback server"+#CRLF$ ) ; in purebasic nomenclature, this is considered the server
  targs\server = CreateNetworkServer( #PB_Any, #UDPPORT, #PB_Network_UDP )
  assert( targs\server )

  Protected t = CreateThread( @loop(), @targs ) : assert( t )

  Repeat
    Print( ~"\r" )
    Print( "[Uptime: "+uptime()+"] " )
    Print( "[NonData Events: "+Str(get_nondataevt())+"] " )
    Print( "[chunkcnt: "+Str(get_chunkcntout())+"] " )
    If IsThread(t) = 0 : Print( " [LOOPBACK THREAD DEAD!]" ) : EndIf
    Delay( 200 )
  Until Inkey() <> ""

  KillThread( t )
EndProcedure

main()