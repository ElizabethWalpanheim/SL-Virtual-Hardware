//    Brainfuck language interpreter for LSL
//    Copyright (C) 2013  Elizabeth Walpanheim
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
string s_rev = "build 83";
integer memtop = 1600; //guaranteed memory
integer monitorChan = -101006;

string printable = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
integer print_offset = 32;
string validchars = "<>+-,.[]*";
key DRAM_ControlUUID = "10101010-0000-0000-0000-eeeeeeee5555";

string program;
list tape;
integer ptr;
integer IP;
string outbuf;
string inbuf;
integer inputwait;
string currop;
integer proglen;
integer busy;
integer PLi;
integer dram_smp; // DRAM I/O semaphore
integer zVal;

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

dram_write(integer addr, integer val)
{
    llMessageLinked(LINK_THIS,addr,"W"+(string)val,DRAM_ControlUUID);
}

dram_read(integer addr)
{
    llMessageLinked(LINK_THIS,addr,"R",DRAM_ControlUUID);
}

integer prog_nextclose()
{
    //Speedy and less memory hungry due to lack of passing arguments
    integer i = IP;
    string ss;
    integer sub = 0;
    while (++i < proglen) {
        ss = llGetSubString(program,i,i);
        if (ss == "[") sub++;
        else if (ss == "]") sub--;
        if (sub < 0) return i;
    }
    return -1;
}

integer prog_nextopen()
{
    //Speedy and less memory hungry due to lack of passing arguments
    integer i = IP;
    string ss;
    integer sub = 0;
    while (--i >= 0) {
        ss = llGetSubString(program,i,i);
        if (ss == "]") sub++;
        else if (ss == "[") sub--;
        if (sub < 0) return i;
    }
    return -1;
}

integer expand(integer newtop)
{
    debug("expand() called with arg="+(string)newtop);
    if (newtop > memtop) {
        error("Can't expand beyound memory limit!");
        return 0;
    }
    integer i = llGetListLength(tape);
    if (newtop < i) return 1;
    i = newtop - i + 1;
    while (i--) tape += [0];
    debug("new tape length="+(string)llGetListLength(tape));
    return 1;
}

integer load(integer x)
{
    if (x < 0) {
        error("Accessing (READ) a cell with address number below zero!");
        return 0;
    }
    if (x >= llGetListLength(tape)) {
        //debug("Accessing (READ) a cell beyound current limit, returning zero");
        return 0;
    }
    return (llList2Integer(tape,x));
}

integer store(integer val, integer addr)
{
    if (addr < 0) {
        error("Accessing (WRITE) a cell with address number below zero!");
        return 0;
    }
    if (addr >= llGetListLength(tape)) {
        //debug("Accessing (WRITE) a cell beyound current limit, expanding...");
        if (expand(addr))
            return(store(val,addr));
        else {
            error("Can't expand the tape!");
            return 0;
        }
    }
    tape = llListReplaceList(tape,[val],addr,addr);
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
        currop = llGetSubString(program,IP,IP);
        if ((dram_smp == 20) && (llSubStringIndex(".,*",currop)) < 0) {
            dram_read(IP);
            return;
        }
        vs = "IP "+(string)IP+" Op: "+currop;
        dram_smp = 20;
        if (currop == ">") {
            ptr += zVal;
            ++IP;
        } else if (currop == "<") {
            ptr -= zVal;
            ++IP;
        } else if (currop == "+") {
            ++IP;
            zVal = load(ptr) + zVal;
            store(zVal,ptr);
        } else if (currop == "-") {
            ++IP;
            zVal = load(ptr) - zVal;
            store(zVal,ptr);
        } else if (currop == ".") {
            outp(load(ptr));
            ++IP;
        } else if (currop == ",") {
            if (inbuf == "") {
                say("Request for input");
                inputwait = 1;
                return;
            }
            zVal = code_input();
            debug("symbol translated to zVal="+(string)zVal);
            store(zVal,ptr);
            ++IP;
        } else if (currop == "[") {
            if (load(ptr)) ++IP;
            else IP = zVal;
        } else if (currop == "]") {
            if (load(ptr)) IP = zVal;
            else ++IP;
        } else if (currop == "*") {
            IP = -1;
            debug("HALT");
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

mapper()
{
    integer x;
    dram_smp = 2;
    while (++IP < proglen) {
        currop = llGetSubString(program,IP,IP);
        x = -1;
        if (currop == "[")
            x = prog_nextclose();
        else if (currop == "]")
            x = prog_nextopen();
        if (x >= 0) {
            stream("map "+(string)IP+" -> "+(string)x);
            dram_write(IP,x);
            return;
        }
    }
    stream("");
    say("Mapper finished!");
    run();
}

init()
{
    busy = 0;
    tape = [];
    ptr = 0;
    IP = 0;
    currop = "";
    outbuf = "";
    inbuf = "";
    inputwait = 0;
    proglen = llStringLength(program);
    dram_smp = 20;
    zVal = 0;
}

run()
{
    init();
    say("Running...");
    llResetTime();
    bf();
}

map_start()
{
    say("Mapping started...");
    proglen = llStringLength(program);
    debug((string)llGetFreeMemory()+" bytes free");
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
    dram_smp = 1;
    for (; PLi<n; PLi++) {
        ch = llGetSubString(inbuf,PLi,PLi);
        if (llSubStringIndex(validchars,ch) >= 0) {
            f = 0;
            if (ch == currop) ptr++;
            else {
                if ((currop != "$") && (ptr)) {
                    program += currop;
                    currop = "^";
                    f = ptr;
                    ptr = 0;
                }
                if (f) {
                    //debug("Ext.Write $"+(string)IP+" = "+(string)f);
                    dram_write(IP++,f);
                    return;
                }
                if (llSubStringIndex("<>+-",ch) >= 0) {
                    currop = ch;
                    ptr = 1;
                } else {
                    program += ch;
                    f = -1;
                }
                if (f) {
                    //debug("Ext.Write $"+(string)IP+" = "+(string)f);
                    dram_write(IP++,f);
                    ++PLi;
                    return;
                }
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
            program = "";
            currop = "$";
            note_rq();
        }
    }

    dataserver(key qid, string data)
    {
        if (qid != note_query) return;
        if (data == EOF) {
            stream("");
            debug("Stream-collapse program result");
            //debug(program);
            debug("Length = "+(string)llStringLength(program));
            say("Loaded.");
            map_start();
            return;
        }
        note_query = NULL_KEY;
        inbuf = data;
        PLi = 0;
        stream("Loading line "+(string)note_line+"\n"+(string)llGetFreeMemory()+" bytes free so far");
        process_line();
    }
    
    link_message(integer sdr, integer num, string str, key id)
    {
        if (id != DRAM_ControlUUID) return;
        if (str == "K") {
            if (dram_smp == 1) process_line();
            else if (dram_smp == 2) mapper();
        } else if (str == "V") {
            if (dram_smp == 20) {
                dram_smp = 21;
                zVal = num;
                //debug("zVal received "+(string)num+" for IP="+(string)IP);
                bf();
            }
        }
    }
}
