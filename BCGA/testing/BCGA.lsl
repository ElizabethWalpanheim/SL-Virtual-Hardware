// (C) Elizabeth Walpanheim, 2012-2013
// GPL License

string version = "0.2 bld 027";
integer access_pin = 68101201;
integer debug = 1;

/* *** MAIN SETTINGS *** */
string display_script = "Graph";
string rwctl_script = "bcga row controller";
integer SizeW = 160;
integer SizeH = 120;
integer PixelQdr = 4;
integer NumSides = 8;
integer NumRowPrims = 5;
string RowCtlPrefix = "ctl";
integer reply_setpixel = 0;
integer reply_setpixblock = 1;
integer reply_setblockcol = 1;
/* *********************** */

key Key_Row_Control = "01010101-0000-0000-0000-123456780aa1";
key Key_Cell_Control = "01010101-0000-0000-0000-123456780bb2";

key Key_Op_SetPixel = "01010101-0000-0000-ffff-000000000001";
key Key_Op_GetPixel = "01010101-0000-0000-ffff-000000000002";
key Key_Op_SetPixelBlock = "01010101-0000-0000-ffff-000000000003";
key Key_Op_GetPixelBlock = "01010101-0000-0000-ffff-000000000004";
key Key_Op_SetScanline = "01010101-0000-0000-ffff-000000000005";
key Key_Op_GetScanline = "01010101-0000-0000-ffff-000000000006";
key Key_Op_GetScreenSize = "01010101-0000-0000-ffff-000000000007";
key Key_Op_ClearScreen = "01010101-0000-0000-ffff-000000000008";
key Key_Op_SetBlockColor = "01010101-0000-0000-ffff-000000000009";
key Key_Op_GetBlockColor = "01010101-0000-0000-ffff-00000000000a";
key Key_Op_SetColorMode = "01010101-0000-0000-ffff-00000000000b";
key Key_Op_GetColorMode = "01010101-0000-0000-ffff-00000000000c";
key Key_Op_Retrace = "01010101-0000-0000-ffff-00000000000d";

key Key_Op_Shutdown = "01010101-0000-fffa-ffff-000000000001";
key Key_Op_Bootstrap = "01010101-0000-fffa-ffff-000000000002";
key Key_Op_Poweron = "01010101-0000-fffa-ffff-000000000003";
key Key_Op_FullDelete = "01010101-0000-fffa-ffff-000000000004";

key Key_Answ_Ready = "01010101-1111-0000-ffff-000000000000";


/* *** GLOBAL VARIABLES *** */
integer cols;
integer rows;
list controller;
integer on;
list framebuf;
list colormap;
integer peak;
integer usecolor;
/* ************************ */


dbg(string s)
{
    if (debug)
        llOwnerSay("DEBUG: "+s);
}

say(string s)
{
    llSay(0,s);
}

