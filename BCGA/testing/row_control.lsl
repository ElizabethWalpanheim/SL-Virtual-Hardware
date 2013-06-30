// (C) Elizabeth Walpanheim, 2012-2013
// License GPL
// rev 20130630-01

integer NumCols = 5;
integer NumSides = 8;
integer access_pin = 68101201;
key Key_Row_Control = "01010101-0000-0000-0000-123456780aa1";
key Key_Cell_Control = "01010101-0000-0000-0000-123456780bb2";
string CellPrefix = "gnd";
integer CtlPrefixLen = 3;
float tTau = 0.6;

integer num;
integer addr_low;
integer addr_hi;
integer cglw;
list targs;
key self;

glow(float f)
{
    llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_GLOW,ALL_SIDES,f]);
}

out(string str)
{
    llOwnerSay("ROWcontroller #"+(string)num+": "+str);
}

integer ispresent(string nm)
{
    if (llGetInventoryType(nm) == INVENTORY_NONE) return 0;
    else return 1;
}

deploy(string name)
{
    integer i;
    glow(1);
    for (i=0; i<NumCols; i++)
        llRemoteLoadScriptPin(llGetLinkKey(llList2Integer(targs,i)),name,access_pin,1,0);
    glow(0);
    out("deploy done!");
    llRemoveInventory(name);
}

dirout(string str)
{
    list vals = llParseString2List(str,["|"],[]);
    integer m = llGetListLength(vals);
    integer i;
    integer j;
    string vs;
    integer n = 0;
    cglw = 1;
    glow(1);
    for (i=0; i<NumCols; i++) {
        vs = "";
        for (j=0; j<NumSides; j++) {
            if (n < m) vs += llList2String(vals,n) + "|";
            n++;
        }
        llMessageLinked(llList2Integer(targs,i),0,vs,Key_Cell_Control);
    }
}

direct(integer col, string str)
{
    if ((col < 0) || (col >= NumCols)) return;
    llMessageLinked(llList2Integer(targs,col),0,str,Key_Cell_Control);
}


default
{
    state_entry()
    {
        self = llGetKey();
        num = (integer)llGetSubString(llGetObjectName(),CtlPrefixLen,-1);
        integer i = llGetNumberOfPrims() + 1;
        if (i == 2) {
            llSay(0,"Dummy mode");
            return;
        }
        integer j = NumCols;
        targs = [];
        glow(0);
        addr_low = num * NumCols;
        addr_hi = addr_low + NumCols;
        while (--j >= 0) targs += [LINK_ALL_OTHERS];
        string vs;
        integer cpxn = llStringLength(CellPrefix) - 1;
        integer k = 0;
        while (i) {
            vs = llGetLinkName(--i);
            if (llGetSubString(vs,0,cpxn) == CellPrefix) {
                j = (integer)(llGetSubString(vs,cpxn+1,-1));
                if ((j >= addr_low) && (j < addr_hi)) {
                    j -= addr_low;
                    targs = llListReplaceList(targs,[i],j,j);
                    k++;
                }
            }
        }
        llSetRemoteScriptAccessPin(access_pin);
        if (k == NumCols) vs = "OK";
        else vs = "FAIL";
        out(" ready ["+vs+"]\n"+(string)llGetFreeMemory()+" bytes free.");
        llSetTimerEvent(tTau);
    }

    link_message(integer sender, integer lnum, string lstr, key lid)
    {
        if (lid != Key_Row_Control) return;
        if (lstr == "RESET") llResetScript();
        else if (lnum == num) {
            list l;
            string c = llGetSubString(lstr,0,0);
            string a = llGetSubString(lstr,1,-1);
            if (c == "!") dirout(a);
            else if (c == "$") {
                l = llParseString2List(a,["%"],[]);
                if (llGetListLength(l) < 2) return;
                a = llList2String(l,1);
                direct((integer)(llList2String(l,0)),a);
            } else {
                l = llParseString2List(lstr,["|"],[]);
                c = llList2String(l,0);
                if (llGetListLength(l) > 1) a = llList2String(l,1);
                else a = "";
                if ((c == "DEPLOY") && (ispresent(a))) deploy(a);
                else if ((c == "REMSCR") && (ispresent(a))) llRemoveInventory(a);
            }
        }
    }

    timer()
    {
        if (cglw) {
            cglw = 0;
            glow(0);
        }
    }

    changed(integer a)
    {
        if (a & CHANGED_INVENTORY) {
            cglw = 1;
            glow(1);
        } else if (a & CHANGED_LINK)
            llResetScript();
    }
}

