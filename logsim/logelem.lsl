/*
  LSCAD LSL dynamic logic simulator
  (C) Elizabeth Walpanheim, 2012
  The code may be licensed under the terms of GNU General Public License version 2

  logic element script
*/

integer debug = 0;
integer review = 12;
integer CtrlChan = 7829;
integer DataChan = -222;
float parttheta = 0.05;
vector partscale = <0.05,0.06,1>;
integer types_qnty = 10;
list types_nm = ["BUF","2AND","2OR","1NOT","2AND-NOT","TRIG","GEN f/4","INSWITCH","LED","DIFF1"];
list types_in = [1,2,2,1,2,3,0,0,1,1];

integer my_type = -1;
list inputs;
list inp_data;
integer inp_q;
integer curpart;
integer mode;
list elem_mem;
integer elem_state;
string elem_sbuf;
key owner;
key self;
integer state_return = 0;
integer timertick;
string output;
integer selected;
integer flg_waitlink;
key tmp_linkcreate;
vector movedelta;
integer wantmove;
integer assigned_chan;

integer bool_keynull(key k)
{
    // The fucking LSL makes the fucking difference between NULL_KEY and empty string
    // even the empty string IS a key and IS valid!!! And NOT EQUAL to fuckin' NULL_KEY!!!
    // What! The! Fuck?! Eh, Lindens?!
    if (k == NULL_KEY) return 1;
    else if (k == "") return 1;
    else if (llStringLength(k) < 36) return 1; // even that >8-[
    else return 0;
}

integer signf(float val)
{
    if (val < 0) return -1;
    else return 1;
}

wdebug(string msg)
{
    if (!debug) return;
    llOwnerSay("DEBUG: "+msg);
}

list targparts(key target)
{
    list r = [PSYS_PART_FLAGS,
                PSYS_PART_TARGET_LINEAR_MASK | PSYS_PART_INTERP_COLOR_MASK,
                PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_DROP,
                PSYS_SRC_TARGET_KEY,target,
                PSYS_PART_START_COLOR,<0,1,0>,
                PSYS_PART_END_COLOR,<1,0,0>,
                PSYS_PART_START_SCALE,partscale,
                PSYS_PART_MAX_AGE,2.0,
                PSYS_SRC_BURST_RATE,0.08,
                PSYS_SRC_BURST_PART_COUNT,3];
    return r;
}

upd_display()
{
    string vs = llList2String(types_nm,my_type) + "\n";
    integer i;
    for (i=0; i<inp_q; i++) {
        vs += (string)i + " --- ";
        if (bool_keynull(llList2Key(inputs,i))) vs += "X";
        else vs += llList2String(inp_data,i);
        vs += "\n";
    }
    vs += "OUT\n" + output;
    if (assigned_chan != 0) vs += "\nassigned to "+(string)assigned_chan;
    llSetText(vs,<1,0,0>,1);
}

glow(integer on)
{
    llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_GLOW,ALL_SIDES,(float)on]);
}

select_self(integer on)
{
    if (on) {
        llShout(CtrlChan,"select|"+(string)self+"|");
        selected = 1;
    } else {
        llShout(CtrlChan,"deselected");
        selected = 0;
    }
    glow(selected);
}

dyn_init()
{
    // init Listeners
    llListen(CtrlChan,"","","");
    llListen(DataChan,"","","");
    llListen(0,"",owner,"");
    if (assigned_chan != 0)
        llListen(assigned_chan,"","","");
    // init timer
    llSetTimerEvent(parttheta);
    timertick = 0;
    llResetTime();
}

init()
{
    llOwnerSay("Review #"+(string)review+"\nUUID = "+(string)llGetKey());
    if ((my_type < 0) || (my_type >= types_qnty)) {
        llSay(0,"Init incorrect");
        state disabled; // that's strange, but script compiled with this o_O
    }
    // init variables
    owner = llGetOwner();
    self = llGetKey();
    integer i = llList2Integer(types_in,my_type);
    inp_q = i;
    inputs = [];
    inp_data = [];
    while (--i >= 0) {
        inputs += [NULL_KEY];
        inp_data += ["0"];
    }
    curpart = 0;
    mode = 0;
    elem_mem = [];
    elem_state = 0;
    elem_sbuf = "0";
    output = "0";
    select_self(0);
    flg_waitlink = 0;
    wantmove = 0;
    assigned_chan = 0;
    // remove statics
    glow(0);
    llParticleSystem([]);
    llSetText(llList2String(types_nm,my_type),<1,0,0>,1.0);
    // init dynamic peripherals
    dyn_init();
    llSay(0,"Init done as "+llList2String(types_nm,my_type));
    llOwnerSay((string)llGetFreeMemory()+" bytes free");
}

