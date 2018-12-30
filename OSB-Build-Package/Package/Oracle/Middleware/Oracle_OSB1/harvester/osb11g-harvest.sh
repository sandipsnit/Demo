#!/bin/sh

"$JAVA_HOME/bin/java" $JAVA_OPTS com.oracle.oer.sync.framework.Introspector -harvester_home "$HARVESTER_HOME" $*
