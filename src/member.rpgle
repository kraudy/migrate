
      //Hello
      //https://www.code400.com/inside.php?category=API
      
     h NoMain

      /INCLUDE './headers/member.rpgle'

        Dcl-ds PgmInfo psds;
          xPgmName    char(10)    pos(1);
          xParms      packed(3:0) pos(37);
          xMsgID      char(7)     pos(40);
          xJobName    char(10)    pos(244);
          xUserId     char(10)    pos(254);
          xJobNumber  packed(6:0) pos(264);
        End-ds;
      *
      * constants
      *
        dcl-c Q   const('''');
        dcl-c Up  const('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
        dcl-c Low const('abcdefghijklmnopqrstuvwxyz');
      *
      *  Field Definitions.
      *
        dcl-s AllMembers    char(10) inz('*ALL');
        dcl-s ApiFile       char(10);
        dcl-s ApiLibrary    char(10);
        dcl-s ApiMember     char(10);
        dcl-s bOvr          char(1) inz('0');
        dcl-s FileLib       char(20);
        dcl-s Format        char(8);
        dcl-s MemberName    char(10);
        dcl-s nBufLen       int(10);
        dcl-s ObjectLib     char(10);
        dcl-s OutData       char(30);
        dcl-s ReceiverLen   int(10) inz(100);
        dcl-s SpaceVal      char(1) inz(*BLANKS);
        dcl-s SpaceAuth     char(10) inz('*CHANGE');
        dcl-s SpaceText     char(50) inz(*BLANKS);
        dcl-s SpaceRepl     char(10) inz('*YES');
        dcl-s SpaceAttr     char(10) inz(*BLANKS);
        dcl-s UseScreen     ind;
        dcl-s UserSpaceOut  char(20);
      *
      * QUSRMBRD API return Struture
      * ============================
        dcl-ds Mbrd0100 inz;
          nBytesRtn     int(10);
          nBytesAval    int(10);
          DBXLIB        char(10);
          DBXFIL        char(10);
          MbrName       char(10);
          FileAttr      char(10);
          SrcType       char(10);
          dtCrtDate     char(13);
          dtLstChg      char(13);
          MbrText       char(50);
          bIsSource     char(1);
          RmtFile       char(1);
          LglPhyFile    char(1);
          ODPSharing    char(1);
          filler2       char(2);
          RecCount      int(10);
          DltRecCnt     int(10);
          DataSpaceSz   int(10);
          AccpthSz      int(10);
          NbrBasedOnMbr int(10);
        end-ds;
      *
      * Create userspace datastructure
      *
        dcl-ds stuff;
          StartPosit  int(10);
          StartLen    int(10);
          SpaceLen    int(10);
          ReceiveLen  int(10);
          MessageKey  int(10);
          MsgDtaLen   int(10);
          MsgQueNbr   int(10);
        end-ds;
      *
      * Date structure for retriving userspace info
      *
        dcl-ds InputDs;
          UserSpace   char(20) pos(1);
          SpaceName   char(10) pos(1);
          SpaceLib    char(10) pos(11);
          InpFileLib  char(20) pos(29);
          InpFFilNam  char(10) pos(29);
          InpFFilLib  char(10) pos(39);
          InpRcdFmt   char(10) pos(49);
        end-ds;
      *
      *  Data structure for the retrieve user space command
      *
        dcl-ds GENDS;
          Filler3     char(116);
          OffsetHdr   int(10);
          SizeHeader  int(10);
          OffsetList  int(10);
          Filler4     char(4);
          NbrInList   int(10);
          SizeEntry   int(10);
        end-ds;
      *
      * Datastructure for retrieving elements from userspace
      *
        dcl-ds HeaderDs;
          OutFileNam  char(10)  pos(1);
          OutLibName  char(10)  pos(11);
          OutType     char(5)   pos(21);
          OutFormat   char(10)  pos(31);
          RecordLen   int(5)    pos(41);
        end-ds;
      *
      * Retrive object description
      *
        dcl-ds RtvObjInfo;
          RoBytRtn    int(10);
          RoBytAvl    int(10);
          RoObjNam    char(10);
          RoObjLib    char(10);
          RoObjTypRt  char(10);
          RoObjLibRt  char(10);
          RoObjASP    int(10);
          RoObjOwn    char(10);
          RoObjDmn    char(2);
          RoObjCrtDts char(7);
          RoObjCrtTim char(6);
          RoObjChgDts char(7);
          RoObjChgTim char(6);
          RoExtAtr    char(10);
          RoTxtDsc    char(50);
          RoSrcF      char(10);
          RoSrcLib    char(10);
          RoSrcMbr    char(10);
        end-ds;
      

      **********************************

       dcl-proc Mbrs_List export;
        dcl-pi Mbrs_List int(10);
          pLibrary char(10) const;
          pObject   char(10) const;
        end-pi;

        FileLib = pObject + pLibrary;

        exsr xQUSCRTUS;
      **
        MemberName = '*ALL';
        Format = 'MBRL0200';
        exsr xQUSLMBR;
      **
      **  Read back the members
      **
        StartPosit = 1;
        StartLen = 140;
      **
      ** First call to get data offsets(start)
      **
     c                   call(e)   'QUSRTVUS'
     c                   parm                    UserSpaceOut
     c                   parm                    StartPosit
     c                   parm                    StartLen
     c                   parm                    GENDS
     c                   parm                    ErrorDs
      **
      ** Then call to get number of entries
      **
        StartPosit = OffsetHdr + 1;
        StartLen = SizeHeader;
      **
     c                   call(e)   'QUSRTVUS'
     c                   parm                    UserSpaceOut
     c                   parm                    StartPosit
     c                   parm                    StartLen
     c                   parm                    HeaderDs
     c                   parm                    ErrorDs
      **
        StartPosit = OffsetList + 1;
        StartLen = SizeEntry;

        return NbrInList;

      **========================================================================
      ** xQUSCRTUS - API to create user space
      **========================================================================
        begsr xQUSCRTUS;
     **
     ** Create a user space named ListMember in QTEMP.
     **
          BytesPrv = 116;
          SpaceName = 'MEMBERS';
          SpaceLib = 'QTEMP';
     **
     ** Create the user space
     **
     c                   call(e)   'QUSCRTUS'
     c                   parm      UserSpace     UserSpaceOut
     c                   parm                    SpaceAttr
     c                   parm      4096          SpaceLen
     c                   parm                    SpaceVal
     c                   parm                    SpaceAuth
     c                   parm                    SpaceText
     c                   parm                    SpaceRepl
     c                   parm                    ErrorDs
     **
        endsr;

        //begsr xQUSCRTUS;

        //  // Create the user space
        //  //callp(e) 'QUSCRTUS' (UserSpaceOut: SpaceAttr: 4096: SpaceVal: SpaceAuth: SpaceText: 
        //  //SpaceRepl: ErrorDs);

        //  //CrtUsrSpace(UserSpaceOut: SpaceAttr: 4096: SpaceVal: 
        //  //            SpaceAuth: SpaceText: SpaceRepl: ErrorDs);
        //  CrtUsrSpace(UserSpaceOut: '': 1: x'00': 
        //              '*CHANGE': SpaceText: '*YES': ErrorDs);
        //endsr;

      **========================================================================
      ** xQUSLMBR  - API List all members in a file
      **========================================================================
        begsr xQUSLMBR;
          nBufLen = %size(MbrD0100);

          //callp(e) 'QUSLMBR' (UserSpaceOut: Format: FileLib: AllMembers: 
          //bOvr: ErrorDs);
          RtvMberList(UserSpaceOut: Format: FileLib: AllMembers: 
                      bOvr: ErrorDs);
        endsr;

      * AQUI TERMINA EL PROCEDIMIENTO PRINCIPAL
       end-proc;


      **********************************
        dcl-proc Mbrs_Next export;
          dcl-pi Mbrs_Next likeDS(ListDS);
          end-pi;

          RtvUserSpace (UserSpaceOut: StartPosit: StartLen: ListDs: ErrorDs);

          ApiMember = LmMember;

          // Increment the start position for the next entry
          StartPosit += SizeEntry;

          return ListDS;

        end-proc;