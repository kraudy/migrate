        
        /INCLUDE './headers/utils.rpgle'
        /INCLUDE './headers/std.rpgle'
        /INCLUDE './headers/library.rpgle'
        
        Dcl-Pi MIGSRCPF;
          pLibrary Char(10);
          pSRCPF   Char(10);
          pOutDir  Char(128);
          pCCSID   Char(10);
        End-Pi;
        
        Dcl-S ASP_Prefix Char(10);
        Dcl-S CmdStr  Varchar(256);
        Dcl-S DirName Varchar(128);
        Dcl-S MbrCnt  Int(5);
        Dcl-S IterNum Int(5);

        //TODO: Put this in a ds
        Dcl-s LmMember Varchar(10) inz(*blanks);
        Dcl-s LmType Varchar(10) inz(*blanks);

        DirName = %TrimR(pOutDir) + '/' +  %TrimR(Utils_Lower(pSRCPF)) + '/';
        If (system('MKDIR DIR(''' + DirName + ''')') <> 0);
          
          Dsply ('Directory may already exist.');
        
        Endif;

        Exec SQL 
          Select count(*) Into :MbrCnt
          From QSYS2.SYSPARTITIONSTAT
          Where SYSTEM_TABLE_SCHEMA = :pLibrary
            And SYSTEM_TABLE_NAME = :pSRCPF
          ;
        Dsply ('Member count: ' + %Char(MbrCnt));
        
        // Preemptive close
        Exec SQL Close membersCursor;

        // List of members
        Exec SQL
          Declare membersCursor Insensitive Cursor For 
            Select Lower(SYSTEM_TABLE_MEMBER) as Member, Lower(SOURCE_TYPE) as Type
            From QSYS2.SYSPARTITIONSTAT
            Where SYSTEM_TABLE_SCHEMA = :pLibrary
              And SYSTEM_TABLE_NAME = :pSRCPF
          For Read Only
        ;

        Exec SQL Open membersCursor;
        If SqlCode <> *zeros;
          snd-msg *info 'Error at cursor open';
        endif;

        Exec SQL Fetch membersCursor Into :LmMember, :LmType;
        If SqlCode <> *zeros;
          snd-msg *info 'Error at initial fetch';
        endif;

        // IFS migration cycle
        DoU SqlCode <> *zeros; 
          ASP_Prefix = GetObjAsp('*LIBL':pLibrary:'*LIB');
          If ASP_Prefix <> *BLANKS;
            ASP_Prefix = '/' + ASP_Prefix;
          Endif;

          //Attempt to copy member to streamfile
          //Dsply ('   ' + %TrimR(LmMember) + '.' + %TrimR(LmType));
          CmdStr = 'CPYTOSTMF FROMMBR('''
                   + %TrimR(ASP_Prefix)
                   + '/QSYS.lib/'
                   + %TrimR(pLibrary) + '.lib/'
                   + %TrimR(pSRCPF) + '.file/'
                   + %TrimR(LmMember) + '.mbr'') '
                 + 'TOSTMF('''
                   + DirName + %TrimR(LmMember) + '.'
                    + %TrimR(LmType) + ''') '
                 + 'STMFOPT(*REPLACE) STMFCCSID(' + %TrimR(pCCSID) 
                 + ') ENDLINFMT(*LF)';
                 
          //If fails, display error
          If (system(CmdStr) = 1);
            Dsply ('Failed to copy ' 
                   + %TrimR(LmMember) + '.' + %TrimR(LmType));
          Endif;

          // Next iteration
          Exec SQL Fetch membersCursor Into :LmMember, :LmType;
        Enddo;
        
        Exec SQL Close membersCursor;

        Dsply ('Finished change.');
        
        Return;
