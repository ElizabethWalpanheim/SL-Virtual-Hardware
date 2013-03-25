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
integer memtop = 2600;

list printable = [" ","!","\"","#","$","%","&","'","(",")","*","+",",","-",".","/","0","1","2","3","4","5","6","7","8","9",":",";","<","=",">","?","@","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","[","\\","]","^","_","`","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","{","|","}","~"];
integer print_offset = 32;

list tape;
integer ptr;
integer IP;

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
    llSay(0,str);
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
    x -= print_offset;
    if ((x < 0) || (x >= llGetListLength(printable))) {
        error("Unprintable code pumped to output: "+(string)(x+print_offset));
        return;
    }
    say(llList2String(printable,x));
}

init()
{
    tape = [];
    ptr = 0;
    IP = 0;
}

bf(string program)
{
    string cmd;
    integer z;
    integer proglen = llStringLength(program);
    while ((IP >= 0) && (IP < proglen)) {
        cmd = llGetSubString(program,IP,IP);
        //debug("IP "+(string)IP+" cmd: "+cmd);
        if (cmd == ">") {
            ++ptr;
            ++IP;
        } else if (cmd == "<") {
            --ptr;
            ++IP;
        } else if (cmd == "+") {
            z = load(ptr) + 1;
            store(z,ptr);
            ++IP;
        } else if (cmd == "-") {
            z = load(ptr) - 1;
            store(z,ptr);
            ++IP;
        } else if (cmd == ".") {
            outp(load(ptr));
            ++IP;
        } else if (cmd == ",") {
            error("Not yet implemented!");
            ++IP;
        } else if (cmd == "[") {
            if (load(ptr)) ++IP;
            else IP = brk_getclose(program,IP);
        } else if (cmd == "]") {
            if (load(ptr)) IP = brk_getopen(program,IP);
            else ++IP;
        }
    }
    debug("out of code\nIP = "+(string)IP+"\nproglen = "+(string)proglen);
}
        
default
{
    state_entry()
    {
        llListen(0,"","","");
        say("BF interpreter is ready");
    }

    listen(integer ch, string name, key id, string msg)
    {
        if (llGetSubString(msg,0,1) != "BF") return;
        init();
        say("Running...");
        bf(llGetSubString(msg,2,-1));
        say("Done!");
        debug((string)llGetFreeMemory()+" bytes free");
    }
}
