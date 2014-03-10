check-cpu-perf
==============

The script is used to obtain CPU average usage over specified time by executing the sar command;

The threshold is based on CPU idle percentage only, this is NOT CPU used.

Your nagios config could look something like this

    define service{
            use                     generic-service
            hostgroup_name          Linux
            service_description     CPU (all cores) average usage on 45 min
            notification_period     dailyhours
            check_command           check_nrpe!check_cpu_perf!20 2 45
    }


Your nrpe config should look something like this

    command[check_cpu_perf]=/usr/lib/nagios/plugins/check_cpu_perf.sh $ARG1$ $ARG2$ $ARG3$
