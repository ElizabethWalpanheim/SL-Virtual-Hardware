/*
    Real 80x25 display
    row controller script
    
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

// rev 20121125-01

integer base = 10000;
integer access_pin = 103600;
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

dirout(string str)
{
    integer i;
    integer k = llCeil((float)llStringLength(str) / 10.00);
    list vl;
    while (i<k) vl += [llGetSubString(str,i*10,(++i)*10-1)];
    k = 0;
    for (i=0; i<8; i++)
        llMessageLinked(llList2Integer(targs,i),(base+i+addr_low),llList2String(vl,k++),NULL_KEY);
}

deploy(string name)
{
    integer i;
    glow(1);
    for (i=0; i<8; i++)
        llRemoteLoadScriptPin(llGetLinkKey(llList2Integer(targs,i)),name,access_pin,1,0);
    glow(0);
    //out("deploy done!");
    llRemoveInventory(name);
}

command(string str)
{
    list vl = llParseString2List(str,["|"],[]);
    string ac = llList2String(vl,0);
    string aa = llList2String(vl,1);
    //out("command received: "+str);
    if ((ac == "deploy") && (ispresent(aa))) deploy(aa);
    else if ((ac == "remove") && (ispresent(aa))) llRemoveInventory(aa);
}

default
{
    state_entry()
    {
        self = llGetKey();
        num = (integer)llGetSubString(llGetObjectName(),3,-1);
        integer i = llGetNumberOfPrims() + 1;
        integer j = 8;
        targs = [];
        glow(0);
        addr_low = num * 8;
        addr_hi = addr_low + 8;
        while (--j >= 0) targs += [LINK_ALL_OTHERS];
        while (i) {
            j = (integer)(llGetLinkName(--i)) - base;
            if ((j >= addr_low) && (j < addr_hi)) {
                j -= addr_low;
                targs = llListReplaceList(targs,[i],j,j);
            }
        }
        llSetRemoteScriptAccessPin(access_pin);
        out(" ready."); //\n"+(string)llGetFreeMemory()+" bytes free.");
        llSetTimerEvent(0.6);
        num += 9000100;
    }

    link_message(integer sender, integer lnum, string lstr, key lid)
    {
        if (lnum == num) {
            if (lid == NULL_KEY) {
                dirout(lstr);
                cglw = 1;
                glow(1);
                llResetTime();
            } else if (lid == self)
                command(lstr);
        } else if ((lnum == -602) && (lstr == "RESET"))
            llResetScript();
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
        }
    }
}

