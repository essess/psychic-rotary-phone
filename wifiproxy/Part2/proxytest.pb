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

Structure targs_t  ; thread args
  serport.q
  client.q
EndStructure

Procedure from_network( *ptargs.targs_t )
  assert( *ptargs )

  #BLKSIZE = #ONEKB*128
  Protected *pbuffer = AllocateMemory( #BLKSIZE ) : assert( *pbuffer )

  Repeat ; pend on network and passthru to serport
    Select NetworkClientEvent( *ptargs\client )
      Case #PB_NetworkEvent_Data
        Protected rlen = ReceiveNetworkData( *ptargs\client, *pbuffer, #BLKSIZE )
        assert( rlen < #BLKSIZE ) : assert( rlen > 0 )
        Protected bytes = WriteSerialPortData( *ptargs\serport, *pbuffer, rlen )
        assert( bytes = rlen )
        inc_chunkcntin()
      Case #PB_NetworkEvent_None
        ; ignore
      Default
        inc_nondataevt()
    EndSelect
  ForEver
EndProcedure

Procedure from_serport( *ptargs.targs_t )
  assert( *ptargs )
  #BLKSIZE = #ONEKB*128
  Protected *pbuffer = AllocateMemory( #BLKSIZE ) : assert( *pbuffer )

  Repeat ; pend on serport and pass thru to network
    Protected bytes = AvailableSerialPortInput( *ptargs\serport )
    assert( bytes <= #BLKSIZE )

    assert( bytes <= 2048 )
    ; TODO if bytes > 2048, need to split it up because udp only allows 2k per send call

    If bytes
      Protected rlen = ReadSerialPortData( *ptargs\serport, *pbuffer, bytes )
      Protected slen = SendNetworkData( *ptargs\client, *pbuffer, rlen )
      assert( slen = rlen )
      inc_chunkcntout()
    EndIf
  ForEver
EndProcedure

Procedure test()
  Protected targs.targs_t, result
  Print( "Initilizing: network, " )
  result = InitNetwork() : assert( result )
  Print( "virtual com port, ")
  targs\serport = OpenSerialPort( #PB_Any, #PORTSTR, 115200, #PB_SerialPort_NoParity, 8, 1,
                                  #PB_SerialPort_NoHandshake, #CHUNKSIZE, #CHUNKSIZE )
  assert( targs\serport )

  Print( "udp to loopback, " ) ; we are the client connection in purebasic terms
  targs\client = OpenNetworkConnection( "localhost", #UDPPORT, #PB_Network_UDP )
  assert( targs\client )

  Print( "network thread, " )
  Protected nt = CreateThread( @from_network(), @targs ) : assert( nt )

  Print( "serial port thread"+#CRLF$ )
  Protected spt = CreateThread( @from_serport(), @targs ) : assert( spt )

  Repeat
    Print( ~"\r" )
    Print( "[Uptime: "+uptime()+"] " )
    Print( "[Send Retries: "+Str(get_netretries())+"] " )
    Print( "[NonData Events: "+Str(get_nondataevt())+"] " )
    Print( "[chunkcntout: "+Str(get_chunkcntout())+"] " )
    Print( "[chunkcntin: "+Str(get_chunkcntin())+"] " )
    If IsThread(spt) = 0 : Print( "[SERPORT THREAD DEAD!] " ) : EndIf
    If IsThread(nt)  = 0 : Print( "[NETWORK THREAD DEAD!] " ) : EndIf
    Delay( 200 )
  Until Inkey() <> ""

  KillThread( nt ) : KillThread( spt )
EndProcedure

main()