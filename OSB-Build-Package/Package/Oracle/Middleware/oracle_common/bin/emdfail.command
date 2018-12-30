#!/usr/bin/sh -f
#
# insert the commands you wish to execute when the emdaemon fails in certain
# ways. The first argument is the failure condition.
# Currently these can be one of the following:
#   upload - The upload manager has determined that too much disk space is
#            being consumed. The upload manager turns off all collections
#            and tries uploading existing files on an expedited schedule.
#

#
# If a messsage is passed in (e.g. from a fixit job) then concatenate
# that message onto the emctl.msg contents
#
if [ "$#" = 0 -o "$#" -gt 1 ]; then
  echo "Usage: emdfail.command {failure_code}"
  exit 255
fi

#
# Mail to specified user
#
#  uncomment out the following 5 lines and specify a valid email address
#  in place of nobody@somewhere.nowhere to send the failure email when
#  the emd  fails in certain ways.
#
#if [ "$1" = "upload" ]; then
#  echo "Upload failure at `date`" >/tmp/upload$$
#  echo "Last 100 lines of log file:" >>/tmp/upload$$
#  tail -100 $EMDROOT/sysman/log/emd.trc >>/tmp/upload$$
#  mailx -s "EMD can not contact repository to upload files"  nobody@somewhere.nowhere </tmp/upload$$
#  rm -f /tmp/upload$$
#else
#  echo "emdfail.command: unknown failure code: $1"
#fi

