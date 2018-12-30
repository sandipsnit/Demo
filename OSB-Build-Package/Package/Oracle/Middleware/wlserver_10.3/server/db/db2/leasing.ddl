
# WebLogic Singleton Servers Data Store DDL for DB2
# Copyright (c) 2005 by BEA, Inc., All Rights Reserved

DROP TABLE ACTIVE;

CREATE TABLE ACTIVE (
  SERVER VARCHAR(150) NOT NULL,
  INSTANCE VARCHAR(100) NOT NULL,
  DOMAINNAME VARCHAR(50) NOT NULL,
  CLUSTERNAME VARCHAR(50) NOT NULL,
  TIMEOUT TIMESTAMP,
  PRIMARY KEY (SERVER, DOMAINNAME, CLUSTERNAME)
); 

