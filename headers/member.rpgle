
      **
      ** List the members
      **
      //TODO: Make ListDs a template
     d ListDs          DS
     d  LmMember                     10
     d  LmType                       10
     d  LmCreationDt                  7
     d  LmCreationTm                  6
     d  LmLastChgDt                   7
     d  LmLastChgTm                   6
     d  LmDescription                50

     D Mbrs_List       PR            10i 0
     D    pLibrary                   10A   Const
     D    pObject                    10A   Const

     D Mbrs_Next       PR                  LikeDS(ListDs)

        dcl-ds Errords;
          BytesPrv    int(5)    inz(%size(errords)) pos(1);
          BytesAvl    int(5)    inz(0)              pos(6);
          MessageId   char(7)                       pos(10);
          ERRxxx      char(1)                       pos(17);
          MessageDta  char(240)                     pos(18);
        end-ds;


        dcl-pr RtvUserSpace extpgm('QUSRTVUS') ;
          *n char(20) const ;   // Name
          *n int(10) const ;    // Starting position
          *n int(10) const ;    // Length
          *n LikeDS(ListDS) ;        // Retrieved data
          *n LikeDS(Errords) options(*varsize:*nopass) ;  // Error feedback
        end-pr;

        dcl-pr RtvMberList extpgm('QUSLMBR') ;
          *n char(20) const ;   // Name
          *n char(8) const ;    
          *n char(20) const ;   
          *n char(10) ;       
          *n char(1) ; 
          *n LikeDS(Errords) options(*varsize:*nopass) ; 
        end-pr;
