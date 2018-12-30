-- upgrade_osb_111130_111140_sqlserver.sql
--
-- Copyright (c) 2010, Oracle and/or its affiliates. All rights reserved. 
--
--    NAME
--      upgrade_osb_111130_111140_sqlserver.sql - Upgrade OSB Schema from 11.1.1.3.0 to 11.1.1.4.0
--
--    DESCRIPTION
--      Updates the message label column and corresponding index change to avoid sqlserver
--      index size limitation.
--
--    NOTES
--    Replace "$(SCHEMA_USER)" with Schema Owner Name before run the script

--================================================================
--== SECTION: Upgrade OSB Index
--================================================================
-- Drop index
DROP INDEX IX_WLI_QS_REPORT_ATTRIBUTE_DM ON WLI_QS_REPORT_ATTRIBUTE
GO

-- Create View and Index
CREATE VIEW $(SCHEMA_USER).VIEW_WLI_QS_REPORT_ATTRIBUTE_DM WITH SCHEMABINDING
	    AS SELECT MSG_GUID, DB_TIMESTAMP, SUBSTRING(MSG_LABELS, 0, 380) AS M_LABELS
	    FROM $(SCHEMA_USER).WLI_QS_REPORT_ATTRIBUTE
GO

CREATE UNIQUE CLUSTERED INDEX IX_WLI_QS_REPORT_ATTRIBUTE_DM ON $(SCHEMA_USER).VIEW_WLI_QS_REPORT_ATTRIBUTE_DM(
	MSG_GUID, DB_TIMESTAMP, M_LABELS )
GO
-- END OF FILE

