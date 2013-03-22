string version = "ver. 4.0.0 rev 104";
key memory_io = "12345678-0000-0000-0000-e1e2e3e4e5ff";
integer cell_size = 2600;
string cell_prefix = "ic";

float sttime = 26.0; //speed test "frame" time
float reqtime = 16.0; //single request timeout

integer mem_top;
integer st;
integer cells;
integer wait;
integer req_adr;
integer last_val;
integer rps;
integer crco;
integer crcn;
integer time_wr;
integer time_rd;
integer gen;
integer req_wait_flag;
integer mode_corner;
list destarr;

cout(string in)
{
    llWhisper(0,in);
}

tout(string in)
{
    llSetText(in,<1,0,1>,1);
}

memerr()
{
    cout("Memory error at $"+(string)req_adr+"\nInvalid data or data pipe error!");
}

msend(integer adr, string str)
{
    integer n = adr / cell_size; //integer divide
    n = llList2Integer(destarr,n);
    //llOwnerSay("Debug: $"+(string)adr+" resolved to cell #"+(string)n);
    llMessageLinked(n,adr,str,memory_io);
}

rnd_put()
{
    req_adr = llFloor(llFrand((float)mem_top));
    if (mode_corner)
        req_adr = llFloor(llFrand(cells)) * cell_size;
    last_val = llCeil(llFrand(0xEF00FF00));
    string vs = "PUT "+(string)last_val;
    tout((string)req_adr+vs);
    msend(req_adr,vs);
    wait = 1;
}

req_last()
{
    tout("GET "+(string)req_adr);
    msend(req_adr,"GET");
    wait = 3;
}

callback_a(integer x)
{
    if (x == last_val) {
        tout("Successfully received value: $"+(string)req_adr+" = "+(string)x);
        wait = 0;
    } else memerr();
    //llResetTime(); -- we don't need it in mono
}

callback_b(integer x)
{
    if (x == last_val) {
        tout("Successfully received value: $"+(string)req_adr+" = "+(string)x);
        wait = 0;
        rps++;
        rnd_put();
    } else memerr();
}

test_put()
{
    llSetTimerEvent(0.0);
    if (++req_adr >= mem_top) {
        time_wr = llGetUnixTime() - time_wr;
        req_wait_flag = 0;
        cout("Writing phase done!\nCRC32 = "+(string)crco);
        cout("Writing time: "+(string)time_wr+" sec.");
        cout("Reading phase...");
        time_rd = llGetUnixTime();
        req_adr = -1;
        crcn = 0;
        test_get();
        return;
    }
    last_val = llCeil(llFrand(0xEF00FF00));
    crco += last_val;
    //llSay(icChan,"PUT "+(string)req_adr+" "+(string)last_val);
    msend(req_adr,"PUT "+(string)last_val);
    tout("WRITE $"+(string)req_adr);
    req_wait_flag = 1;
    llSetTimerEvent(reqtime);
}

test_get()
{
    llSetTimerEvent(0.0);
    if (++req_adr >= mem_top) {
        time_rd = llGetUnixTime() - time_rd;
        req_wait_flag = 0;
        cout("Reading phase done!\nCRC32 = "+(string)crcn);
        cout("Reading time: "+(string)time_rd+" sec.");
        tout("CRC.1="+(string)crco+"\nCRC.2="+(string)crcn+"\nTime.WR="+(string)time_wr+"\nTime.RD="+(string)time_rd);
        cout("Test complete");
        st = 7;
        return;
    }
    //llSay(icChan,"GET "+(string)req_adr);
    msend(req_adr,"GET");
    tout("READ $"+(string)req_adr);
    req_wait_flag = 2;
    llSetTimerEvent(reqtime);
}

callback_c(integer x)
{
    crcn += x;
    req_wait_flag = 0;
    llSetTimerEvent(0.0);
    test_get();
}

