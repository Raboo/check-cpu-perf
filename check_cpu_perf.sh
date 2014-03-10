#!/bin/bash
#
# Check CPU Performance plugin for Nagios 
#
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt
#
# Author        : Luke Harris
# Contributions : Elias Abacioglu
# version       : 2014031001
# Creation date : 1 October 2010
# Revision date : 10 March 2014
# Description   : Nagios plugin to check CPU performance statistics.
#               This script has only been tested on Ubuntu.
#               But this script has *should* work on the following Linux and Unix platforms:
#               RHEL/CentOS, SUSE, Ubuntu, Debian, FreeBSD => 7 and Solaris 8-10.
#               The script is used to obtain key CPU performance statistics average over specified time by executing the
#               sar command, eg. user, system, iowait, steal, nice, idle.
#               The Nagios Threshold test is based on CPU idle percentage only, this is NOT CPU used.
#               Support has been added for Nagios Plugin Performance Data for integration with Splunk, NagiosGrapher, PNP4Nagios, 
#               opcp, NagioStat, PerfParse, fifo-rrd, rrd-graph, etc
#
#               Note: My(Elias) changes to return an average over time kind of renders the purpose of graphing useless, for that
#                     it's best to use the original check from Luke Harris.
#
# USAGE         : ./check_cpu_perf.sh {warning} {critical} {minutes of history}
#
# Example: ./check_cpu_perf.sh 20 10 45
# OK: CPU Idle = 95.07% | CpuUser=0.31%; CpuNice=0.00%; CpuSystem=1.11%; CpuIowait=0.27%; CpuSteal=3.24%; CpuIdle=95.07%;20;10
#
# Note: the option exists to NOT test for a threshold. Specifying 0 (zero) for both warning and critical will always return an exit code of 0.


#Ensure warning and critical limits are passed as command-line arguments
if [ -z "$1" -o -z "$2" -o -z "$3" ]
then
 echo "Please include three arguments, eg."
 echo "Usage: $0 {warning} {critical} {minutes of history}"
 echo "Example: $0 20 10 30"
exit 3
fi

#Disable nagios alerts if warning and critical limits are both set to 0 (zero)
if [ $1 -eq 0 ]
 then
  if [ $2 -eq 0 ]
   then
    ALERT=false
  fi
fi
        
#Ensure warning is greater than critical limit
if [ $1 -lt $2 ]
 then
  echo "Please ensure warning is greater than critical, eg."
  echo "Usage: $0 20 10"
  exit 3
fi

#Detect which OS and if it is Linux then it will detect which Linux Distribution.
OS=`uname -s`

#Define locale to ensure time is in 24 hour format
LC_ALL=en_AU.UTF-8

TIME=$(date +%H:%M:%S --date="${3} min ago")
CORES=$(cat /proc/cpuinfo | grep processor | awk '{ORS="," ; print $3}')

#Collect sar output
case "$OS" in
'Linux')
SARCPU=$(/usr/bin/sar -P ALL -s ${TIME}|grep all|grep Average|tail -1)
VERSION=`sar -V|head -1|awk '{print $3}'|awk -F\. '{print $1}'`
if [ $VERSION -gt 5 ]
 then
  SARCPUIDLE=`echo ${SARCPU}|awk '{print $8}'|awk -F. '{print $1}'`
  CPU=$(echo ${SARCPU}|awk "{print \"CPU Idle = \"\$8\"% | CpuUser=\"\$3\"%; CpuNice=\"\$4\"%; CpuSystem=\"\$5\"%; CpuIowait=\"\$6\"%; CpuSteal=\"\$7\"%; CpuIdle=\"\$8\"%;${1};${2}\"}")
 else
  SARCPUIDLE=`echo ${SARCPU}|awk '{print $7}'|awk -F. '{print $1}'`
  CPU=$(echo ${SARCPU}|awk "{print \"CPU Idle = \"\$7\"% | CpuUser=\"\$3\"%; CpuNice=\"\$4\"%; CpuSystem=\"\$5\"%; CpuIowait=\"\$6\"%; CpuIdle=\"\$7\"%;${1};${2}\"}")
fi
;;
'SunOS')
SARCPU=$(/usr/bin/sar -u -s ${TIME}|grep Average|tail -1)
SYSSTATPKGINFO=`pkginfo -l SUNWaccu|grep VERSION|awk '{print $2}'|awk -F\. '{print $1}'`
if [ $SYSSTATPKGINFO -ge 11 ]
 then
  SARCPUIDLE=`echo ${SARCPU}|awk '{print $5}'`
  CPU=$(echo ${SARCPU}|awk "{print \"CPU Idle = \"\$5\"% | CpuUser=\"\$2\"%; CpuSystem=\"\$3\"%; CpuIowait=\"\$4\"%; CpuIdle=\"\$5\"%;${1};${2}\"}")
 else
  echo "Solaris $SYSSTATPKGINFO Not Supported"
  exit 3
fi
;;
'FreeBSD')
SARCPU=$(/usr/local/bin/bsdsar -u -s ${TIME}|tail -1)
VERSION=`pkg_info | grep ^bsdsar | awk -F\- '{print $2}' | awk -F\. '{print $1}'`
if [ $VERSION -ge 1 ]
 then
  SARCPUIDLE=`echo ${SARCPU}|awk '{print $6}'`
  CPU=$(echo ${SARCPU}|awk "{print \"CPU Idle = \"\$6\"% | CpuUser=\"\$2\"%; CpuSystem=\"\$3\"%; CpuNice=\"\$4\"%; CpuIntrpt=\"\$5\"%; CpuIdle=\"\$6\"%;${1};${2}\"}")
 else
  echo "FreeBSD bsdsar $VERSION Not Supported"
  exit 3
fi
;;
esac

#Display CPU Performance without alert
if [ "$ALERT" == "false" ]
 then
    echo "$CPU"
    exit 0
 else
        ALERT=true
fi

#Display CPU Performance with alert
if [ ${SARCPUIDLE} -lt $2 ]
 then
    echo "CRITICAL: $CPU"
    exit 2
 elif [ $SARCPUIDLE -lt $1 ]
     then
      echo "WARNING: $CPU"
      exit 1
         else
      echo "OK: $CPU"
      exit 0
fi