string ind(integer no) // shothand function
{
    if ((no < 0) || (no >= inp_q)) {
        wdebug("Invalid access to pin "+(string)no+" in "+(string)inp_q+" pins element!");
        return ("0");
    }
    return (llList2String(inp_data,no));
}

quantum()
{
    //"BUF","2AND","2OR","1NOT","2AND-NOT","TRIG","GEN f/2","INSWITCH"
    if (my_type == 0) {
        output = llList2String(inp_data,0);
    } else if (my_type == 1) {
        if ((ind(0) == "1") && (ind(1) == "1"))
            output = "1";
        else output = "0";
    } else if (my_type == 2) {
        if ((ind(0) == "1") || (ind(1) == "1"))
            output = "1";
        else output = "0";
    } else if (my_type == 3) {
        if (ind(0) == "1") output = "0";
        else output = "1";
    } else if (my_type == 4) {
        if ((ind(0) == "1") && (ind(1) == "1"))
            output = "0";
        else output = "1";
    } else if (my_type == 5) {
        // 3 inputs: Data, Strobe, Count
        if (ind(1) == "1") {
            // most priority on Strobe
            elem_sbuf = ind(0);
        } else if (ind(2) == "1") {
            // count (toggle)
            if (elem_sbuf == "1") elem_sbuf = "0";
            else elem_sbuf = "1";
        }
        output = elem_sbuf;
    } else if (my_type == 6) {
        // gen 1
        if (elem_state > 3) output = "1";
        if (elem_state > 7) {
            output = "0";
            elem_state = 0;
        }
        elem_state++;
    } else if (my_type == 7) {
        // inswitch, nothing to do
    } else if (my_type == 8) {
        // simple led
        if (ind(0) == "1") glow(1);
        else glow(0);
        // simple i/o: output gate
        if (assigned_chan != 0) llShout(assigned_chan,ind(0));
    } else if (my_type == 9) {
        // differential 1 (low to high transition detector)
        if (ind(0) != elem_sbuf) {
            if (ind(0) == "1") {
                output = "1";
            } else {
                output = "0";
            }
            elem_sbuf = ind(0);
        } else output = "0";
    }
    upd_display();
    llShout(DataChan,output);
}

commandpu(string str, key id)
{
    list vl = llParseString2List(str,["|"],[]);
    string cmd = llList2String(vl,0);
    key trg = (key)llList2String(vl,1);
    if ((cmd == "q") && (mode == 1)) {
        quantum();
    } else if (((cmd == "del") && (selected)) || (cmd == "delete_all")) {
        llDie();
        llSleep(10.0);
    } else if ((cmd == "edit") && (bool_keynull(trg))) {
        mode = 0;
        glow(0);
        flg_waitlink = 0;
        wdebug("edit mode engaged");
    } else if ((cmd == "action") && (bool_keynull(trg))) {
        mode = 1;
        select_self(0);
        flg_waitlink = 0;
        wdebug("operational");
        upd_display();
    } else if (cmd == "select") {
        if ((!bool_keynull(trg)) && (flg_waitlink == 1)) {
            flg_waitlink++;
            tmp_linkcreate = trg;
            if (inp_q == 1) {
                // automatically create the link with 1-input elems
                flg_waitlink = 0;
                inputs = llListReplaceList(inputs,[tmp_linkcreate],0,0);
                select_self(0);
                curpart = 0; // reset particles
            } else
                llSay(0,"Say number of input to link to");
            upd_display();
        } else {
            if (trg == self) select_self(1);
            else select_self(0);
        }
    } else if (cmd == "changemind") {
        if ((selected) || (trg == self)) {
            my_type = (integer)llList2String(vl,2);
            init();
        }
    } else if (cmd == "move") {
        wdebug("->"+(string)trg);
        if ((!bool_keynull(trg)) && (trg != self)) return;
        movedelta.x = (float)llList2String(vl,2);
        movedelta.y = (float)llList2String(vl,3);
        movedelta.z = (float)llList2String(vl,4);
        if ((llFabs(movedelta.x) < 10.0) && 
            (llFabs(movedelta.y) < 10.0) && 
            (llFabs(movedelta.z) < 10.0)) {
            // immediately move
            llSetPos(llGetPos()+movedelta);
            wantmove = 0;
        } else wantmove = 1;
    } else if ((cmd == "ln") && (selected) && (mode == 0)) {
        // create link
        llSay(0,"Select another element to begin creating the link");
        flg_waitlink = 1;
        tmp_linkcreate = NULL_KEY;
    } else if ((cmd == "dumplinks") && (trg == self)) {
        llSay(CtrlChan,"reply_links|"+llDumpList2String(inputs,"|"));
    } else if ((cmd == "assign") && (selected)) {
        assigned_chan = (integer)llList2String(vl,1);
        if (assigned_chan != 0) llSay(0,"Assigned simple i/o to channel "+(string)assigned_chan);
        else llSay(0,"Simple i/o channel deactivated.");
    } else if ((flg_waitlink == 2) && ((id == owner) || (llGetOwnerKey(id) == owner))) { // this block MUST be at the end, after all other checks
        if (id != owner) {
            if (llGetSubString(str,0,0) != "%")  //check marker from automatic links creator (board)
                return;
            else
                str = llGetSubString(str,1,-1);
        }
        flg_waitlink = 0;
        if (bool_keynull(tmp_linkcreate)) return;
        integer i = (integer)str;
        wdebug("link creation: link from "+(string)tmp_linkcreate+" Input "+(string)i);
        if ((i < 0) || (i >= inp_q)) return;
        inputs = llListReplaceList(inputs,[tmp_linkcreate],i,i);
        select_self(0);
        upd_display();
        curpart = 0; // reset particles
    }
}

