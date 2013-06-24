/*
    Real 80x25 display
    main script
    
    (C) Elizabeth Walpanheim, 2012-2013
    
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

string version = "0.3.1 bld 135";
float tau = 1.0;
integer mChan = -101006;
integer xChan = -102006;
integer access_pin = 103600;
string display_script = "ZZText-M";
list tbuf;
integer on;
vector cursor;
integer buflg;
integer curmode;
list controller;
integer blk_frm_cnt;

string genstr(string char, integer len)
{
    string s;
    while (--len >= 0) s += char;
    return s;
}

string strnorm(string in)
{
    integer i = llStringLength(in);
    if (i > 80) return (llGetSubString(in,0,79));
    else {
        for (;i < 80; i++) in += " ";
    }
    return in;
}

dir_outstr_nw(string str, integer row)
{
    if ((row < 0) || (row > 24)) return;
    llMessageLinked(llList2Integer(controller,row),9000100+row,str,NULL_KEY);
}

init_buf()
{
    integer i;
    tbuf = [];
    string vs = genstr(" ",80);
    for (; i<25; i++) tbuf += [vs];
    cursor = <0,0,0>;
}

clear()
{
    //integer i;
    //string vs = genstr(" ",80);
    /*for (; i<200; i++)
        llMessageLinked(LINK_ALL_OTHERS,10000+i,vs,NULL_KEY);*/
    //for (; i<25; i++) dir_outstr_nw(vs,i);
    llMessageLinked(LINK_ALL_OTHERS,-601,"clear",NULL_KEY);
}

list strslice(string in, integer len)
{
    integer i;
    integer k = llCeil((float)llStringLength(in) / (float)len);
    list vl;
    while (i<k) vl += [llGetSubString(in,i*len,(++i)*len-1)];
    return vl;
}

wbuf(string str, integer row)
{
    if ((row < 0) || (row > 24)) return;
    tbuf = llListReplaceList(tbuf,[strnorm(str)],row,row);
}

string rbuf(integer row)
{
    if ((row < 0) || (row > 24)) return ("");
    return (llList2String(tbuf,row));
}

scrollbuf(integer val)
{
    if (val == 0) return;
    if (llAbs(val) > 24) {
        init_buf();
        return;
    }
    string vs = genstr(" ",80);
    if (val > 0) {
        tbuf = llList2List(tbuf,val,24);
        while (--val >= 0) tbuf += [vs];
    }
    buflg = 1;
}

drawbuf()
{
    integer i;
    for (; i<25; i++) dir_outstr_nw(llList2String(tbuf,i),i);
    buflg = 0;
}

sprint(string str, integer mode)
{
    buflg = 1;
    //llOwnerSay("sprint(): '"+str+"' mode "+(string)mode);
    if (cursor.y > 24) {
        cursor.y = 24;
        scrollbuf(1);
    }
    if (mode == 0) { // no wrap, single string, cursor to next string
        cursor.x = 0;
        wbuf(str,(integer)(cursor.y));
        cursor += <0,1,0>;
    } else if (mode == 1) { // wrap, cursor to next empty string
        list vl = strslice(str,80);
        integer i;
        integer k = llGetListLength(vl);
        do {
            sprint(llList2String(vl,i++),0);
        } while(i<k);
    }
}

init_rowcontrol()
{
    integer i = llGetNumberOfPrims() + 1;
    integer j = 25;
    string vs;
    controller = [];
    while (--j >= 0) controller += [LINK_ALL_OTHERS];
    while (i) {
        vs = llGetLinkName(--i);
        if (llGetSubString(vs,0,2) == "led") {
            j = (integer)llGetSubString(vs,3,-1);
            if ((j >= 0) && (j < 25))
                controller = llListReplaceList(controller,[i],j,j);
        }
    }
    //llOwnerSay((string)controller);
}

cmd_scripts(string cmd)
{
    integer i = 25;
    integer j;
    cmd += "|" + display_script;
    llMessageLinked(LINK_ALL_OTHERS,-601,"!REMOVE!",NULL_KEY);
    while (i) {
        j = llList2Integer(controller,--i);
        llMessageLinked(j,9000100+i,cmd,llGetLinkKey(j));
    }
}

