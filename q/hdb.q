/Sample usage:
/q hdb.q C:/OnDiskDB/sym -p 5002

logfile:hopen hsym`$raze[system["echo $HOME/kdbAlertTP/processLogs/hdbProcLog"]];
.log.out:{x y,"\n"}[logfile;];
.log.out["log started at ",string[.z.p]];

if[1>count .z.x;show"Supply directory of historical database";exit 0];

hdb:.z.x 0

/Mount the Historical Date Partitioned Database
@[{system"l ",x};hdb;{show "Error message -  ",x;exit 0}]