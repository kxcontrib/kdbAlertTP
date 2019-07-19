/q aeRT3.q [host]:port[:usr:pwd] [host]:port[:usr:pwd]
/2008.09.09 .k ->.q
.proc.name:last[.z.x];
logfile:hopen hsym`$"C:\\OnDiskDB\\procLog",.proc.name;
.log.out:{x string[.z.P],":-> ",y,"\n"}[logfile;];
.log.out["log started at ",string[.z.p]];

if[not "w"=first string .z.o;system "sleep 1"];
system"l alertFunctions.q";
system"c 25 300";

.ae.orderToTrade_getRows_alert:{[data]

    windows:(data[`transactTime]-0D00:05;data[`transactTime]);

    lookupTable:?[dxOrderPublic;(((';~:;<);`transactTime;min[data`transactTime]-0D00:05);(=;`eventType;enlist`Place));0b;({x!x}`sym`transactTime`limitPrice`originalQuantity`side`eventID)];

    rowsInWindow:.ae.getRowsInTimeWindow_cutoff1G[windows;data;lookupTable];

    data:update 
        orderCount:count each rowsInWindow,
        totalOrderQty:sum each lookupTable[`originalQuantity]@/:rowsInWindow,
        totalOrderValue:sum each (lookupTable[`originalQuantity]@/:rowsInWindow)*lookupTable[`limitPrice]@/:rowsInWindow,
        orderCountsPerSide:count each' group each lookupTable[`side]@/:rowsInWindow,
        bestBidAsk:{(max;min)@''`side xgroup ([]side:`buy`sell,x;price:0.0,0.0,y)}'[lookupTable[`side]@/:rowsInWindow;lookupTable[`limitPrice]@/:rowsInWindow]
    from data;

    lookupTable:?[dxTradePublic;enlist((';~:;<);`transactTime;min[data`transactTime]-0D00:05);0b;({x!x}`sym`transactTime`price`quantity`eventID)];

    rowsInWindow:.ae.getRowsInTimeWindow_cutoff1G[windows;data;lookupTable];

    data:update tradeCount:count each rowsInWindow,totalTradeQty:sum each lookupTable[`quantity]@/:rowsInWindow,totalTradeValue:sum each (lookupTable[`quantity]@/:rowsInWindow)*lookupTable[`price]@/:rowsInWindow  from data;

    .ae.orderToTrade_checkAgainstThresholds[data];
 };

.ae.orderToTrade_getRows_upd:{[t;x]
    if[t=`dxOrderPublic;
        `x set select transactTime,sym,eventID,orderID,executionOptions,eventType,orderType from x where eventType=`Place;
        if[not count x;:()];
        startTime:.z.P;
        wBefore:.Q.w[];
        tsvector:system"ts:20 .ae.orderToTrade_getRows_alert[x]";
        endTime:.z.P;
        wAfter:.Q.w[];
        .log.out -3!(`.ae.orderToTrade_getRows_alert;startTime;endTime;min[x`transactTime];max[x`transactTime];tsvector[0];tsvector[1];wBefore`used;wAfter`used;wBefore`heap;wAfter`heap);
    ];

 };

upd:{[t;x]
    /.debug.upd:(`t`x)!(t;x);
    /`updStats upsert ([]time:enlist[.z.p];cnt:count[x];mnt:min[x`transactTime]);
    t insert x;
    .ae.orderToTrade_getRows_upd[t;x];
    if[count dxATAlert;
        .ae.alertMonitorHandle("upd";`dxATAlert;select from dxATAlert where i=(first;i)fby eventID);
        delete from `dxATAlert;
    ];
 };

/ get the ticker plant and history ports, defaults are 5001,5001
.u.x:.z.x,(count .z.x)_(":5000";":5001");

/ end of day: save, clear, hdb reload
/.u.end:{t:tables`.;t@:where `g=attr each t@\:`sym;.Q.hdpf[`$":",.u.x 1;`:.;x;`sym];@[;`sym;`g#] each t;};

/ init schema and sync up from log file;cd to hdb(so client save can run)
.u.rep:{(.[;();:;].)each x;if[null first y;:()];-11!y;system "cd ",1_-10_string first reverse y};
/ HARDCODE \cd if other than logdir/db

/ connect to ticker plant for (schema;(logcount;log))
.u.rep .(hopen `$":",.u.x 0)"(.u.sub[`;`];`.u `i`L)";