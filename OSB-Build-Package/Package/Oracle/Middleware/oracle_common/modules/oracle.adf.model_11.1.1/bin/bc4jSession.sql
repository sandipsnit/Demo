create or replace package bc4jSession as

-----------------------------------------------------------------
-- bc4jSession
-- -----------
--
-- PL/SQL Program Specs which expose the
-- methods of AppModuleHelper.
--
-- $Author: smuench $
-- $Date: 1999/05/26 21:51:53 $
-- $Source: C:\\cvsroot/\\bc4j\\src\\oracle/jbo/plsql/bc4jSession.sql,v $
-- $Revision: 1.1 $
-----------------------------------------------------------------

  procedure initialize( amDefName VARCHAR2 );

  procedure createApplicationModule( amAlias VARCHAR2, amDefName VARCHAR2 );

  procedure removeApplicationModule( amAlias VARCHAR2 );

  procedure commit;

  procedure rollback;

  procedure next( amAlias VARCHAR2, voAlias VARCHAR2);

  procedure next( voAlias VARCHAR2);

  procedure previous( amAlias VARCHAR2, voAlias VARCHAR2);

  procedure previous( voAlias VARCHAR2);

  procedure first( amAlias VARCHAR2, voAlias VARCHAR2);

  procedure first( voAlias VARCHAR2);

  procedure executeQuery( amAlias VARCHAR2, voAlias VARCHAR2);

  procedure executeQuery( voAlias VARCHAR2);

  procedure setWhereClause( amAlias VARCHAR2, 
                            voAlias VARCHAR2,
                            whereClause VARCHAR2);

  procedure setWhereClause( voAlias VARCHAR2,
                            whereClause VARCHAR2);

  procedure setWhereClauseParam( amAlias      VARCHAR2,
                                 voAlias      VARCHAR2,
                                 bindvarIndex NUMBER,
                                 newValue     VARCHAR2);

  procedure setWhereClauseParam( voAlias      VARCHAR2,
                                 bindvarIndex NUMBER,
                                 newValue     VARCHAR2);

  procedure setAttribute( amAlias VARCHAR2,
                          voAlias VARCHAR2,
                          voAttribute VARCHAR2,
                          newValue VARCHAR2 );

  procedure setAttribute( voAlias VARCHAR2,
                          voAttribute VARCHAR2,
                          newValue VARCHAR2 );

   function getAttribute( amAlias VARCHAR2,
                          voAlias VARCHAR2,
                          voAttribute VARCHAR2,
                          newValue VARCHAR2 ) return VARCHAR2;

   function getAttribute( voAlias VARCHAR2,
                          voAttribute VARCHAR2,
                          newValue VARCHAR2 ) return VARCHAR2;



end;
.
/
show errors
create or replace package body bc4jSession as

  procedure initialize( amDefName VARCHAR2 )
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.createRootAppModule(java.lang.String)';


  procedure createApplicationModule( amAlias VARCHAR2, amDefName VARCHAR2)
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.createApplicationModule(java.lang.String, java.lang.String)';


  procedure removeApplicationModule( amAlias VARCHAR2 )
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.removeApplicationModule(java.lang.String)';

  procedure commit
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.commit()';

  procedure rollback
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.rollback()';

  procedure next( amAlias VARCHAR2, voAlias VARCHAR2)
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.next(java.lang.String, java.lang.String)';

  procedure next( voAlias VARCHAR2)
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.next(java.lang.String)';

  procedure previous( amAlias VARCHAR2, voAlias VARCHAR2)
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.previous(java.lang.String,java.lang.String)';

  procedure previous( voAlias VARCHAR2)
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.previous(java.lang.String)';

  procedure first( amAlias VARCHAR2, voAlias VARCHAR2)
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.first(java.lang.String,java.lang.String)';

  procedure first( voAlias VARCHAR2)
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.first(java.lang.String)';

  procedure executeQuery( amAlias VARCHAR2, voAlias VARCHAR2)
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.executeQuery(java.lang.String,java.lang.String)';

  procedure executeQuery( voAlias VARCHAR2)
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.executeQuery(java.lang.String)';

  procedure setWhereClause( amAlias VARCHAR2, 
                            voAlias VARCHAR2,
                            whereClause VARCHAR2)
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.setWhereClause(java.lang.String,java.lang.String,java.lang.String)';

  procedure setWhereClause( voAlias VARCHAR2,
                            whereClause VARCHAR2)
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.setWhereClause(java.lang.String,java.lang.String)';

  procedure setWhereClauseParam( amAlias      VARCHAR2,
                                 voAlias      VARCHAR2,
                                 bindvarIndex NUMBER,
                                 newValue     VARCHAR2)
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.setWhereClauseParam(java.lang.String,java.lang.String, int, java.lang.String)';

  procedure setWhereClauseParam( voAlias      VARCHAR2,
                                 bindvarIndex NUMBER,
                                 newValue     VARCHAR2)
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.setWhereClauseParam(java.lang.String, int, java.lang.String)';

  procedure setAttribute( amAlias    VARCHAR2,
                          voAlias     VARCHAR2,
                          voAttribute VARCHAR2,
                          newValue VARCHAR2 )
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.setAttribute(java.lang.String,java.lang.String, java.lang.String, java.lang.String)';

  procedure setAttribute( voAlias VARCHAR2,
                          voAttribute VARCHAR2,
                          newValue VARCHAR2 )
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.setAttribute(java.lang.String, java.lang.String, java.lang.String)';

   function getAttribute( amAlias VARCHAR2,
                          voAlias VARCHAR2,
                          voAttribute VARCHAR2,
                          newValue VARCHAR2 ) return VARCHAR2
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.getAttribute(java.lang.String,java.lang.String, java.lang.String, java.lang.String)
   return java.lang.String';

   function getAttribute( voAlias VARCHAR2,
                          voAttribute VARCHAR2,
                          newValue VARCHAR2 ) return VARCHAR2
  as LANGUAGE JAVA NAME
  'oracle.jbo.plsql.RootAppModuleHelper.getAttribute(java.lang.String,java.lang.String, java.lang.String)
   return java.lang.String';

end;
.
/
show errors
