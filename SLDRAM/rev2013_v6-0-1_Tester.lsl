string version = "ver. 6.0 rev 2013.048";
/*
string objname = "SDMC simple 4";
vector dpos = <-5, 0, 0.5>;
vector rpos = <0.2, 0, 0>;
vector spos = <0, 0, 0.15>;
vector cpos;
*/
//integer icChan = -987110; //old channel
integer icChan = -967116; // 4R3 and abowe

integer cell_size = 2600;
integer cells = 63;

float sttime = 26.0; //speed test "frame" time
float reqtime = 16.0; //single request timeout

integer mem_top;
integer st;
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

rnd_put()
{
    req_adr = llFloor(llFrand((float)mem_top));
    if (mode_corner)
        req_adr = llFloor(llFrand(cells)) * cell_size;
    last_val = llCeil(llFrand(0xEF00FF00));
    string vs = "PUT "+(string)req_adr+" "+(string)last_val;
    tout(vs);
    llSay(icChan,vs);
    wait = 1;
}

req_last()
{
    string vs = "GET "+(string)req_adr;
    tout(vs);
    llSay(icChan,vs);
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
    llSay(icChan,"PUT "+(string)req_adr+" "+(string)last_val);
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
    llSay(icChan,"GET "+(string)req_adr);
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
        llSay(icChan,"TRCHECK");
        llSleep(2.0);
        mem_top = cells * cell_size;
        cout("Have "+(string)cells+" DRAM cells");
        cout("mem_top at $"+(string)mem_top);
        cout("Result capacity is "+(string)(mem_top*4/1024)+"KB or "+(string)(mem_top*4)+" bytes.");
        llSay(icChan,"RESET");
        st = 0;
        llListen(icChan,"","","");
        cout("Prepared.");
    }
    
    touch_start(integer p)
    {
        if (llDetectedKey(0) != llGetOwner()) return;
        if (st == 0) {
            st = 1;
            cout("resizing");
            llSay(icChan,"RESIZE "+(string)cell_size);
            return;
        } else if (st == 1) {
            mode_corner = 1;
            llSetTimerEvent(1.5);
            cout("go");
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
            st = 8;
        } else if (st == 8) {
            cout("deleting cells...");
            llSay(icChan,"DELETE ");
            st = 100;
        }
        //llResetTime(); -- we don't need it in mono
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
            string vs = "PUT "+(string)req_adr+" "+(string)last_val;
            cout("Resend: "+vs);
            llSay(icChan,vs);
        } else if (req_wait_flag == 2) {
            //repeat request for address
            string vs = "GET "+(string)req_adr;
            cout("Repeat: "+vs);
            llSay(icChan,vs);
        }
    }
    
    listen(integer ch, string nam, key id, string msg)
    {
        if (!wait) return;
        if (llGetOwnerKey(id) != llGetOwner()) return;
        list lt = llParseString2List(msg,[" "],[]);
        string ans = llList2String(lt,0);
        if ((ans == "VAL") && (llList2Key(lt,3) == llGetKey())) {
            if (llList2Integer(lt,1) == req_adr) {
                if (st == 2) callback_a(llList2Integer(lt,2));
                else if (st == 4) callback_b(llList2Integer(lt,2));
                else if (st == 6) callback_c(llList2Integer(lt,2));
            } else {
                tout("Memory error at request $"+(string)req_adr+" : received of $"+(string)llList2Integer(lt,1));
            }
        } else if ((ans == "OK") && (llList2Key(lt,2) == llGetKey())) {
            if (llList2Integer(lt,1) == req_adr) {
                if (req_wait_flag == 1) req_wait_flag = 0;
                if (st == 4) {
                    wait = 2;
                    rps++;
                    req_last();
                } else if (st == 6) {
                    test_put();
                }
            } else
                tout("Memory error: $"+(string)req_adr+" sent, received OK for $"+(string)llList2Integer(lt,1));
        }
    }
    
    on_rez(integer p)
    {
        llResetScript();
    }
}
