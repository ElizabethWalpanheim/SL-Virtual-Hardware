/*
    Brainfuck language interpreter for LSL
    Copyright (C) 2013  Elizabeth Walpanheim

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

string s_rev = "rev E build 107";
// REVIEW E - optimized for small hand-written programs and maximum performance
// in single-script usage.

integer memtop = 350; //guaranteed (?) 32bit memory cells count
integer monitorChan = -101006;

string printable = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
integer print_offset = 32;
string validchars = "><+-.,[]"; //8

list tape;
list map;
integer ptr;
integer IP;
string outbuf;
string inbuf;
integer inputwait;
integer currop;
string curropch;
integer proglen;
integer busy;
integer PLi;
integer zVal;
integer MP_Memtop;
integer MP_LastAddr; //memory pack enhancer
integer MP_Original; //memory pack enhancer

string note_name;
integer note_line;
key note_query;

debug(string str)
{
    llOwnerSay("DEBUG: "+str);
}

error(string str)
{
    llSay(0,"*ERROR: "+str);
}

say(string str)
{
    llSay(monitorChan,str);
    llSay(0,str);
}

stream(string str)
{
    llSetText(str,<0,1,0>,1);
}

integer mappacki(integer op, integer arg)
{
    arg = (arg << 3) & 0xFFFFFFF8;
    return (arg | op);
}

integer mappack(string char, integer mapdata)
{
    integer x = llSubStringIndex(validchars,char);
    if (x < 0) {
        error("Unrecognized symbol passed into mappack: "+char);
        return 0;
    }
    return (mappacki(x,mapdata));
}

//This function reads map data at 'addr' and passes it result to 
//1. symbol code -> 'currop' global var
//2. argument -> return value
integer readmap(integer addr)
{
    integer x = llList2Integer(map,addr);
    currop = x & 0x00000007;
    return (x >> 3);
}

integer readoponly(integer addr)
{
    integer x = llList2Integer(map,addr);
    return (x & 0x00000007);
}

//Speedy and less memory hungry due to lack of passing arguments
integer prog_nextclose()
{
    integer i = IP;
    integer sub = 0;
    integer ss;
    while (++i < proglen) {
        ss = readoponly(i);
        if (ss == 6) sub++;
        else if (ss == 7) sub--;
        if (sub < 0) return i;
    }
    return -1;
}

//Speedy and less memory hungry due to lack of passing arguments
integer prog_nextopen()
{
    integer i = IP;
    integer sub = 0;
    integer ss;
    while (--i >= 0) {
        ss = readoponly(i);
        if (ss == 7) sub++;
        else if (ss == 6) sub--;
        if (sub < 0) return i;
    }
    return -1;
}

integer expand(integer newtop)
{
    //debug("expand() called with arg="+(string)newtop);
    if (newtop > memtop) {
        error("Can't expand beyound memory limit!");
        return 0;
    }
    integer i = llGetListLength(tape);
    if (newtop < i) return 1;
    i = newtop - i + 1;
    while (i--) tape += [0];
    debug("new tape length="+(string)llGetListLength(tape)+"; bytes free="+(string)llGetFreeMemory());
    return 1;
}

integer load(integer x)
{
    if (x < 0) {
        error("Accessing (READ) a cell with address number below zero!");
        return 0;
    }
    MP_LastAddr = x;
    integer m = (x % 4) * 8;
    x = x / 4;
    if (x >= llGetListLength(tape)) {
        //debug("Accessing (READ) a cell beyound current limit, returning zero");
        MP_Original = 0;
        return 0;
    }
    MP_Original = llList2Integer(tape,x);
    x = MP_Original >> m;
    return (x & 0x000000FF);
}

integer store(integer val, integer addr)
{
    if (addr < 0) {
        error("Accessing (WRITE) a cell with address number below zero!");
        return 0;
    }
    if (MP_LastAddr != addr) load(addr); //do it before possibly expanding to elliminate one List access inside load()
    integer y = addr / 4;
    if (y >= llGetListLength(tape)) {
        //debug("Accessing (WRITE) a cell beyound current limit, expanding...");
        if (expand(y))
            return(store(val,addr));
        else {
            error("Can't expand the tape!");
            return 0;
        }
    }
    //TODO: clean it!
    y = (addr % 4) * 8;
    addr = ~(0x000000FF << y);
    MP_Original = (MP_Original & addr) | (val << y);
    addr = MP_LastAddr / 4;
    tape = llListReplaceList(tape,[MP_Original],addr,addr);
    return 1;
}

outp(integer x)
{
    string ch;
    if ((llStringLength(outbuf) > 254) || (x == 10) || (x == 13)) {
        say(outbuf);
        outbuf = "";
        return;
    }
    x -= print_offset;
    if ((x < 0) || (x >= llStringLength(printable))) {
        error("Unprintable code pumped to output: "+(string)(x+print_offset));
        return;
    }
    ch = llGetSubString(printable,x,x);
    debug(ch);
    outbuf += ch;
}

integer code_input()
{
    string ch = llGetSubString(inbuf,0,0);
    if (llStringLength(inbuf) > 1)
        inbuf = llGetSubString(inbuf,1,-1);
    else {
        inbuf = "";
        debug("Last symbol pumped in");
    }
    if (ch == "\n") return 10; //FIXME
    integer x = llSubStringIndex(printable,ch);
    if (x < 0) {
        error("Unrecognized symbol: "+ch);
        return 0;
    }
    x += print_offset;
    return x;
}

bf()
{
    string vs;
    busy = 1;
    while ((IP >= 0) && (IP < proglen)) {
        zVal = readmap(IP);
        vs = "IP: "+(string)IP+" Op: "+(string)currop;
        if (currop == 0) {
            ptr += zVal;
            ++IP;
        } else if (currop == 1) {
            ptr -= zVal;
            ++IP;
        } else if (currop == 2) {
            ++IP;
            zVal = load(ptr) + zVal;
            store(zVal,ptr);
        } else if (currop == 3) {
            ++IP;
            zVal = load(ptr) - zVal;
            store(zVal,ptr);
        } else if (currop == 4) {
            outp(load(ptr));
            ++IP;
        } else if (currop == 5) {
            if (inbuf == "") {
                say("Request for input");
                inputwait = 1;
                return;
            }
            zVal = code_input();
            debug("symbol translated to zVal="+(string)zVal);
            store(zVal,ptr);
            ++IP;
        } else if (currop == 6) {
            if (load(ptr)) ++IP;
            else IP = zVal;
        } else if (currop == 7) {
            if (load(ptr)) IP = zVal;
            else ++IP;
        }
        vs += "\nDP: "+(string)ptr;
        stream(vs);
    }
    if (outbuf != "") say(outbuf);
    outbuf = "";
    inbuf = "";
    stream("");
    debug("out of code\nIP = "+(string)IP+"\nproglen = "+(string)proglen);
    busy = 0;
    float time = llGetAndResetTime();
    say("Done!");
    say("Computation time: "+(string)time+" sec.");
}

init()
{
    busy = 0;
    tape = [];
    MP_Memtop = 0;
    MP_LastAddr = -1;
    ptr = 0;
    IP = 0;
    currop = -1;
    outbuf = "";
    inbuf = "";
    inputwait = 0;
    proglen = llGetListLength(map);
    zVal = 0;
}

run()
{
    init();
    say("Running...");
    llResetTime();
    bf();
}

mapper()
{
    integer x;
    while (++IP < proglen) {
        readmap(IP);
        x = -1;
        if (currop == 6) // [
            x = prog_nextclose();
        else if (currop == 7) // ]
            x = prog_nextopen();
        if (x >= 0) {
            stream("map "+(string)IP+" -> "+(string)x);
            map = llListReplaceList(map,[mappacki(currop,x)],IP,IP);
        }
    }
    stream("");
    say("Mapper finished!");
    //debug(llDumpList2String(map,","));
    run();
}

map_start()
{
    say("Mapping started...");
    debug((string)llGetFreeMemory()+" bytes free");
    init();
    IP = -1;
    mapper();
}

note_rq()
{
    note_query = llGetNotecardLine(note_name,note_line++);
}

process_line()
{
    integer n = llStringLength(inbuf);
    string ch;
    integer f;
    for (; PLi<n; PLi++) {
        ch = llGetSubString(inbuf,PLi,PLi);
        if (llSubStringIndex(validchars,ch) >= 0) {
            f = 0;
            if (ch == curropch) ptr++;
            else {
                if ((curropch != "$") && (ptr)) {
                    map += [mappack(curropch,ptr)];
                    curropch = "^";
                    ptr = 0;
                }
                if (llSubStringIndex("<>+-",ch) >= 0) {
                    curropch = ch;
                    ptr = 1;
                } else
                    map += [mappack(ch,0)];
            }
        }
    }
    note_rq();
}

default
{
    state_entry()
    {
        llListen(0,"",llGetOwner(),"");
        say("BF interpreter is ready");
        say(s_rev);
        stream("");
    }

    listen(integer ch, string name, key id, string msg)
    {
        if (inputwait) {
            inputwait = 0;
            inbuf = msg + "\n";
            say("%"+msg);
            bf();
            return;
        }
        if (busy) return;
        if (llGetSubString(msg,0,4) == "FLOAD") {
            note_name = llGetSubString(msg,5,-1);
            note_line = 0;
            say("Loading "+note_name+"...");
            init();
            map = [];
            curropch = "$";
            note_rq();
        }
    }

    dataserver(key qid, string data)
    {
        if (qid != note_query) return;
        note_query = NULL_KEY;
        if (data == EOF) {
            stream("");
            debug("Stream-collapse program result");
            debug("Length = "+(string)llGetListLength(map));
            say("Loaded.");
            map_start();
            return;
        }
        inbuf = data;
        PLi = 0;
        stream("Loading line "+(string)note_line+"\n"+(string)llGetFreeMemory()+" bytes free so far");
        process_line();
    }
}
