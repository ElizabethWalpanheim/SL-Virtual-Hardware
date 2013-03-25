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
integer chan = -113730;
integer loadPin = 68101201;

default
{
    state_entry()
    {
        llListen(chan,"","","");
        llSetRemoteScriptAccessPin(loadPin);
    }

    on_rez(integer p)
    {
        llResetScript();
    }

    listen(integer ch, string nm, key id, string mg)
    {
        if (llGetOwnerKey(id) != llGetOwner()) return;
        list vl = llParseString2List(mg,["|"],[]);
        string vs = llList2String(vl,0);
        integer i;
        vector v;
        if (vs == "setcolor") {
            v = (vector)llList2String(vl,1);
            llSetLinkColor(LINK_THIS,v,ALL_SIDES);
        } else if (vs == "setsize") {
            v = (vector)llList2String(vl,1);
            llSetScale(v);
        } else if (vs == "getsize") {
            llShout(chan,"size|"+(string)llGetScale());
        } else if (vs == "setpos") {
            v = (vector)llList2String(vl,1);
            llSetPos(v);
        } else if (vs == "setname") {
            llSetObjectName(llList2String(vl,1));
        } else if (vs == "setdesc") {
            llSetPrimitiveParams([PRIM_DESC,llList2String(vl,1)]);
        } else if (vs == "done") {
            llRemoveInventory(llGetScriptName());
            llSleep(1);
            return;
        }
    }
}
