# Copyright (c) 2010, 2011, Oracle and/or its affiliates. All rights reserved. 
#
# Caution: This file is part of the command scripting implementation. Do not edit or move
# this file because this may cause commands and scripts to fail. Do not
# try to reuse the logic in this file or keep copies of this file because this
# could cause your scripts to fail when you upgrade to a different version.

"""Oracle Middleware Configuration Loader"""

# append libs
import java

import cie.ConfigUtilities
cie.ConfigUtilities.setLevel("INFO")

# import OracleMWConfig
import cie.OracleMWConfig as OracleMWConfig
OracleMWConfig.init(globals())

# import OracleMWConfig
import cie.OracleMWConfigUtilities as OracleMWConfigUtilities

# import OracleHelp
import cie.OracleHelp as OracleHelp
OracleHelp.init()