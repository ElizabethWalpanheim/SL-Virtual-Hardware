/*
    MCPU processor ERAM chip model script
    written by Elizabeth Walpanheim
    
    MCPU (C) Elizabeth Walpanheim, 2009-2012
    MCPU LSL model (C) Elizabeth Walpanheim, 2011-2012
    MCPU ERAM LSL model (C) Elizabeth Walpanheim, 2012
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// *** CONSTANTS ***
string version = "v 0.1 rev 8";
integer memory_channel = -423531;
vector msg_color = <0.0, 1.0, 0.0>;
integer use_stat = 1;
integer stat_delay = 5; // the length of update_stat() cycle
integer max_miss_stat = 10; // maximum number of idle cycles to deactivate update_stat()

// *** VARIABLES ***
integer mem_low; // start address
integer mem_size; // SIZE of memory
integer mem_hi;
key owner;
key self;
list memory;
integer mem_bytesize;
integer h_Lst;
integer inactive;
integer rx;
integer tx;
integer last_trans;
integer cnt_idle;
integer full_total;

// *** CODE ***

debug(string msg)
{
    llOwnerSay("ERAM Debug: "+msg);
}

mem_init()
{
    integer i;
    memory = [];
    for (i=0; i<mem_size; i++) memory += [0];
}

update_stat()
{
    if (inactive) {
        llSetText("",ZERO_VECTOR,0);
        return;
    }
    if ((rx+tx) == last_trans) {
        if (cnt_idle <= max_miss_stat) cnt_idle++;
        else {
            llSetText("Idle",msg_color,1);
            rx = 0;
            tx = 0;
            last_trans = 0;
            full_total = 0;
        }
        return;
    }
    last_trans = rx + tx;
    full_total += last_trans;
    string vs = "ACTIVE\n$"+(string)mem_low+" : $"+(string)mem_hi+"\n";
    vs += "Within last "+(string)stat_delay+" seconds:\n";
    vs += "RX = "+(string)rx+"  TX = "+(string)tx+"\n";
    float trn = (float)(last_trans) / (float)stat_delay;
    vs += (string)trn+" TPS\nTotal transactions: "+(string)(full_total)+"\n";
    vs += "Heap space used: "+(string)mem_bytesize+" bytes.\n";
    vs += "Free space: "+(string)llGetFreeMemory()+" bytes.\n";
    //llOwnerSay(vs);
    // TODO: maybe add the zero cells counter
    llSetText(vs,msg_color,1);
    rx = 0;
    tx = 0;
}

activate()
{
    inactive = 0;
    h_Lst = llListen(memory_channel,"","","");
    rx = 0;
    tx = 0;
    last_trans = 0;
    cnt_idle = 0;
    full_total = 0;
    llSetTimerEvent((float)stat_delay);
    llResetTime();
}

default
{
    state_entry()
    {
        llSetText("",ZERO_VECTOR,0);
        llOwnerSay("Initialising...");
        owner = llGetOwner();
        self = llGetKey();
        memory = [];
        list l = llParseString2List(llList2String(llGetPrimitiveParams([PRIM_DESC]),0),[" "],[]);
        mem_low = (integer)llList2String(l,0);
        mem_size = (integer)llList2String(l,1);
        mem_hi = mem_low + mem_size - 1;
        mem_bytesize = llGetFreeMemory();
        mem_init();
        mem_bytesize -= llGetFreeMemory();
        debug("low = "+(string)mem_low+"  size = "+(string)mem_size);
        activate();
        llOwnerSay("Done. "+(string)llGetFreeMemory()+" bytes left.");
    }
    
    listen(integer chan, string name, key id, string msg)
    {
        if (id == self) return; // just for lulz
        if (llGetOwnerKey(id) != owner) return;
        cnt_idle = 0;
        list tml = llParseString2List(msg,[" "],[]);
        debug("signal("+llDumpList2String(tml,", ")+")");
        string vs = llList2String(tml,0);
        if (vs == "FULLRESET") {
//            mem_init();
            debug("fullreset() received");
            llResetScript();
        } else {
            integer a = llList2Integer(tml,1);
            if ((a < mem_low) || (a > mem_hi)) {
                debug("Address is out of my range ("+(string)mem_low+" - "+(string)mem_hi+")!!");
                return;
            }
            a -= mem_low;
            if (vs == "GET") {
                llSay(memory_channel,"VAL "+(string)llList2Integer(memory,a));
                tx++;
            } else if (vs == "PUT") {
                memory = llListReplaceList(memory,[llList2Integer(tml,2)],a,a);
                rx++;
            } else
                debug("Unknown command '"+vs+"'");
        }
    }
    
    touch_start(integer p)
    {
        if (llDetectedKey(0) != owner) return;
        if (inactive) {
            llSay(0,"Chip activated");
            activate();
        } else if (h_Lst) {
            inactive = 1;
            llListenRemove(h_Lst);
            h_Lst = 0;
            llSetTimerEvent(0);
            llResetTime();
            llSay(0,"Chip suspended");
        } else {
            llSay(0,"Chip internal error!");
            //llSleep(1.0);
            llResetScript();
        }
        update_stat();
    }
    
    timer()
    {
        if (use_stat) update_stat();
    }
}
