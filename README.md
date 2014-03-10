check-cpu-perf
==============

### About
This is a nagios type check to obtain CPU average usage over specified time by executing the sar command.
(The threshold is based on CPU idle percentage only, this is NOT CPU used.)

#### Usage
./check_cpu_perf.sh {warning} {critical} {minutes of history}

**Example**: `./check_cpu_perf.sh 20 10 45`
`OK: CPU Idle = 95.07% | CpuUser=0.31%; CpuNice=0.00%; CpuSystem=1.11%; CpuIowait=0.27%; CpuSteal=3.24%; CpuIdle=95.07%;20;10`

### Setup
Your nagios config could look something like this

    define service{
            use                     generic-service
            hostgroup_name          Linux
            service_description     CPU (all cores) average usage on 45 min
            notification_period     dailyhours
            check_command           check_nrpe!check_cpu_perf!20 5 45
    }


Your nrpe config should look something like this

    command[check_cpu_perf]=/usr/lib/nagios/plugins/check_cpu_perf.sh $ARG1$ $ARG2$ $ARG3$
