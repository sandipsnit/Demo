REM $Header: $
REM dbdrv: sql ~PROD ~PATH ~FILE none none none sqlplus_single &phase=tbm \
REM dbdrv: checkfile:~PROD:~PATH:~FILE
/*===========================================================================*/
REM Copyright (c) 2002, 2008, Oracle. All rights reserved.  
REM
REM CREMDSTYPS.sql - CReate MetaData Services TYPeS
REM
REM This file is needed by APPS to be incorporated in the ARU.  The ARU 
REM contains a mechanism for creating tables, views and indexes (via *.odf file)
REM and for creating pl/sql packages (via *.pls) files, but no mechanism for
REM creating TYPEs.  As such, this file is needed to create any database objects
REM which are not handled by the *.odf files.
REM
REM MODIFIED    (MM/DD/YY)
REM vyerrama     04/11/08   - #(6957982) Increased the size of the vararray 
REM                           field
REM rnanda       08/31/06   - Adding comment
REM rnanda       08/14/06   - RCU integration
REM enewman      12/20/04   - enewman_support_generic_xml
REM enewman      12/20/04  -  Renamed from jdrmdstp.sql
REM enewman      06/06/02  -  Modifications to follow apps coding standards
REM enewman      06/03/02  -  Creation.
REM
/*===========================================================================*/

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

REM Create types which are needed for customizations
CREATE OR REPLACE TYPE mds_numArray AS VARRAY(20) of NUMBER;
/

REM Don't change / to ; in the above and below lines

CREATE OR REPLACE TYPE mds_stringArray AS VARRAY(20) OF VARCHAR2(4000);
/

COMMIT;
