//    DRAM memory element for LSL
//    Copyright (C) 2012-2013  Elizabeth Walpanheim
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
integer icChan = -967116;
integer capacity;
list memory;
integer my_no;
key owner;
integer low;
integer hig;
key trusted;
integer hLst;

out(string s)
{
    llSay(icChan,s);
}

resize(integer sz)
{
    memory = [];
    if (my_no < 0) return;
    capacity = sz;
    low = capacity * my_no;
    hig = low + capacity - 1;
    llOwnerSay("#"+(string)my_no+" Number "+(string)my_no+" is registered.\nLow = "+(string)low+"\nHigh = "+(string)hig);
    integer i;
    for (i=0; i<capacity; i++) memory += [llFloor(llFrand(0xFFFFFFF0))];
    llOwnerSay("#"+(string)my_no+" Free memory: "+(string)llGetFreeMemory()+" bytes.");
}

check_trusted()
{
    if (llGetNumberOfPrims() > 1) {
        //llOwnerSay("Linkset detected. Root becomes trusted node!");
        trusted = llGetLinkKey(LINK_ROOT);
    } else trusted = NULL_KEY;
}

relisten()
{
    if (hLst) llListenRemove(hLst);
    check_trusted();
    hLst = llListen(icChan,"",trusted,"");
}

default
{
    state_entry()
    {
        my_no = (integer)llGetObjectDesc() - 1;
        low = -1;
        hig = -1;
        memory = [];
        owner = llGetOwner();
        relisten();
    }

    listen(integer ch, string nam, key id, string msg)
    {
        //if (llGetOwnerKey(id) != owner) return;
        if (msg == "TRCHECK") {
            key t_old = trusted;
            check_trusted();
            if (trusted != t_old) llResetScript();
        }
        if ((trusted != NULL_KEY) && (id != trusted)) return;
        list lt = llParseString2List(msg,[" "],[]);
        string vs = llList2String(lt,0);
        integer adr = llList2Integer(lt,1);
        if (vs == "GET") {
            if ((adr < low) || (adr > hig)) return;
            vs = "VAL "+(string)adr+" "+(string)llList2Integer(memory,(adr-low));
            if (trusted != NULL_KEY) vs += (" "+(string)trusted);
            out(vs);
        } else if (vs == "PUT") {
            if ((adr < low) || (adr > hig)) return;
            adr -= low;
            memory = llListReplaceList((memory=[])+memory,[llList2Integer(lt,2)],adr,adr);
            vs = "OK "+(string)(adr+low);
            if (trusted != NULL_KEY) vs += (" "+(string)trusted);
            out(vs);
        } else if (vs == "RESIZE")
            resize(llList2Integer(lt,1));
        else if (vs == "DELETE")
            llRemoveInventory(llGetScriptName());
        else if (msg == "RESET")
            llResetScript();
    }

    on_rez(integer p)
    {
        relisten();
    }
}
