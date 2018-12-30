"""
Copyright (c) 2009, 2011, Oracle and/or its affiliates. All rights reserved.

Caution: This file is part of the command scripting implementation.
Do not edit or move this file because this may cause commands and scripts
to fail. Do not try to reuse the logic in this file or keep copies of this
file because this could cause your scripts to fail when you upgrade to a
different version.

Oracle Fusion Middleware logging commands.

"""

def listLoggers(**kws):
    import oracle_odl_handler
    return oracle_odl_handler.listLoggers(**kws)

def getLogLevel(**kws):
    import oracle_odl_handler
    return oracle_odl_handler.getLogLevel(**kws)

def setLogLevel(**kws):
    import oracle_odl_handler
    return oracle_odl_handler.setLogLevel(**kws)

def listLogHandlers(**kws):
    import oracle_odl_handler
    return oracle_odl_handler.listLogHandlers(**kws)

def configureLogHandler(**kws):
    import oracle_odl_handler
    return oracle_odl_handler.configureLogHandler(**kws)

def listLogs(**kws):
    import oracle_odl_handler
    return oracle_odl_handler.listLogs(**kws)

def displayLogs(searchString=None, **kws):
    import oracle_odl_handler
    return oracle_odl_handler.displayLogs(searchString, **kws)

def help(cmd=None):
    import cie.OracleHelp as OracleHelp
    _module = "OracleODL"
    if cmd == None:
        cmd = _module
    else:
        cmd = _module + '.' + cmd
    return OracleHelp.help(cmd)

