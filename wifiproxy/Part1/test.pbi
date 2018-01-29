; -----------------------------------------------------------------------------
; Copyright (c) Sean Stasiak. All rights reserved.
; Developed by: Sean Stasiak <sstasiak@protonmail.com>
; Refer to license terms in LICENSE; In the absence of such a file, contact
; me at the above email address and I can provide you with one.
; -----------------------------------------------------------------------------

EnableExplicit

#ONEKB           = (1*1024)
#ONEMB           = (#ONEKB*1024)
#CHUNKSIZE       = (#ONEKB*1)

Declare test( )

Procedure main()
  Protected isopen = OpenConsole( GetFilePart(ProgramFilename(),
                                              #PB_FileSystem_NoExtension) )
  assert( isopen )
  PrintN( "#CHUNKSIZE : "+StrD(#CHUNKSIZE/#ONEKB,1)+" KB - Press any key To stop (Or Ctrl+C)." )
  test()
EndProcedure