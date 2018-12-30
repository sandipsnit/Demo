#!/bin/sh
#############################################################################
# Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.
# Shell Script Wrapper for Perl
#
# $Id: rda.sh,v 2.21 2012/02/20 22:17:21 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/bin/rda.sh,v 2.21 2012/02/20 22:17:21 mschenke Exp $
#############################################################################

if [ -z "$RDA_CWD" ]
then
  RDA_CWD=`pwd`
  export RDA_CWD
fi
RDA_DIR=`dirname "$0"`
cd "$RDA_DIR" 

# Detect if a compile engine must be used
if [ -r "$RDA_CWD/rda.cfg" ]
then
  . "$RDA_CWD/rda.cfg"
  RDA_EXE="$RDA_CWD/${RDA_EXE:-rda.exe}"
  if [ -n "$RDA_ENG" -a -x "engine/$RDA_ENG" ]
  then
    RDA_ENG="`pwd`/engine/$RDA_ENG"
    "$RDA_ENG" -X Upgrade -- engine "$RDA_EXE" "$RDA_ENG"
  fi
  if [ -x "$RDA_EXE" ]
  then
    exec "$RDA_EXE" "$@"
  fi
elif [ -r "engine/rda.cfg" ]
then
  . "engine/rda.cfg"
  RDA_EXE="`pwd`/${RDA_EXE:-rda.exe}"
  if [ -n "$RDA_ENG" -a -x "engine/$RDA_ENG" ]
  then
    RDA_ENG="`pwd`/engine/$RDA_ENG"
    "$RDA_ENG" -X Upgrade -- engine "$RDA_EXE" "$RDA_ENG"
  fi
  if [ -x "$RDA_EXE" ]
  then
    exec "$RDA_EXE" "$@"
  fi
fi

# Try to local Perl if it is not in the path
if [ -z "$RDA_NO_NATIVE" ]
then
  PERL_CMD=`(unset LANG; type perl) 2>/dev/null`
  PERL_EXE=`expr "${PERL_CMD}" : "perl is a tracked alias for \(.*\)"`
  if [ -z "${PERL_EXE}" ]
  then
    PERL_EXE=`expr "$PERL_CMD" : "perl is hashed (\(.*\))"`
    if [ -z "$PERL_EXE" ]
    then
      PERL_EXE=`expr "$PERL_CMD" : "perl is \(.*\)"`
    fi
  fi
fi

# Validate the local Perl
if [ -n "$PERL_EXE" ]
then
  PERL5OLD="${PERL5LIB:-.}"
  PERL5LIB=.
  export PERL5LIB
  ( ulimit -c 0
    "$PERL_EXE" -e "die 'too old' if $] < 5.005; use strict"
  ) >/dev/null 2>/dev/null
  if [ $? -ne 0 ]
  then
    PERL_EXE=''
    PERL5LIB="$PERL5OLD"
  fi
fi

# Validate Applications Perl
if [ -z "$PERL_EXE" -a -n "$ADPERLPRG" ]
then
  ( ulimit -c 0
    "$ADPERLPRG" -e "die 'too old' if $] < 5.005; use strict"
  ) >/dev/null 2>/dev/null
  if [ $? -eq 0 ]
  then
    PERL_EXE="$ADPERLPRG"
  fi
fi

# Validate Perl in RDA .config file
if [ -z "$PERL_EXE" -a -r .config ]
then
  . ./.config
  export PERL5LIB
  ( ulimit -c 0
    "$PERL5DIR"/perl -e "die 'too old' if $] < 5.005; use strict"
  ) >/dev/null 2>/dev/null
  if [ $? -eq 0 ]
  then
    PERL_EXE="$PERL5DIR"/perl
  fi
fi