default
{
    state_entry()
    {
        if (state_return) {
            dyn_init();
        } else {
            if (debug) my_type = 0; // debug
            init();
        }
        state_return = 0;
    }

    on_rez(integer p)
    {
        my_type = p;
        init();
    }

    listen(integer chan, string name, key id, string msg)
    {
        if (chan == 0) {
            // owner's control commands
            commandpu(msg,id);
        } else if ((chan == DataChan) && (llGetOwnerKey(id) == owner)) {
            // DATA
            if ((msg != "0") && (msg != "1")) return;
            integer i;
            key vid;
            for (i=0; i<inp_q; i++) {
                vid = llList2Key(inputs,i);
                if ((!bool_keynull(id)) && (vid == id)) {
                    inp_data = llListReplaceList(inp_data,[msg],i,i);
                    i = inp_q; //break
                }
            }
        } else if ((chan == CtrlChan) && (llGetOwnerKey(id) == owner)) {
            // CONTROL
            commandpu(msg,id);
        } else if (chan == assigned_chan) {
            // simple i/o
            if (my_type == 7) {
                //switch, used as gate
                output = llGetSubString(msg,0,0);
            }
        } else {
            llOwnerSay("Input on my channel "+(string)chan+" intercepted. Sender = "+name+" ["+(string)id+"]\n"+msg);
            llOwnerSay("W T F ?!");
        }
    }

    timer()
    {
//        timertick++;
        if (wantmove) state moving;
        if ((curpart < 0) || (curpart >= inp_q)) curpart = 0;
        key vk = llList2Key(inputs,curpart);
        while ((curpart < inp_q) && (bool_keynull(vk))) {
            curpart++;
            vk = llList2Key(inputs,curpart);
        }
        if (!bool_keynull(vk)) {
            llParticleSystem(targparts(vk));
            //wdebug((string)vk);
        } else
            llParticleSystem([]);
        curpart++;
        llResetTime();
    }

    touch_start(integer total_number)
    {
        if (mode == 0) {
            if (selected) select_self(0);
            else select_self(1);
        } else if ((mode == 1) && (my_type == 7)) { // input switch
            if (output == "0") output = "1";
            else output = "0";
            upd_display();
        }
    }
}

state disabled
{
    state_entry()
    {
        llOwnerSay("DISABLED");
    }
    on_rez(integer p)
    {
        my_type = p;
        state_return = 0;
        state default;
    }
}

state moving
{
    state_entry()
    {
        state_return = 1;
        llSetTimerEvent(0.3);
        llResetTime();
    }

    timer()
    {
        vector cp = llGetPos();
        integer chng = 0;
        if (movedelta.x != 0.0) {
            if (llFabs(movedelta.x) < 10.0) {
                // we're near end :)
                cp.x += movedelta.x;
                movedelta.x = 0.0;
            } else {
                cp.x += (float)signf(movedelta.x) * 10.0;
                movedelta.x -= (float)signf(movedelta.x) * 10.0;
            }
            chng++;
        }
        if (movedelta.y != 0.0) {
            if (llFabs(movedelta.y) < 10.0) {
                // we're near end :)
                cp.y += movedelta.y;
                movedelta.y = 0.0;
            } else {
                cp.y += (float)signf(movedelta.y) * 10.0;
                movedelta.y -= (float)signf(movedelta.y) * 10.0;
            }
            chng++;
        }
        if (movedelta.z != 0.0) {
            if (llFabs(movedelta.z) < 10.0) {
                // we're near end :)
                cp.z += movedelta.z;
                movedelta.z = 0.0;
            } else {
                cp.z += (float)signf(movedelta.z) * 10.0;
                movedelta.z -= (float)signf(movedelta.z) * 10.0;
            }
            chng++;
        }
        llResetTime();
        if (chng > 0) llSetPos(cp);
        else {
            llSetTimerEvent(0);
            state default;
        }
    }

    state_exit()
    {
        wantmove = 0;
        movedelta = ZERO_VECTOR;
        wdebug("Leave moving state");
    }
}