fmem()
{
    dbg("Free memory: "+(string)llGetFreeMemory()+" bytes.");
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

place_scripts(integer what)
{
    integer i = rows;
    key tk;
    string nm;
    integer ss; //starting state
    if (what == 1) {
        nm = display_script;
        ss = 0;
    } else if (what == 2) {
        nm = rwctl_script;
        ss = 1;
    } else return;
    while (i) {
        tk = llGetLinkKey(llList2Integer(controller,--i));
        llRemoteLoadScriptPin(tk,nm,access_pin,ss,0);
        dbg("# "+(string)i+" ["+(string)tk+"] placed");
    }
}

initmem()
{
    integer i = cols;
    framebuf = [];
    colormap = [];
    list a;
    list b;
    while (i--) {
        a += [0];
        if (usecolor) b += [0];
        else b += [0xFFFFFF];
    }
    i = rows;
    while (i--) {
        framebuf += a;
        colormap += b;
    }
    //doing next to reset colors of the display even if they messed up,
    //but we don't want to use colors anymore
    if (!usecolor) {
        usecolor = 1;
        retrace();
        usecolor = 0;
    }
    a = [];
    b = [];
    fmem();
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
        if (usecolor) {
            s = "@!";
            for (c=0; c<cols; c++)
                s += (string)(llList2Integer(colormap,(r*cols+c))) + "|";
            llMessageLinked(llList2Integer(controller,r),r,s,Key_Row_Control);
        }
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
    if (usecolor) {
        s = "@$" + (string)(col/NumSides) + "%";
        for (i=0; i<NumSides; i++)
            s += (string)llList2Integer(colormap,row*cols+c+i)+"|";
        dbg("COLOR: "+s);
        llMessageLinked(llList2Integer(controller,row),row,s,Key_Row_Control);
    }
}

setblock(integer col, integer row, integer val, integer upd)
{
    if ((col<0) || (col>=cols) || (row<0) || (row>=rows)) return;
    integer adr = row * cols + col;
    framebuf = llListReplaceList(framebuf,[val],adr,adr);
    if (upd) updateblock(col,row);
    //fmem();
}

integer getblock(integer col, integer row)
{
    if ((col<0) || (col>=cols) || (row<0) || (row>=rows)) return 0;
    return llList2Integer(framebuf,row*cols+col);
}

setblockcol(integer col, integer row, integer color)
{
    if ((col<0) || (col>=cols) || (row<0) || (row>=rows)) return;
    integer adr = row * cols + col;
    colormap = llListReplaceList(colormap,[color],adr,adr);
    updateblock(col,row);
}

integer getblockcol(integer col, integer row)
{
    if ((col<0) || (col>=cols) || (row<0) || (row>=rows)) return 0;
    return llList2Integer(colormap,row*cols+col);
}

integer genpixmask(integer x, integer y)
{
    x = x % PixelQdr;
    y = (y % PixelQdr) * PixelQdr + x;
    x = 1 << y;
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
    setblock(c,r,o,1);
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

setscanline(integer row, string data)
{
    integer i;
    integer j;
    integer b;
    integer z;
    integer c = 0;
    integer m = (1 << PixelQdr) - 1;
    integer nm = m ^ peak;
    for (i=0; i<cols; i++) {
        b = getblock(i,row) & nm;
        for (j=0; j<PixelQdr; j++) {
            if (llGetSubString(data,c,c) == "1") z = 1 << j;
            else z = 0;
            b = b | z;
            c++;
        }
        setblock(i,row,b,0);
    }
}

init_sequence(integer full)
{
    init_rowcontrol();
    llSleep(1);
    if (full) { //poweron or bootstrap action
        if (full > 1) { //full bootstrap
            place_scripts(2);
            llSleep(1);
            place_scripts(1);
            llSleep(1);
        }
        cmd_rows("DEPLOY|"+display_script);
    } else llMessageLinked(LINK_ALL_OTHERS,0,"RESET",Key_Cell_Control);
    llSleep(1);
    initmem();
    retrace();
    llMessageLinked(LINK_ALL_OTHERS,0,"",Key_Answ_Ready);
}


default
{
    state_entry()
    {
        fmem();
        say("BCGA "+version+" booting...\n(C) Elizabeth Walpanheim, 2012-2013");
        rows = SizeH / PixelQdr;
        cols = SizeW / PixelQdr;
        peak = (integer)llPow(2,PixelQdr*PixelQdr) - 1;
        usecolor = 1;
        say("Size "+(string)SizeW+"x"+(string)SizeH+"\ncols:rows\t"+(string)cols+"\t"+(string)rows);
        init_sequence(0);
        say("Init done. Ready.");
    }

    link_message(integer sndr, integer num, string str, key id)
    {
        if (sndr == llGetLinkNumber()) return;
        list l;
        //dbg((string)num+": "+str);
        if (llGetSubString(str,0,0) == "#")
            l = llParseString2List(llGetSubString(str,1,-1),["|"],[]);
        integer n = llGetListLength(l);
        if ((id == Key_Op_SetPixel) && (n == 2)) { // X,Y
            setpixel(llList2Integer(l,0),llList2Integer(l,1),num);
            if (reply_setpixel) llMessageLinked(sndr,255,"OK",id);
        } else if ((id == Key_Op_GetPixel) && (n == 2)) // X,Y
            llMessageLinked(sndr,getpixel(llList2Integer(l,0),llList2Integer(l,1)),"OK",id);
        else if ((id == Key_Op_SetPixelBlock) && (n == 2)) { // Col,Row
            setblock(llList2Integer(l,0),llList2Integer(l,1),num,1);
            if (reply_setpixblock) llMessageLinked(sndr,255,"OK",id);
        } else if ((id == Key_Op_GetPixelBlock) && (n == 2)) // Col,Row
            llMessageLinked(sndr,getblock(llList2Integer(l,0),llList2Integer(l,1)),"OK",id);
        else if ((id == Key_Op_GetBlockColor) && (n == 2)) // Col,Row
            llMessageLinked(sndr,255,(string)getblockcol(llList2Integer(l,0),llList2Integer(l,1)),id);
        else if ((id == Key_Op_SetBlockColor) && (n == 3)) { // Col,Row,Color
            setblockcol(llList2Integer(l,0),llList2Integer(l,1),llList2Integer(l,2));
            if (reply_setblockcol) llMessageLinked(sndr,255,"OK",id);
        } else if (id == Key_Op_SetScanline) {
            setscanline(num,str);
            llMessageLinked(sndr,255,"OK",id);
        } else if (id == Key_Op_GetScanline)
            ; //NYI
        else if (id == Key_Op_Retrace)
            retrace();
        else if (id == Key_Op_SetColorMode) {
            if (num) usecolor = 1;
            else usecolor = 0;
        } else if (id == Key_Op_GetColorMode)
            llMessageLinked(sndr,usecolor,"OK",id);
        else if (id == Key_Op_GetScreenSize)
            llMessageLinked(sndr,255,((string)SizeW+"|"+(string)SizeH+"|"+(string)cols+"|"+(string)rows),id);
        else if (id == Key_Op_ClearScreen) {
            initmem();
            if (usecolor) retrace(); //if not, we've already updated cells
        } else if (id == Key_Op_Shutdown) {
            say("Shutted down.");
            framebuf = [];
        } else if (id == Key_Op_Bootstrap) {
            say("Botstrapping...\nThis may take a few minutes. Please wait.");
            init_sequence(2);
            say("Bootstrap done. Ready.");
        } else if (id == Key_Op_Poweron) {
            say("Powering on...\nPlease wait.");
            init_sequence(1);
            say("Ready.");
        } else if (id == Key_Op_FullDelete) {
            say("Cleaning all array scripts");
            cmd_rows("REMSCR|"+display_script);
            cmd_rows("SELFDELETE");
            llMessageLinked(LINK_ALL_OTHERS,0,"",Key_Op_Shutdown);
        }
    }

    on_rez(integer p)
    {
        llResetScript();
    }

    changed(integer w)
    {
        if (w & CHANGED_LINK) llResetScript();
    }
}

