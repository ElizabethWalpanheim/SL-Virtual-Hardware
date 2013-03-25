//    DRAM controller for LSL
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
integer cells = 24;
integer cell_size = 2600;
string base_version = "ver. 6.3 rev 2013.069";
string build = "build 001";
string icname = "icmem";


float reqtime = 6.0; //single request timeout
integer icChan = -967116; // 4R3 and abowe
key DRAM_ControlUUID = "10101010-0000-0000-0000-eeeeeeee5555";

integer mem_top;
integer req_adr;
integer last_val;
integer req_wait_flag;
key owner;
key self;
integer hListen;
integer sender;

cout(string in)
{
    llSay(0,in);
}

integer checkaddress(integer a)
{
    //TODO
    return 0;
}

ukeys()
{
    llSay(icChan,"TRCHECK");
    self = llGetKey();
    owner = llGetOwner();
}

uget(integer addr)
{
    if (checkaddress(addr)) return;
    llListenControl(hListen,TRUE);
    req_wait_flag = 2;
    req_adr = addr;
    llSay(icChan,"GET "+(string)req_adr);
    llSetTimerEvent(reqtime);
}

uput(integer addr, integer val)
{
    if (checkaddress(addr)) return;
    llListenControl(hListen,TRUE);
    req_wait_flag = 1;
    req_adr = addr;
    last_val = val;
    llSay(icChan,"PUT "+(string)req_adr+" "+(string)last_val);
    llSetTimerEvent(reqtime);
}

default
{
    state_entry()
    {
        cout("SL DRAM "+base_version);
        cout(build);
        ukeys();
        mem_top = cells * cell_size;
        cout("Have "+(string)cells+" DRAM cells");
        cout("mem_top at $"+(string)mem_top);
        cout("Result capacity is "+(string)(mem_top*4/1024)+"KB or "+(string)(mem_top*4)+" bytes.");
        llSay(icChan,"RESET");
        hListen = llListen(icChan,icname,"","");
        //llListenControl(hListen,FALSE);
        cout("Initializing memory...");
        llSleep(2.0);
        llSay(icChan,"RESIZE "+(string)cell_size);
    }
    
    timer()
    {
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
        } else {
            req_wait_flag = 0;
            llSetTimerEvent(0.0);
        }
    }
    
    listen(integer ch, string nam, key id, string msg)
    {
        if (req_wait_flag == 0) return;
        if (llGetOwnerKey(id) != owner) return;
        list lt = llParseString2List(msg,[" "],[]);
        string ans = llList2String(lt,0);
        //llOwnerSay(msg);
        if ((ans == "VAL") && (llList2Key(lt,3) == self)) {
            if (llList2Integer(lt,1) == req_adr) {
                if (req_wait_flag == 2) req_wait_flag = 0;
                //RECEIVED
                llMessageLinked(sender,llList2Integer(lt,2),"V",DRAM_ControlUUID);
            } else {
                cout("Memory error at request $"+(string)req_adr+" : received of $"+(string)llList2Integer(lt,1));
            }
        } else if ((ans == "OK") && (llList2Key(lt,2) == self)) {
            if (llList2Integer(lt,1) == req_adr) {
                if (req_wait_flag == 1) req_wait_flag = 0;
                //TRANSMITTED
                llMessageLinked(sender,0,"K",DRAM_ControlUUID);
            } else
                cout("Memory error: $"+(string)req_adr+" sent, received OK for $"+(string)llList2Integer(lt,1));
        }
    }
    
    link_message(integer sdr, integer num, string str, key id)
    {
        if (id != DRAM_ControlUUID) return;
        //llOwnerSay("Command '"+str+"' arg="+(string)num);
        string pp = llGetSubString(str,0,0);
        if (pp == "W") {
            //write
            sender = sdr;
            uput(num,(integer)llGetSubString(str,1,-1));
        } else if (pp == "R") {
            //read
            sender = sdr;
            uget(num);
        } else if (pp == "S") {
            //stop
            llListenControl(hListen,FALSE);
        }
    }
    
    on_rez(integer p)
    {
        ukeys();
        cout("RAM alive");
    }
}