place_scripts()
{
    integer i = 25;
    key tk;
    while (i) {
        tk = llGetLinkKey(llList2Integer(controller,--i));
        llRemoteLoadScriptPin(tk,display_script,access_pin,0,0);
        //llOwnerSay("# "+(string)i+" ["+(string)tk+"] placed");
    }
}

default
{
    state_entry()
    {
        llSay(0,"Computer terminal monitor 80x25\n(C) Elizabeth Walpanheim, 2012");
        llSay(0,"ver. "+version);
        init_rowcontrol();
        clear();
        init_buf();
        on = 1;
        //cursor = <0,0,0>;
        buflg = 0;
        llListen(mChan,"","","");
        llListen(xChan,"","","");
        llListen(0,"",llGetOwner(),"");
        llSetTimerEvent(tau);
        llSay(0,"Monitor ready!");
    }

    touch_start(integer total_number)
    {
        if (llDetectedKey(0) != llGetOwner()) return;
        on = 1 - on;
        if (on) {
            llSay(0,"Monitor on");
            drawbuf();
        } else {
            llSay(0,"Monitor off");
            clear();
        }
    }

    listen(integer chan, string name, key id, string msg)
    {
        if (chan == 0) {
            if (msg == "monitor reload") {
                on = 0;
                integer tt = llGetUnixTime();
                llSay(0,"Monitor reloading!\nThis process take some time, from 1.5 to 3 minutes!");
                llSay(0,"Please wait!");
                llSay(0,"Core init...");
                llMessageLinked(LINK_ALL_OTHERS,-602,"RESET",NULL_KEY);
                llSleep(2.0);
                init_rowcontrol();
                cmd_scripts("remove");
                llSleep(2.0);
                llSay(0,"Stage 1...");
                place_scripts();
                llSay(0,"Stage 2...");
                cmd_scripts("deploy");
                llSay(0,"Finalize...");
                clear();
                init_buf();
                llSay(0,"Monitor reloaded in "+(string)(llGetUnixTime()-tt)+" sec!");
                curmode = 0;
                llSay(0,"You can safely turn on your monitor if all status LEDs are off!");
            } else if (msg == "monitor shutdown") {
                on = 0;
                llSay(0,"All unneccessary items will be removed in a few seconds!");
                clear();
                llSleep(2.0);
                cmd_scripts("remove");
                init_buf();
            } else {
                //sprint(msg,1);
            }
            return;
        }
        if (llGetOwnerKey(id) != llGetOwner()) return;
        if ((chan == mChan) && (on)) {
            if (curmode == -100) {
                wbuf(msg,blk_frm_cnt++);
                if (blk_frm_cnt > 24) {
                    blk_frm_cnt = 0;
                    drawbuf();
                }
            } else if (curmode >= 0) {
                sprint(msg,curmode);
            }
        } else if ((chan == xChan) && (on)) {
            llOwnerSay("Command received: "+msg);
            list vl = llParseString2List(msg,["|"],[]);
            string cmd = llList2String(vl,0);
            if (cmd == "setmode") {
                curmode = (integer)llList2String(vl,1);
                if (curmode == -100) blk_frm_cnt = 0;
            } else if (cmd == "autoretrace") {
                if (1 > (integer)llList2String(vl,1)) llSetTimerEvent(0);
                else llSetTimerEvent(tau);
                llResetTime();
            } else if (cmd == "clear") {
                string v = llList2String(vl,1);
                if (v == "all") {
                    init_buf();
                    clear();
                } else if (v == "buf") {
                    init_buf();
                    blk_frm_cnt = 0;
                } else if (v == "scr") clear();
            } else if (cmd == "change_color") {
                vector v = (vector)llList2String(vl,1);
                llMessageLinked(LINK_ALL_OTHERS,-601,"color|"+(string)v,NULL_KEY);
            } else if (cmd == "blank_out") {
                llMessageLinked(LINK_ALL_OTHERS,-601,"solid",NULL_KEY);
            } else if (cmd == "selfdelete") {
                llDie();
            }
        }
    }

    timer()
    {
        if (buflg) drawbuf();
    }
}

