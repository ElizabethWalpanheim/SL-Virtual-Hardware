integer tranChan = -97888;
integer test_block = 500;
list test;
integer crc;
integer fsm;
integer cadr;
integer ncrc;

say(string vs)
{
    llSay(0,vs);
}

read()
{
    fsm = 20;
    if (++cadr >= test_block) {
        say("Reading is done!");
        say("Result CRC32: "+(string)ncrc);
        if (ncrc == crc) say("CRC32 is equal!");
        else say("Control summ is NOT equal!!!");
        return;
    }
    llSay(tranChan,"G@"+(string)cadr);
    fsm = 21;
}

write()
{
    fsm = 10;
    if (--cadr < 0) {
        say("Writing is done!");
        say("Reading...");
        ncrc = 0;
        cadr = -1;
        read();
        return;
    }
    llSay(tranChan,"P@"+(string)cadr+"@"+(string)llList2Integer(test,cadr));
    fsm = 11;
}

default
{
    state_entry()
    {
        llSetText("",ZERO_VECTOR,0);
        llSay(0, "Hello, Avatar!");
        llListen(tranChan,"","","");
    }

    touch_start(integer total_number)
    {
        integer i = test_block;
        integer x;
        test = [];
        crc = 0;
        say("Prepare test block...");
        while (i--) {
            x = llFloor(llFrand(256));
            test += [x];
            crc += x;
        }
        say("Block size = "+(string)llGetListLength(test));
        say("Free memory: "+(string)llGetFreeMemory()+" bytes.");
        say("CRC32: "+(string)crc);
        say("Writing...");
        cadr = test_block;
        fsm = 0;
        //write();
        cadr = -1;
        read();
    }
    
    listen(integer chan, string name, key id, string msg)
    {
        list l = llParseString2List(msg,["@"],[]);
        string answ = llList2String(l,0);
        if ((fsm == 11) && (answ == "K")) {
            if ((integer)llList2String(l,1) != cadr)
                say("Transmit error: $"+(string)cadr+" transmitted, received answer for $"+llList2String(l,1));
            else {
                fsm = 12;
                llSetText("->"+llList2String(l,1),<1,1,1>,1);
                write();
            }
        } else if ((fsm == 21) && (answ == "A")) {
            if ((integer)llList2String(l,1) != cadr)
                say("Receive error: $"+(string)cadr+" requested, received data for $"+llList2String(l,1));
            else {
                fsm = 22;
                ncrc += (integer)llList2String(l,2);
                llSetText("<-"+llList2String(l,1),<1,1,1>,1);
                read();
            }
        }
    }
}
