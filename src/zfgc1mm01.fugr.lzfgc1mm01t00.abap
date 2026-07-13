*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZMVA1MM0011.....................................*
TABLES: ZMVA1MM0011, *ZMVA1MM0011. "view work areas
CONTROLS: TCTRL_ZMVA1MM0011
TYPE TABLEVIEW USING SCREEN '0002'.
DATA: BEGIN OF STATUS_ZMVA1MM0011. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZMVA1MM0011.
* Table for entries selected to show on screen
DATA: BEGIN OF ZMVA1MM0011_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZMVA1MM0011.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZMVA1MM0011_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZMVA1MM0011_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZMVA1MM0011.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZMVA1MM0011_TOTAL.

*...processing: ZMVC1MM0001.....................................*
TABLES: ZMVC1MM0001, *ZMVC1MM0001. "view work areas
CONTROLS: TCTRL_ZMVC1MM0001
TYPE TABLEVIEW USING SCREEN '0001'.
DATA: BEGIN OF STATUS_ZMVC1MM0001. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZMVC1MM0001.
* Table for entries selected to show on screen
DATA: BEGIN OF ZMVC1MM0001_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZMVC1MM0001.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZMVC1MM0001_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZMVC1MM0001_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZMVC1MM0001.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZMVC1MM0001_TOTAL.

*.........table declarations:.................................*
TABLES: ZTC1MM0001                     .
TABLES: ZTC1MM0005                     .
