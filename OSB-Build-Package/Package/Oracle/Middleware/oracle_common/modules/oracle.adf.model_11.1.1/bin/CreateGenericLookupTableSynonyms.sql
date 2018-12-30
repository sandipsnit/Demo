Rem
Rem $Header: jdevadf/modules/adfm-business-editor/etc/apps/Taskflows/Model/src/CreateGenericLookupTableSynonyms.sql /st_jdevadf_patchset_ias/1 2011/05/19 13:25:09 smuench Exp $
Rem
Rem CreateGenericLookupTableSynonyms.sql
Rem
Rem Copyright (c) 2011, Oracle.  All rights reserved.  
Rem
Rem    NAME
Rem      CreateGenericLookupTableSynonyms.sql - Create ADF synonyms for FND lookup tables
Rem
Rem    DESCRIPTION
Rem      Creates synonyms to mape ADF_LOOKUPS to FND_LOOKUPS
Rem      and ADF_LOOKUP_TYPES to FND_STANDARD_LOOKUP_TYPES
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    smuench     05/19/11 - Created
Rem

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

create synonym fnd_standard_lookup_types for adf_lookup_types;
create synonym fnd_lookups for adf_lookups;
