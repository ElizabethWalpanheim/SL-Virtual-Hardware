string encode = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzªºÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏŐőŒœŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžſƀƁƂƃƄƅƆƇƈƉƊƋ";

string mem;
integer block_size = 256;
integer blocks = 44;
string buf;
integer memlimit = 3072;
integer mem_top;
integer tranChan = -97888;

out(string in)
{
    //llWhisper(0,in);
    llOwnerSay(in);
}

memdbg()
{
    integer mfr = llGetFreeMemory();
    if (mfr < memlimit)
        llSay(0,"Warning! Memlimit exceeded!!!");
    /*else
        out("mem_free="+(string)mfr);*/
}

integer ch_bt(string ch)
{
    return (llSubStringIndex(encode,ch));
}

string bt_ch(integer bt)
{
    return (llGetSubString(encode,bt,bt));
}

string getchar(integer pos)
{
    return (llGetSubString(mem,pos,pos));
}

replace(integer pos, string nw)
{
    integer i;
    integer c;
    integer m;
    integer f = 1;
    string aux;
    for (i=0; i<blocks; i++) {
        //memdbg();
        buf = ""; //release buffer
        //memdbg();
        buf = llGetSubString(mem,0,block_size-1);
        //memdbg();
        mem = llGetSubString(mem,block_size,-1);
        /*m = llStringLength(mem);
        if (m < block_size) {
            out("mem_tail_cut="+(string)m);
            mem = "";
        }*/
        //memdbg();
        c += block_size;
        if ((f) && (c > pos)) {
            //we're inside the block needed
            f = 0;
            m = pos % block_size;
            //out("block "+(string)i+" m="+(string)m);
            if (m == (block_size-1))
                buf = llGetSubString(buf,0,-2) + nw;
            else if (m == 0)
                buf = nw + llGetSubString(buf,1,-1);
            else {
                //out("worstcase");
                aux = llGetSubString(buf,0,m-1);
                buf = llGetSubString(buf,m+1,-1);
                //memdbg();
                buf = aux + nw + buf;
                aux = "";
                //memdbg();
            }
            memdbg();
        }
        mem += buf;
        memdbg();
        //out("cycle-end");
    }
    buf = encode;
    memdbg();
}

checkaddr(integer a)
{
    if ((a < 0) || (a >= mem_top)) state err;
}

checkbyte(integer b)
{
    if ((b < 0) || (b > 255)) state err;
}

WR(integer addr, integer bt)
{
    //out("b_in(): byte "+(string)bt);
    checkaddr(addr);
    checkbyte(bt);
    replace(addr,bt_ch(bt));
    llSetText((string)addr+" <-- "+(string)bt,<1,1,1>,1);
    llSay(tranChan,"K@"+(string)addr);
}

integer RD(integer addr)
{
    checkaddr(addr);
    return (ch_bt(getchar(addr)));
}

erase()
{
    mem = "";
    buf = "";
    integer i = block_size;
    while (i--) buf += "A";
    i = blocks;
    while (i--) mem += buf;
}

xout(integer addr)
{
    integer x = RD(addr);
    llSetText((string)addr+" --> "+(string)x,<1,1,1>,1);
    llSay(tranChan,"A@"+(string)addr+"@"+(string)x);
}

default
{
    state_entry()
    {
        llSetText("",ZERO_VECTOR,0);
        out("-----------------------------------------------------");
        out("encoder_length="+(string)llStringLength(encode));
        buf = encode; //allocate resident buffer by 256 bytes
        out("resizing...");
        mem_top = block_size * blocks;
        erase();
        out("mem_s="+(string)llStringLength(mem));
        memdbg();
        out("set_time="+(string)llGetTime());
        llListen(tranChan,"","","");
        out("ch2bt: "+(string)ch_bt("q"));
        out("bt2ch: "+bt_ch(42));
    }
    listen(integer chan, string name, key id, string msg)
    {
        list l = llParseString2List(msg,["@"],[]);
        string cmd = llList2String(l,0);
        if (cmd == "P") {
            //put
            if (llGetListLength(l) == 3)
                WR((integer)llList2String(l,1),(integer)llList2String(l,2));
        } else if (cmd == "G") {
            //get
            if (llGetListLength(l) == 2)
                xout((integer)llList2String(l,1));
        } else if (cmd == "FLASH!") {
            //flash erase
            erase();
        }
    }
    touch_start(integer p)
    {
        if (llDetectedKey(0) != llGetOwner()) return;
        llSetTimerEvent(1.0);
        llResetTime();
    }
    timer()
    {
        integer k = llFloor(llFrand(256));
        integer a = llFloor(llFrand(mem_top));
        //llSetText("val "+(string)k+" -> $"+(string)a,<1,1,1>,1);
        WR(a,k);
        if (k != RD(a)) {
            out("ERROR!! addr = $"+(string)a);
            state err;
        }
        llResetTime();
    }
}

state err
{
    state_entry()
    {
        out("ERR");
    }
}