# Locate Perl
ORA_HOME="${IAS_ORACLE_HOME:-$ORACLE_HOME}"
if [ -z "$PERL_EXE" ]
then
  # Locate Perl in the Oracle home
  if [ -n "$ORA_HOME" ]
  then
    if [ -x "$ORA_HOME"/perl/bin/perl ]
    then
      PERL_EXE=`echo $ORA_HOME/perl/bin/perl`
      PERL_LIB=`echo $ORA_HOME/perl/lib`
      PERL_SHL=`echo $ORA_HOME/lib`
    elif [ -x "$ORA_HOME"/perl/5*/bin/perl ]
    then
      PERL_EXE=`echo $ORA_HOME/perl/5*/bin/perl`
      PERL_LIB=`echo $ORA_HOME/perl/5*/lib`
      PERL_SHL=`echo $ORA_HOME/lib`
    elif [ -x "$ORA_HOME"/Apache/perl/bin/perl ]
    then
      PERL_EXE=`echo $ORA_HOME/Apache/perl/bin/perl`
      PERL_LIB=`echo $ORA_HOME/Apache/perl/lib`
      PERL_SHL=`echo $ORA_HOME/lib`
    elif [ -x "$ORA_HOME"/Apache/perl/5*/bin/perl ]
    then
      PERL_EXE=`echo $ORA_HOME/Apache/perl/5*/bin/perl`
      PERL_LIB=`echo $ORA_HOME/Apache/perl/5*/lib`
      PERL_SHL=`echo $ORA_HOME/lib`
    elif [ -x "$ORA_HOME"/Apache/perl/5*/bin/*/perl ]
    then
      PERL_EXE=`echo $ORA_HOME/Apache/perl/5*/bin/*/perl`
      PERL_LIB=`echo $ORA_HOME/Apache/perl/5*/lib`
      PERL_SHL=`echo $ORA_HOME/lib`
    fi
  fi

  # Locate Perl in OCM
  if [ -z "$PERL_EXE" ]
  then
    # Locate OCM
    CCR_PERL=''
    if [ -d ../ccr/engines/*/perl ]
    then
      CCR_PERL=`echo ../ccr/engines/*/perl`
    elif [ -n "$ORA_HOME" -a -d "$ORA_HOME"/ccr/engines/*/perl ]
    then
      CCR_PERL=`echo "$ORA_HOME"/ccr/engines/*/perl`
    elif [ -n "$ORA_HOME" -a \
           -d "$ORA_HOME"/../oracle_common/ccr/engines/*/perl ]
    then
      CCR_PERL=`echo "$ORA_HOME"/../oracle_common/ccr/engines/*/perl`
    elif [ -n "$ORA_HOME" -a -d "$ORA_HOME"/../utils/ccr/engines/*/perl ]
    then
      CCR_PERL=`echo "$ORA_HOME"/../utils/ccr/engines/*/perl`
    elif [ -n "$MW_HOME" -a -d "$MW_HOME"/oracle_common/ccr/engines/*/perl ]
    then
      CCR_PERL=`echo "$MW_HOME"/oracle_common/ccr/engines/*/perl`
    elif [ -n "$MW_HOME" -a -d "$MW_HOME"/utils/ccr/engines/*/perl ]
    then
      CCR_PERL=`echo "$MW_HOME"/utils/ccr/engines/*/perl`
    elif [ -n "$WL_HOME" -a -d "$WL_HOME"/../oracle_common/ccr/engines/*/perl ]
    then
      CCR_PERL=`echo "$WL_HOME"/../oracle_common/ccr/engines/*/perl`
    elif [ -n "$WL_HOME" -a -d "$WL_HOME"/../utils/ccr/engines/*/perl ]
    then
      CCR_PERL=`echo "$WL_HOME"/../utils/ccr/engines/*/perl`
    elif [ -d /usr/lib/ccr/engines/*/perl ]
    then
      CCR_PERL=`echo /usr/lib/ccr/engines/*/perl`
    elif [ -n "${ORACLE_CONFIG_HOME}" ]
    then
      CCR_PROP="$ORACLE_CONFIG_HOME"/ccr/config/collector.properties
      if [ -r "$CCR_PROP" ]
      then
        CCR_HOME=`grep -e "^ccr.binHome=" "$CCR_PROP" | cut -d= -f 2`
        if [ -d "$CCR_HOME"/engines/*/perl ]
        then
          CCR_PERL=`echo "$CCR_HOME"/engines/*/perl`
        fi
      fi
    fi

    # Locate OCM Perl
    if [ -n "$CCR_PERL" ]
    then
      if [ -x "$CCR_PERL"/bin/perl ]
      then
        PERL_EXE=`echo $CCR_PERL/bin/perl`
        PERL_LIB=`echo $CCR_PERL/lib`
      elif [ -x "$CCR_PERL"/5*/bin/*/perl ]
      then
        PERL_EXE=`echo $CCR_PERL/5*/bin/*/perl`
        PERL_LIB=`echo $CCR_PERL`
      fi
    fi
  fi

  # Validate the Perl found
  if [ -n "$PERL_EXE" ]
  then
    PERL5DIR=`dirname "$PERL_EXE"`
    PERL5LIB="."
    if [ -d "$PERL_LIB" ]
    then
      for DIR in `find "$PERL_LIB" -type d -name auto -exec dirname '{}' \;`
      do
        PERL5LIB="$DIR:$PERL5LIB"
      done
    fi
    export PERL5LIB
    "$PERL_EXE" -e "die 'too old' if $] < 5.005; use strict" \
      >/dev/null 2>/dev/null
    if [ $? -ne 0 ]
    then
      PERL5DIR=''
    elif [ -w . ]
    then
      echo "PERL5DIR='$PERL5DIR'" >.config
      echo "PERL5LIB='$PERL5LIB'" >>.config
      if [ -n "$PERL_SHL" ]
      then
        echo "PERL_SHL='$PERL_SHL'" >>.config
      fi
    fi
  fi

  if [ -z "$PERL5DIR" ]
  then
    if [ -z "$ORA_HOME" ]
    then
      echo "Error: ORACLE_HOME is not set."
      echo "Please set your ORACLE_HOME."
    else
      echo "Error: Perl not found in the PATH or in known directory locations."
      echo "Although the default RDA engine requires Perl, compiled versions"
      echo "without Perl requirements are available for major platforms. Please"
      echo "download the platform-specific RDA engine from My Oracle Support"
      echo "and place it within the top directory of your RDA installation."
    fi
    exit 1
  fi

  PATH="$PERL5DIR:$PATH"
  export PATH PERL5LIB
else
  FOUND='N'
  for DIR in `"$PERL_EXE" -e 'print join("\n",@INC);'`
  do
    if [ "$DIR" = "." ]
    then
      FOUND='Y'
    fi
  done
  if [ "$FOUND" = "N" ]
  then
    if [ -z "$PERL5LIB" ]
    then
      PERL5LIB='.'
    else
      PERL5LIB=".:$PERL5LIB"
    fi
    export PERL5LIB
  fi
fi

# Extend the shared library path
if [ -n "$PERL_SHL" ]
then
  OS=`$PERL_EXE -e 'print $^O;'`
  if [ "$OS" = "aix" ]
  then
    RDA_ALTER_SHL="LIBPATH=$LIBPATH"
    if [ -z "$LIBPATH" ]
    then
      LIBPATH="$PERL_SHL"
    else
      LIBPATH="$PERL_SHL:$LIBPATH"
    fi
    export LIBPATH RDA_ALTER_SHL
  elif [ "$OS" = "hpux" ]
  then
    RDA_ALTER_SHL="SHLIB_PATH=$SHLIB_PATH"
    if [ -z "$SHLIB_PATH" ]
    then
      SHLIB_PATH="$PERL_SHL"
    else
      SHLIB_PATH="$PERL_SHL:$SHLIB_PATH"
    fi
    export SHLIB_PATH RDA_ALTER_SHL
  elif [ "$OS" = "darwin" ]
  then
    RDA_ALTER_SHL="DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH"
    if [ -z "$DYLD_LIBRARY_PATH" ]
    then
      DYLD_LIBRARY_PATH="$PERL_SHL"
    else
      DYLD_LIBRARY_PATH="$PERL_SHL:$DYLD_LIBRARY_PATH"
    fi
    export DYLD_LIBRARY_PATH RDA_ALTER_SHL
  else
    RDA_ALTER_SHL="LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
    if [ -z "$LD_LIBRARY_PATH" ]
    then
      LD_LIBRARY_PATH="$PERL_SHL"
    else
      LD_LIBRARY_PATH="$PERL_SHL:$LD_LIBRARY_PATH"
    fi
    export LD_LIBRARY_PATH RDA_ALTER_SHL
  fi
fi

# Test if DBD::Oracle can be used
if [ -z "$RDA_NO_DBD_ORACLE" ]
then
  "$PERL_EXE" -e "use DBI; use DBD::Oracle;" >/dev/null 2>/dev/null
  if [ $? -ne 0 ]
  then
    RDA_NO_DBD_ORACLE=1
    export RDA_NO_DBD_ORACLE
  fi
fi

# Run the Perl script
exec "${PERL_EXE:-perl}" rda.pl "$@"
