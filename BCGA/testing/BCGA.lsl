// (C) Elizabeth Walpanheim, 2012-2013
// License GPL

string version = "0.1 bld 012";
integer access_pin = 68101201;
string display_script = "Graph";
string rwctl_script = "bcga row controller";
integer SizeW = 160;
integer SizeH = 120;
integer PixelQdr = 4;
integer NumSides = 8;
integer NumRowPrims = 5;
string RowCtlPrefix = "ctl";
key Key_Row_Control = "01010101-0000-0000-0000-123456780aa1";
key Key_Cell_Control = "01010101-0000-0000-0000-123456780bb2";

integer cols;
integer rows;
list controller;
integer on;
list framebuf;
integer peak;


dbg(string s)
{
    llOwnerSay("DEBUG: "+s);
}

say(string s)
{
    llSay(0,s);
}

init_rowcontrol()
{
    integer i = llGetNumberOfPrims() + 1;
    integer j = rows;
    integer k = llStringLength(RowCtlPrefix) - 1;
    string vs;
    controller = [];
    while (--j >= 0) controller += [LINK_ALL_OTHERS];
    while (i) {
        vs = llGetLinkName(--i);
        if (llGetSubString(vs,0,k) == RowCtlPrefix) {
            j = (integer)(llGetSubString(vs,k+1,-1));
            if ((j >= 0) && (j < rows))
                controller = llListReplaceList(controller,[i],j,j);
        }
    }
    dbg("Controllers: "+llDumpList2String(controller,", "));
    llMessageLinked(LINK_ALL_OTHERS,0,"RESET",Key_Row_Control);
}

cmd_rows(string cmd)
{
    integer i = rows;
    integer j;
    while (i) {
        j = llList2Integer(controller,--i);
        llMessageLinked(j,i,cmd,Key_Row_Control);
    }
}

place_scripts()
{
    integer i = rows;
    key tk;
    while (i) {
        tk = llGetLinkKey(llList2Integer(controller,--i));
        llRemoteLoadScriptPin(tk,display_script,access_pin,0,0);
        dbg("# "+(string)i+" ["+(string)tk+"] placed");
    }
}

initmem()
{
    integer i = rows * cols;
    framebuf = [];
    while (i--) framebuf += [0];
    dbg("Free memory: "+(string)llGetFreeMemory()+" bytes.");
}

retrace()
{
    integer r;
    integer c;
    string s;
    for (r=0; r<rows; r++) {
        s = "!";
        for (c=0; c<cols; c++)
            s += (string)(llList2Integer(framebuf,(r*cols+c))) + "|";
        llMessageLinked(llList2Integer(controller,r),r,s,Key_Row_Control);
    }
}

updateblock(integer col, integer row)
{
    if ((col<0) || (col>=cols) || (row<0) || (row>=rows)) return;
    integer c = col / NumSides;
    string s = "$" + (string)c + "%";
    integer i;
    c *= NumSides;
    for (i=0; i<NumSides; i++)
        s += (string)llList2Integer(framebuf,row*cols+c+i)+"|";
    dbg(s);
    llMessageLinked(llList2Integer(controller,row),row,s,Key_Row_Control);
}

setblock(integer col, integer row, integer val)
{
    if ((col<0) || (col>=cols) || (row<0) || (row>=rows)) return;
    integer adr = row * cols + col;
    framebuf = llListReplaceList(framebuf,[val],adr,adr);
    updateblock(col,row);
}

integer getblock(integer col, integer row)
{
    if ((col<0) || (col>=cols) || (row<0) || (row>=rows)) return 0;
    return llList2Integer(framebuf,row*cols+col);
}

integer genpixmask(integer x, integer y)
{
//    dbg("gpx\t"+(string)x+"\t"+(string)y);
    x = x % PixelQdr;
    y = (y % PixelQdr) * PixelQdr + x;
//    dbg("gpx shift\t"+(string)y);
    x = 1 << y;
//    dbg("out\t"+(string)x);
    return x;
}

setpixel(integer x, integer y, integer v)
{
    if ((x<0) || (x>=SizeW) || (y<0) || (y>=SizeH)) return;
    integer c = x / PixelQdr;
    integer r = y / PixelQdr;
    integer m = genpixmask(x,y);
    integer o = getblock(c,r) & (m ^ peak);
//    dbg("filtered\t"+(string)o+" with "+(string)(m ^ peak));
    if (v) o = o | m;
//    dbg("res\t"+(string)o);
    setblock(c,r,o);
}

integer getpixel(integer x, integer y)
{
    if ((x<0) || (x>=SizeW) || (y<0) || (y>=SizeH)) return 0;
    integer c = x / PixelQdr;
    integer r = y / PixelQdr;
    integer v = getblock(c,r) & genpixmask(x,y);
    if (v) return 1;
    else return 0;
}

init_sequence(integer full)
{
    init_rowcontrol();
    llSleep(1);
    if (full) {
        place_scripts();
        llSleep(1);
        cmd_rows("DEPLOY|"+display_script);
    } else llMessageLinked(LINK_ALL_OTHERS,0,"RESET",Key_Cell_Control);
    llSleep(1);
    initmem();
    retrace();
    llListen(0,"",llGetOwner(),"");
}


default
{
    state_entry()
    {
        say(version);
        rows = SizeH / PixelQdr;
        cols = SizeW / PixelQdr;
        peak = (integer)llPow(2,PixelQdr*PixelQdr) - 1;
        say("Size "+(string)SizeW+"x"+(string)SizeH+"\ncols:rows\t"+(string)cols+"\t"+(string)rows);
        init_sequence(0);
        say("Init done. Ready.");
    }

    touch_start(integer total_number)
    {
    }

    listen(integer ch, string nm, key id, string msg)
    {
        if (msg == "ret") retrace();
        else {
            list l = llParseString2List(msg,[" "],[]);
            setpixel(llList2Integer(l,0),llList2Integer(l,1),1);
            llSay(0,(string)getpixel(llList2Integer(l,0),llList2Integer(l,1)));
        }
    }

    on_rez(integer p)
    {
        llResetScript();
    }
}

