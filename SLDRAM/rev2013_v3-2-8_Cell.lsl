key memory_io = "12345678-0000-0000-0000-e1e2e3e4e5ff";
integer capacity;
list memory;
integer my_no;
key owner;
integer low;
integer hig;

debug(string msg)
{
    llOwnerSay("Module debug (#"+(string)my_no+"): "+msg);
}

resize(integer sz)
{
    memory = [];
    if (my_no < 0) return;
    capacity = sz;
    low = capacity * my_no;
    hig = low + capacity - 1;
    debug("Number "+(string)my_no+" is registered.\nLow = "+(string)low+"\nHigh = "+(string)hig);
    integer i;
    for (i=0; i<capacity; i++) memory += [llFloor(llFrand(0xFFFFFFF0))];
    debug("Free memory: "+(string)llGetFreeMemory()+" bytes.");
}

default
{
    state_entry()
    {
        my_no = (integer)llGetSubString(llGetObjectName(),2,-1) - 1;
        low = -1;
        hig = -1;
        memory = [];
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if (id != memory_io) return;
        if (str == "GET") {
            if ((num < low) || (num > hig)) return;
            debug((string)num+" accepted: "+str);
            llMessageLinked(sender,num,"VAL "+(string)llList2Integer(memory,(num-low)),memory_io);
        } else if (llGetSubString(str,0,2) == "PUT") {
            if ((num < low) || (num > hig)) return;
            debug((string)num+" accepted: "+str);
            num -= low;
            memory = llListReplaceList((memory=[])+memory,[llGetSubString(str,4,-1)],num,num);
            llMessageLinked(sender,num+low,"OK",memory_io);
        } else if (str == "RESIZE") {
            resize(num);
        } else if (str == "DELETE") {
            llRemoveInventory(llGetScriptName());
        } else if (str == "RESET") {
            llResetScript();
        }
    }
}
