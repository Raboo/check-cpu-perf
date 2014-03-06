check-cpu-perf
==============

This readme needs more work.

Nagios config

    define service{
            use                     generic-service
            hostgroup_name          Linux
            service_description     CPU (all cores) average usage on 45 min
            notification_period     dailyhours
            check_command           check_nrpe!check_cpu_perf!20 2 45
    }


nrpe config

    command[check_cpu_perf]=/usr/lib/nagios/plugins/check_cpu_perf.sh $ARG1$ $ARG2$ $ARG3$
