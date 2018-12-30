-- SQL Script for xmlpserver
-- &&1 - Audit Admin Role
-- &&2 - Audit Append Role
-- &&3 - Audit Viewer Role

CREATE TABLE xmlpserver (
	IAU_ID NUMBER , 
	IAU_TstzOriginating TIMESTAMP , 
	IAU_EventType VARCHAR(255) , 
	IAU_EventCategory VARCHAR(255) , 
	IAU_Format VARCHAR(30) , 
	IAU_Template VARCHAR(255) , 
	IAU_Locale VARCHAR(10) , 
	IAU_JobId VARCHAR(255) , 
	IAU_IsScheduled NUMBER , 
	IAU_OutputId VARCHAR(255) , 
	IAU_UserJobName VARCHAR(100) , 
	IAU_UserJobDescription VARCHAR(255) , 
	IAU_StartDate TIMESTAMP , 
	IAU_EndDate TIMESTAMP , 
	IAU_Bursting NUMBER , 
	IAU_JobGroup VARCHAR(255) , 
	IAU_RunType VARCHAR(255) , 
	IAU_OutputInfo CLOB , 
	IAU_DeliveryInfo CLOB , 
	IAU_RepublishId VARCHAR(255) , 
	IAU_FreeMemory NUMBER , 
	IAU_TotalMemory NUMBER , 
	IAU_DataSize NUMBER , 
	IAU_ProcessTime NUMBER , 
	IAU_OutputName VARCHAR(255) , 
	IAU_DeliveryMethod VARCHAR(255) , 
	IAU_DeliveryProperties CLOB 
);

-- INDEX 
CREATE INDEX xmlpserver_Index
ON xmlpserver(IAU_TSTZORIGINATING);

-- PERMISSIONS 
GRANT ALL on xmlpserver to &&1;
GRANT INSERT on xmlpserver to &&2;
GRANT SELECT on xmlpserver to &&2;
GRANT SELECT on xmlpserver to &&3;

-- SYNONYMS 
CREATE OR REPLACE SYNONYM &&3..xmlpserver FOR &&1..xmlpserver;
CREATE OR REPLACE SYNONYM &&2..xmlpserver FOR &&1..xmlpserver;
