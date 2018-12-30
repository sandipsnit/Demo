#!/bin/sh

JAVA_HOME="D:\OSB\Program"

MEM_ARGS="-Xms256m -Xmx512m"

"$JAVA_HOME/bin/java" ${MEM_ARGS} -jar patch-client.jar $*
