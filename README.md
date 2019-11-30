# kdbAlertTP

TP set-up for test Alert Monitor system. 

Companion code to Kx Technical White Paper [“Latency and efficiency considerations for a real-time surveillance system”](https://code.kx.com/v2/pw/surveillance-latency/).

This framework is an expansion of the skeleton TP framework described in Kx Technical White Paper [“Building real-time tick subscribers”](https://code.kx.com/v2/wp/building_real_time_tick_subscribers.pdf).

It has been built on to replay our cryptocurrency data set with the original timestamp but with today’s date in a live manner.  Each routine and execution-point (e.g. 'intraday 1 minute' + 'wj with timestamps') test was run in its own alert-engine process.  If running Windows, place the contents of kdbAlertTP on git but in a single location, extract the 7z data, point your windows terminal to that location, and run

    q startUp.q

All required processes for the test will be auto-started and a process status table (called `processStatus`) will be available with PID and handle details in that master q process, for example:

|name|port|handle|PID|lastHeartBeatReceived|
|----|----|----|----|----|
|master|55555|0|15248|2019.06.25D10:36:09.641313000|
|alertMonitor|999|604|12776|2019.06.25D10:36:09.643313000|
|tp|5000|612|11828|2019.06.25D10:36:09.643313000|
|hdb|5001|624|13804|2019.06.25D10:36:09.643313000|
|rdb|5002|628|9552|2019.06.25D10:36:09.643313000|
|aeRT1|5003|632|14528|2019.06.25D10:36:09.643313000|
|aeRT2|5004|636|12280|2019.06.25D10:36:09.643313000|
|aeRT3|5005|640|13740|2019.06.25D10:36:09.643313000|
|aeRT4|5006|644|12120|2019.06.25D10:36:09.643313000|
|aeID1_1|5007|648|14464|2019.06.25D10:36:09.643313000|
|aeID2_1|5008|652|15084|2019.06.25D10:36:09.643313000|
|aeID3_1|5009|656|14840|2019.06.25D10:36:09.643313000|
|aeID4_1|5010|660|15320|2019.06.25D10:21:29.642628000|
|aeID1_5|5011|664|12748|2019.06.25D10:36:09.643313000|
|aeID2_5|5012|668|13044|2019.06.25D10:36:09.643313000|
|aeID3_5|5013|672|15192|2019.06.25D10:36:09.643313000|
|aeID4_5|5014|676|13580|2019.06.25D10:13:29.642633000|
|aeID1_10|5015|680|15024|2019.06.25D10:36:09.643313000|
|aeID2_10|5016|684|12400|2019.06.25D10:36:09.643313000|
|aeID3_10|5017|688|14844|2019.06.25D10:36:09.643313000|
|aeID4_10|5018|692|4372|2019.06.25D10:03:29.642639000|
|replay|5100|696|14976|2019.06.25D10:36:09.643313000|


Data will start replaying in simulated real-time from the replay process and published to the tickerplant process to which all the alert engines are subscribed.  Any alerts that beat the example thresholds are sent to an alert table called `dxATAlert` in the `alertMonitor` process.  At any point, to shut down, run 

```q
\l shutDown.q
```

Each alert engine logs run times in process log files named accordingly kept on `C:\OnDiskDB`.  The repository includes the script `readInProcLogs.q` to read from these logs and store in a table for aggregation.  This framework can be used to test and compare your own approaches.
