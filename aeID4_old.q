/q aeID4.q [host]:port[:usr:pwd] [host]:port[:usr:pwd]
/2008.09.09 .k ->.q

logfile:hopen hsym`$"C:\\OnDiskDB\\aeID4ProcLog";
.log.out:{x string[.z.P],":-> ",y,"\n"}[logfile;];
.log.out["log started at ",string[.z.p]];

if[not "w"=first string .z.o;system "sleep 1"];
system"l alertFunctions.q";
system"c 25 300";

.ae.orderToTrade_getRowsWithWJ_alert:{[data;lookupTable]

    windows:(data[`transactTime]-0D00:05;data[`transactTime]);

    rowsInWindow:exec rowsInWindow from (cols[data],`rowsInWindow) xcol 
            wj1[
                windows;
                `sym`transactTime;
                data;
                (
                    `sym`transactTime xasc select sym,transactTime,rn from lookupTable;
                    (::;`rn)
                )
             ];

    data:update 
        orderCount:count each rowsInWindow,
        totalOrderQty:sum each lookupTable[`originalQuantity]@/:rowsInWindow,
        totalOrderValue:sum each (lookupTable[`originalQuantity]@/:rowsInWindow)*lookupTable[`limitPrice]@/:rowsInWindow,
        orderCountsPerSide:count each' group each lookupTable[`side]@/:rowsInWindow,
        bestBidAsk:{(max;min)@''`side xgroup ([]side:x,`buy`sell;price:y,0.0,0.0)}'[lookupTable[`side]@/:rowsInWindow;lookupTable[`limitPrice]@/:rowsInWindow]
    from data;

    lookupTable:update rn:i from ?[dxTradePublic;enlist((';~:;<);`transactTime;min[data`transactTime]-0D00:05);0b;({x!x}`sym`transactTime`price`quantity)];

    rowsInWindow:exec rowsInWindow from (cols[data],`rowsInWindow) xcol 
            wj1[
                windows;
                `sym`transactTime;
                data;
                (
                    `sym`transactTime xasc select sym,transactTime,rn from lookupTable;
                    (::;`rn)
                )
             ];

    data:update tradeCount:count each rowsInWindow,totalTradeQty:sum each lookupTable[`quantity]@/:rowsInWindow,totalTradeValue:sum each (lookupTable[`quantity]@/:rowsInWindow)*lookupTable[`price]@/:rowsInWindow  from data;
 };

upd:{[t;x]
    /.debug.upd:(`t`x)!(t;x);
    /`updStats upsert ([]time:enlist[.z.p];cnt:count[x];mnt:min[x`transactTime]);
    t insert x;
 };

.z.ts:{
    startTime:.z.P;
    wBefore:.Q.w[];
    tsvector:system"ts:20 outcome:.ae.orderToTrade_getRowsWithWJ_ts[]";
    $[outcome~`noDataToAnalyse;:();.ae.orderToTrade_getRowsWithWJ_lastEventAnalysed:outcome[0]];
    endTime:.z.P;
    wAfter:.Q.w[];
    .log.out -3!(`.ae.orderToTrade_getRowsWithWJ_ts;startTime;endTime;outcome[1];outcome[2];tsvector[0];tsvector[1];wBefore`used;wAfter`used;wBefore`heap;wAfter`heap);
 };

.ae.orderToTrade_getRowsWithWJ_lastEventAnalysed:0;

.ae.orderToTrade_getRowsWithWJ_ts:{

    dataToAnalyse:select transactTime,sym,orderID,executionOptions,eventType,orderType from dxOrderPublic where 
        eventID>.ae.orderToTrade_getRowsWithWJ_lastEventAnalysed,
        not[executionOptions in `$("fill-or-kill";"immediate-or-cancel";"maker-or-cancel")]
        or (executionOptions in `$("fill-or-kill";"immediate-or-cancel";"maker-or-cancel"))
        and not ({`Place`Cancel~x};eventType)fby ([]orderID;transactTime),
        transactTime<last[dxOrderPublic[`transactTime]]-0D00:00:10,
        eventType=`Place;

    if[not count dataToAnalyse;:`noDataToAnalyse];

    cacheToUse:update rn:i from select sym,transactTime,eventID,limitPrice,originalQuantity,side from dxOrderPublic where 
        transactTime>=min[dataToAnalyse[`transactTime]]-(0D00:05+00:00:10),
        not[executionOptions in `$("fill-or-kill";"immediate-or-cancel";"maker-or-cancel")]
        or (executionOptions in `$("fill-or-kill";"immediate-or-cancel";"maker-or-cancel"))
        and not ({`Place`Cancel~x};eventType)fby ([]orderID;transactTime),
        eventType=`Place;

    .ae.orderToTrade_getRowsWithWJ_alert[dataToAnalyse;cacheToUse];
    :(last[dataToAnalyse[`eventID]];first[dataToAnalyse[`transactTime]];last[dataToAnalyse[`transactTime]])
 };

/ get the ticker plant and history ports, defaults are 5000,5001
.u.x:.z.x,(count .z.x)_(":5000";":5001");

/ end of day: save, clear, hdb reload
/.u.end:{t:tables`.;t@:where `g=attr each t@\:`sym;.Q.hdpf[`$":",.u.x 1;`:.;x;`sym];@[;`sym;`g#] each t;};

/ init schema and sync up from log file;cd to hdb(so client save can run)
.u.rep:{(.[;();:;].)each x;if[null first y;:()];-11!y;system "cd ",1_-10_string first reverse y};
/ HARDCODE \cd if other than logdir/db

/ connect to ticker plant for (schema;(logcount;log))
.u.rep .(hopen `$":",.u.x 0)"(.u.sub[`;`];`.u `i`L)";
