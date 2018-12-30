SAVECP=$CLASSPATH
unset CLASSPATH
DERBY_HOME=C:/Oracle/Middleware/wlserver_10.3/common/derby
export DERBY_HOME
C:/Oracle/Middleware/wlserver_10.3/common/derby/bin/startNetworkServer $@ &
CLASSPATH=$SAVECP
export CLASSPATH
     
