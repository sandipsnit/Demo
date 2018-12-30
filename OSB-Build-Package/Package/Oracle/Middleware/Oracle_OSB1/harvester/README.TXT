========================
PURPOSE
========================
This document describes how to harvest OSB resources using the following
methods:
 - command line
 - ANT script
 - WLST script

This document contains the following sub-sections:
 - Contents
 - Setting the Environment
 - Password Encryption
 - Command Line Harvest
 - ANT Harvest
 - WLST Harvest
 - Troubleshooting


========================
CONTENTS
========================

The harvester directory ($HARVESTER_HOME) contains files that are used to
configure the harvester framework. The files/directorie listed below must not
be modified.
  - lib/*
  - plugins/*
  - L10N/*
  - *.jar
  - adapters.xml
  - types.properties

This folder also contains the following:
  - encrypt.*                [ Command line script to encrypt passwords in the
                               HarvesterSettings.xml document]
  - log4fl.properties        [ Describes logging configuration ]
  - HarvesterSettings.xml    [ default settings file used by the harvester]
  - setenv.*                 [ Command line scripts to set the environment ]
  - osb11g-harvest.*         [ Command line scripts to run the harvester ]
  - osb11g-harvester-ant.xml [ ANT build file defining the default ANT targets
                               that can be used to harvest ]
  - wlst.*                   [ Command line scripts to execute WLST scripts ]


========================
SETTING THE ENVIRONMENT
========================

Before harvesting OSB resources via command line, ANT or WLST, you must set
your environment appropriately.

To set your environment, run the setenv.* script (note: you only need to run it
once per shell).
e.g.:
    cd $HARVESTER_HOME
    source setenv.sh


You can modify the setenv.* files to tune the JVM heap size, add additional JARs
to the CLASSPATH (e.g. if you have a JAR resource requiring custom jars on the
server classpath) or add additional system properties.


========================
PASSWORD ENCRYPTION
========================

The passwords used to access the OER server or OSB server must be encrypted
when used from the harvester scripts.

If you are using a harvester settings file to define these passwords, you can
use the encrypt.* script to encode those passwords. The encrypt.* script takes
two arguments - the input file and an output file.
e.g. - the following will overwrite the default settings file with encrypted
passwords:
    cd $HARVESTER_HOME
    source setenv.sh            [if the environment has not previously been set]
    ./encrypt.sh  HarvesterSettings.xml HarvesterSettings.xml


If you need an encrypted password to be used via command line argument, ANT
property or WLST argument and are not using a settings file, you can create a
custom XML file with the password specified in a <password> tag.
e.g. - to encrypt 2 passwords:
    created a file passwords.xml with the following content:
        <passwords>
            <password>admin</password>
            <password>JohnDoe</password>
        <passwords>
    next use the encrypt.* script to encrypt the file:
        cd $HARVESTER_HOME
        source setenv.sh        [if the environment has not previously been set]
        ./encrypt.sh passwords.xml passwords.xml


========================
COMMAND LINE HARVEST
========================

The simplest way to harvest through command line is to edit the settings file
HarvesterSettings.xml under $HARVESTER_HOME and then run the harvest.* script.
e.g.:
    cd $HARVESTER_HOME
    source setenv.sh            [if the environment has not previously been set]
    ./osb11g-harvest.sh

You may also create a new harvester settings file and use it by specifying the
-settings argument.
e.g.:
    ./osb11g-harvest.sh -settings MyHarvesterSettings.xml


When harvesting through command line, you can use the following arguments to
override the default behavior:
    * To override the default HarvesterSettings.xml:
        -settings <filename>
    * To override the repository configuration:
        -url <url>                          [OER repository URL]
        -username <username>
        -password <password>                [must be encrypted]
    * To perform a file query:
        -file <filename>                    [must be an OSB config jar]
    * To perform a remote query:
        -remote_url <url>                   [OSB server MBean URL]
        -remote_username <username>
        -remote_password <password>         [must be encrypted]
        -remote_server_type OSB             [only OSB is supported as value]
        -remote_project <projectname>       [to harvest a single OSB project]


========================
ANT HARVEST
========================

OSB provides an ANT file (osb11g-harvester-ant.xml) with targets to harvest
using a settings file (harvest.settings), a file query (harvest.file) and a
remote query (harvest.remote).
You can create your own ANT build file and call those targets.

e.g. the following build file (mybuild.xml) will harvest 2 separate OSB config
jars:
    <project name="harvest" basedir=".">
        <target name="do-harvest">
            <ant antfile="osb11g-harvester-ant.xml" target="harvest.file">
                <property name="file.name" value="/somepath/myconfig1.jar"/>
            </ant>
            <ant antfile="osb11g-harvester-ant.xml" target="harvest.file">
                <property name="file.name" value="/somepath/myconfig2.jar"/>
            </ant>
        </target>
    </project>
This build file assumes that the repository is already configured in the default
HarvesterSettings.xml. You can run this build file as follow:
    cd $HARVESTER_HOME
    source setenv.sh            [if the environment has not previously been set]
    ant -f mybuild.xml do-harvest

In the build file, you can use properties to override the default behavior (see
the target harvest.init in harvester-ant.xml):
    * To control the behavior of the task:
        task.debug              [turn on the harvester debug logging]
        task.failonerror        [true by default, when set to false, the task
                                 does not fail but set the result in the
                                 property identified by task.errorproperty]
        task.errorproperty      [property name to receive the task result]
    * To override the settings file:
        harvester.settings
    * To override the repository configuration:
        repository.url
        repository.username
        repository.password     [must be encrypted]
        repository.timeout
    * To override harvester configuration:
        settings.workdir
        settings.description
        settings.namespace
        settings.registrationStatus

When using the target harvest.file, the following properties are used:
    * file.name                 [required]
    * file.artifactStore        [optional, empty by default]

When using the target harvest.remote, the following properties are used:
    * remote.uri                [required, URI to the OSB server]
    * remote.username           [required]
    * remote.password           [required, must be encrypted]
    * remote.artifactStore      [optional, empty by default]
    * remote.projects           [optional, list of projects to harvest, empty by
                                 default indicating all projects are harvested]
    * remote.projectsDelimiter  [optional, set to ',' by default, use to delimit
                                 project names in remote.projects]


========================
WLST HARVEST
========================

OSB provides a WLST library function 'osb.harvest' that you can use to harvest
OSB resources using WLST scripts.

To make sure WLST is properly configured, you can use the provided wlst.*
script.
e.g.:
    cd $HARVESTER_HOME
    source setenv.sh            [if the environment has not previously been set]
    wlst.sh <scriptname>


The following WLST script uses the configuration provided in the default
HarvesterSettings.xml file:
    argMap = {}
    osb.harvest(argMap)

When using WLST, the command line arguments listed in the section 'Command Line
Harvest' also apply.
e.g.:
    argMap = {}
    argMap['-file'] = '/somepath/myconfig.jar'
    osb.harvest(argMap)


========================
TROUBLESHOOTING
========================

When you perform remote harvest of very large OSB configuration project(s), the
harvest may fail with an error as follows:
    weblogic.socket.MaxMessageSizeExceededException: Incoming message of size:
    '10000080' bytes exceeds the configured maximum of: '10000000' bytes for
    protocol: 't3'
For remote harvest, the OSB config jar will be downloaded via MBean. The default
WLS configuration has the max message size limit for the t3 protocol set to
10000000. When the size of the config jar exceeds that default you see the error
above.
You can increase the max message size limit for the t3 protocol by doing the
following:
  - on the server side:
      - open the WLS console
      - go to Environment -> Servers -> <AdminServer> -> Configuration
                          -> Protocols -> General
      - Increase the "Max Message Size" attribute
  - on the client side add the following system property to your setenv.*:
      -Dweblogic.MaxMessageSize=...
