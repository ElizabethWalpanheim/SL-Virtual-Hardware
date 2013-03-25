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
integer memtop = 1600; //guaranteed memory
integer monitorChan = -101006;

string printable = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
integer print_offset = 32;

string validchars = "<>+-,.[]*";

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
list map;

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
    //llSay(monitorChan,str);
    llSay(0,str);
}

stream(string str)
{
    llSetText(str,<0,1,0>,1);
}

integer brk_getclose(string in, integer pos)
{
    integer i = pos;
    string ss;
    integer sub = 0;
    while (++i < llStringLength(in)) {
        ss = llGetSubString(in,i,i);
        if (ss == "[") sub++;
        else if (ss == "]") sub--;
        if (sub < 0) return i;
    }
    return -1;
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

integer brk_getopen(string in, integer pos)
{
    integer i = pos;
    string ss;
    integer sub = 0;
    while (--i >= 0) {
        ss = llGetSubString(in,i,i);
        if (ss == "]") sub++;
        else if (ss == "[") sub--;
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

integer chunk_detect()
{
    integer i = IP;
    integer c = 1;
    while (++i < proglen) {
        if (llGetSubString(program,i,i) == currop) c++;
        else i = proglen;
    }
    //if (c>1) debug("Chunk of "+currop+" -> "+(string)c+" times.");
    return c;
}

init()
{
    busy = 0;
    tape = [];
    ptr = 0;
    IP = 0;
    outbuf = "";
    inbuf = "";
    inputwait = 0;
}

bf()
{
    integer z;
    string vs;
    busy = 1;
    proglen = llStringLength(program);
    while ((IP >= 0) && (IP < proglen)) {
        currop = llGetSubString(program,IP,IP);
        vs = "IP "+(string)IP+" Op: "+currop;
        if (currop == ">") {
            z = chunk_detect();
            ptr += z;
            IP += z;
        } else if (currop == "<") {
            z = chunk_detect();
            ptr -= z;
            IP += z;
        } else if (currop == "+") {
            z = chunk_detect();
            IP += z;
            z = load(ptr) + z;
            store(z,ptr);
            //vs += "\n"+(string)z+"\n";
        } else if (currop == "-") {
            z = chunk_detect();
            IP += z;
            z = load(ptr) - z;
            store(z,ptr);
            //vs += "\n"+(string)z+"\n";
        } else if (currop == ".") {
            outp(load(ptr));
            ++IP;
        } else if (currop == ",") {
            if (inbuf == "") {
                say("Request for input");
                inputwait = 1;
                return;
            }
            z = code_input();
            debug("symbol translated to z="+(string)z);
            store(z,ptr);
            ++IP;
        } else if (currop == "[") {
            if (load(ptr)) ++IP;
            else IP = llList2Integer(map,IP);
        } else if (currop == "]") {
            if (load(ptr)) IP = llList2Integer(map,IP);
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
}

/*
cycles_outline_print()
{
    integer i = -1;
    proglen = llStringLength(program);
    integer y;
    say("Calculating outline...");
    while (++i < proglen) {
        if (llGetSubString(program,i,i) == "[") {
            y = brk_getclose(program,i);
            say(llGetSubString(program,i,y));
            i = y;
        }
    }
    say("Outline finished");
}
*/

mapper()
{
    //very dumb algorithm just for testing
    debug("mapper() started");
    IP = -1;
    proglen = llStringLength(program);
    map = [];
    string ch;
    integer x;
    while (++IP < proglen) {
        ch = llGetSubString(program,IP,IP);
        x = -1;
        if (ch == "[")
            x = prog_nextclose();
        else if (ch == "]")
            x = prog_nextopen();
        map += [x];
    }
    debug((string)llGetFreeMemory()+" bytes free");
}

note_rq()
{
    note_query = llGetNotecardLine(note_name,note_line++);
}

run()
{
    debug((string)llGetFreeMemory()+" bytes free");
    mapper();
    init();
    say("Running...");
    llResetTime();
    bf();
    float time = llGetAndResetTime();
    say("Done!");
    say("Computation time: "+(string)time+" sec.");
}

default
{
    state_entry()
    {
        llListen(0,"",llGetOwner(),"");
        say("BF interpreter is ready");
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
        if (llGetSubString(msg,0,1) == "BF") {
            program = llGetSubString(msg,2,-1);
            run();
            debug((string)llGetFreeMemory()+" bytes free");
        } else if (llGetSubString(msg,0,4) == "FLOAD") {
            note_name = llGetSubString(msg,5,-1);
            note_line = 0;
            program = "";
            say("Loading "+(string)llGetSubString(msg,5,-1)+"...");
            note_rq();
        }
    }

    dataserver(key qid, string data)
    {
        if (qid != note_query) return;
        if (data == EOF) {
            say("Loaded.");
            run();
            return;
        }
        integer i;
        integer n = llStringLength(data);
        string ch;
        for (i=0; i<n; i++) {
            ch = llGetSubString(data,i,i);
            if (llSubStringIndex(validchars,ch) >= 0)
                program += ch;
        }
        note_rq();
    }
}