default
{
    state_entry()
    {
        tout("");
        cout("-------------------------------------------------");
        cout("SL DRAM Tester "+version);
        cout("-------------------------------------------------");
        cells = llGetNumberOfPrims() - 1; // ASSUME there's no additional prims!!
        mem_top = cell_size * cells;
        cout("Have "+(string)cells+" DRAM cells");
        cout("mem_top at $"+(string)mem_top);
        cout("Full capacity is "+(string)(mem_top*4/1024)+"KB or "+(string)(mem_top*4)+" bytes.");
        llMessageLinked(LINK_SET,0,"RESET",memory_io);
        integer i = cells;
        destarr = [];
        while (i--) destarr += [-100];
        llOwnerSay("Debug: "+(string)llGetListLength(destarr)+" records destinations array initialized.");
        i = cells + 2;
        integer j;
        string vs;
        while (--i) {
            vs = llGetLinkName(i);
            if (llGetSubString(vs,0,1) == cell_prefix) {
                j = (integer)llGetSubString(vs,2,-1) - 1;
                if ((j < 0) || (j > cells))
                    llOwnerSay("Invalid name: "+vs);
                else
                    destarr = llListReplaceList(destarr,[i],j,j);
            }
        }
        llOwnerSay("Debug: "+(string)destarr);
        st = 0;
    }
    
    touch_start(integer p)
    {
        if (llDetectedKey(0) != llGetOwner()) return;
        if (st == 0) {
            st = 1;
            cout("resizing");
            llMessageLinked(LINK_SET,cell_size,"RESIZE",memory_io);
            return;
        } else if (st == 1) {
            mode_corner = 1;
            llSetTimerEvent(1.5);
            cout("begin 'corner test'");
            wait = 0;
            st = 2;
        } else if (st == 2) {
            llSetTimerEvent(0.0); // for queue freeeing reason
            cout("pause");
            st = 3;
        } else if (st == 3) {
            mode_corner = 0;
            cout("Speed test begin");
            llSetTimerEvent(sttime);
            rps = 0;
            rnd_put();
            st = 4;
        } else if (st == 4) {
            cout("Stop all");
            llSetTimerEvent(0.0);
            tout("");
            st = 5;
        } else if (st == 5) {
            mem_top = cell_size + 100; //debug only!
            cout("R/W Test begins!\nWriting phase...");
            gen = 1;
            req_adr = -1;
            crco = 0;
            time_wr = llGetUnixTime();
            wait = 1;
            req_wait_flag = 0;
            test_put();
            st = 6;
        } else if (st == 7) {
            cout("ready");
            llSetTimerEvent(0.0);
            st = 100; //debug, no return
        }
    }
    
    timer()
    {
        llOwnerSay("tick");
        if (st == 2) {
            if (wait == 0) rnd_put();
            else if (wait == 1) req_last();
        } else if (st == 4) {
            float r = (float)rps / sttime;
            cout("RPS = "+(string)r);
            rps = 0;
        }
        if (req_wait_flag == 1) {
            //resend data
            string vs = "PUT "+(string)last_val;
            cout("Resend: "+(string)req_adr+vs);
            msend(req_adr,vs);
        } else if (req_wait_flag == 2) {
            //repeat request for address
            string vs = "GET "+(string)req_adr;
            cout("Repeat: "+vs);
            msend(req_adr,"GET");
        }
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        if ((id != memory_io) || (!wait)) return;
        if (llGetSubString(str,0,2) == "VAL") {
            if (num == req_adr) {
                integer x = (integer)llGetSubString(str,4,-1);
                if (st == 2) callback_a(x);
                else if (st == 4) callback_b(x);
                else if (st == 6) callback_c(x);
            } else {
                tout("Memory error at request $"+(string)req_adr+" : received of $"+(string)num);
            }
        } else if (llGetSubString(str,0,1) == "OK") {
            if (num == req_adr) {
                if (req_wait_flag == 1) req_wait_flag = 0;
                if (st == 4) {
                    wait = 2;
                    rps++;
                    req_last();
                } else if (st == 6) {
                    test_put();
                }
            } else
                tout("Memory error: $"+(string)req_adr+" sent, received OK for $"+(string)num);
        }
    }
    
    on_rez(integer p)
    {
        llResetScript();
    }
}
