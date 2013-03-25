//    DRAM tester for LSL
//    Copyright (C) 2012-2013  Elizabeth Walpanheim
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 2 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.

string version = "ver. 6.3 rev 2013.069";
/*
string objname = "SDMC simple 4";
vector dpos = <-5, 0, 0.5>;
vector rpos = <0.2, 0, 0>;
vector spos = <0, 0, 0.15>;
vector cpos;
*/
//integer icChan = -987110; //old channel
integer icChan = -967116; // 4R3 and abowe
string icname = "icmem";

integer cell_size = 2600;
integer cells = 64;

float sttime = 26.0; //speed test "frame" time
float reqtime = 6.0; //single request timeout

key DRAM_ControlUUID = "10101010-0000-0000-0000-eeeeeeee5555";

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
//integer gen;
integer req_wait_flag;
integer mode_corner;
integer tout_cnt;
key owner;
key self;
integer hListen;
integer range_bottom;
integer range_top;

cout(string in)
{
    llOwnerSay(in);
}

tout(string in)
{
    //llSetText(in,<1,0,1>,1);
    if ((st == 4) || (st == 6)) {
        if (++tout_cnt >= 9) {
            tout_cnt = 0;
            llSay(21,in);
        }
    } else llSay(21,in);
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

callback_c(integer x)
{
    crcn += x;
    req_wait_flag = 0;
    //llSetTimerEvent(0.0);
    test_get();
}

test_put()
{
    llSetTimerEvent(0.0);
    if (++req_adr >= mem_top) {
        time_wr = llGetUnixTime() - time_wr;
        cout("Writing phase done!\nCRC32 = "+(string)crco);
        cout("Writing time: "+(string)time_wr+" sec.");
        cout("Reading phase...");
        prepare_rd_test_vars();
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

finally()
{
    req_wait_flag = 0;
    st = 7;
    string vs = "CRC.1="+(string)crco+"\nCRC.2="+(string)crcn+"\nTime.WR="+(string)time_wr+"\nTime.RD="+(string)time_rd;
    tout(vs);
    cout(vs);
    cout("Test complete");
    cout("Real time consumed: "+(string)llGetAndResetTime());
}

test_get()
{
    llSetTimerEvent(0.0);
    if (++req_adr >= mem_top) {
        time_rd = llGetUnixTime() - time_rd;
        cout("Reading phase done!\nCRC32 = "+(string)crcn);
        cout("Reading time: "+(string)time_rd+" sec.");
        finally();
        return;
    }
    llSay(icChan,"GET "+(string)req_adr);
    tout("READ $"+(string)req_adr);
    req_wait_flag = 2;
    llSetTimerEvent(reqtime);
}

prepare_rw_vars()
{
    req_wait_flag = 0;
    llListenControl(hListen,TRUE);
    if (range_top) {
        req_adr = range_bottom;
        mem_top = range_top;
    } else
        req_adr = -1;
    wait = 1;
}

prepare_wr_test_vars()
{
    crco = 0;
    prepare_rw_vars();
    time_wr = llGetUnixTime();
}

prepare_rd_test_vars()
{
    crcn = 0;
    prepare_rw_vars();
    time_rd = llGetUnixTime();
}

fTouch()
{
    if (st == 0) {
        st = 1;
        cout("resizing");
        llSay(icChan,"RESIZE "+(string)cell_size);
        return;
    } else if (st == 1) {
        mode_corner = 1;
        llListenControl(hListen,TRUE);
        llSetTimerEvent(1.5);
        cout("go");
        wait = 0;
        st = 2;
    } else if (st == 2) {
        llListenControl(hListen,FALSE);
        llSetTimerEvent(0.0); // for queue freeeing reason
        cout("pause");
        st = 3;
    } else if (st == 3) {
        mode_corner = 0;
        llListenControl(hListen,TRUE);
        cout("Speed test begin");
        llSetTimerEvent(sttime);
        rps = 0;
        rnd_put();
        st = 4;
    } else if (st == 4) {
        llListenControl(hListen,FALSE);
        cout("Stop all");
        llSetTimerEvent(0.0);
        tout("");
        st = 5;
    } else if (st == 5) {
        range_top = 0;
        mem_top = cell_size + 100; //debug only!
        cout("R/W Test begins!\nWriting phase...");
        st = 6;
        prepare_wr_test_vars();
        test_put();
    } else if (st == 6) {
        llOwnerSay("Emergency stop engaged!");
        llListenControl(hListen,FALSE);
        wait = 0;
        st = 5;
        llSetTimerEvent(0.0);
    } else if (st == 7) {
        cout("Re-read");
        st = 6;
        prepare_rd_test_vars();
        test_get();
    }/* else if (st == 8) {
        cout("deleting cells...");
        llSay(icChan,"DELETE ");
        st = 100;
    }*/
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
        self = llGetKey();
        owner = llGetOwner();
        llSleep(2.0);
        mem_top = cells * cell_size;
        cout("Have "+(string)cells+" DRAM cells");
        cout("mem_top at $"+(string)mem_top);
        cout("Result capacity is "+(string)(mem_top*4/1024)+"KB or "+(string)(mem_top*4)+" bytes.");
        llSay(icChan,"RESET");
        st = 0;
        hListen = llListen(icChan,icname,"","");
        llListenControl(hListen,FALSE);
        cout("Prepared.");
    }
    
    touch_start(integer p)
    {
        if (llDetectedKey(0) != owner) return;
        fTouch();
    }
    
    timer()
    {
        //llOwnerSay("tick");
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
        if (llGetOwnerKey(id) != owner) return;
        list lt = llParseString2List(msg,[" "],[]);
        string ans = llList2String(lt,0);
        if ((ans == "VAL") && (llList2Key(lt,3) == self)) {
            if (llList2Integer(lt,1) == req_adr) {
                if (st == 2) callback_a(llList2Integer(lt,2));
                else if (st == 4) callback_b(llList2Integer(lt,2));
                else if (st == 6) callback_c(llList2Integer(lt,2));
            } else {
                tout("Memory error at request $"+(string)req_adr+" : received of $"+(string)llList2Integer(lt,1));
            }
        } else if ((ans == "OK") && (llList2Key(lt,2) == self)) {
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
    
    link_message(integer sender, integer num, string str, key id)
    {
        if (id != DRAM_ControlUUID) return;
        llOwnerSay("Command '"+str+"' arg="+(string)num);
        if (str == "touch")
            fTouch();
        else if (llGetSubString(str,0,0) == "%") {
            list vl = llParseString2List(str,["%"],[]);
            llOwnerSay("Performing range-test $"+llList2String(vl,0)+" : $"+llList2String(vl,1));
            range_bottom = llList2Integer(vl,0) - 1;
            range_top = llList2Integer(vl,1) + 1;
            prepare_wr_test_vars();
            st = 6;
            test_put();
        }
    }
    
    on_rez(integer p)
    {
        llOwnerSay("Update keys...");
        llSay(icChan,"TRCHECK");
        self = llGetKey();
    }
}

