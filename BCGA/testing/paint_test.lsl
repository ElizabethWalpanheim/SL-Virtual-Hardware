// (C) Elizabeth Walpanheim, 2012-2013
// License GPL

string mtx_obj_name = "display plane";

key Key_Op_SetPixel = "01010101-0000-0000-ffff-000000000001";
key Key_Op_GetPixel = "01010101-0000-0000-ffff-000000000002";
key Key_Op_SetPixelBlock = "01010101-0000-0000-ffff-000000000003";
key Key_Op_GetPixelBlock = "01010101-0000-0000-ffff-000000000004";
key Key_Op_SetScanline = "01010101-0000-0000-ffff-000000000005";
key Key_Op_GetScanline = "01010101-0000-0000-ffff-000000000006";
key Key_Op_GetScreenSize = "01010101-0000-0000-ffff-000000000007";
key Key_Op_ClearScreen = "01010101-0000-0000-ffff-000000000008";

integer mtx_obj;
key last_req = NULL_KEY;
integer FSM = 0;
integer width;
integer height;

default
{
    state_entry()
    {
        integer i = llGetNumberOfPrims() + 1;
        mtx_obj = LINK_ALL_OTHERS;
        while (--i)
            if (llGetLinkName(i) == mtx_obj_name) {
                mtx_obj = i;
                i = 1;
            }
        llMessageLinked(mtx_obj,0,"",Key_Op_ClearScreen);
        llSay(0,"Draw the figure on my main surface!\nSay 'clear' to clear the screen");
        llListen(0,"",llGetOwner(),"");
        last_req = Key_Op_GetScreenSize;
        FSM = 1;
        llMessageLinked(mtx_obj,0,"",last_req);
    }

    link_message(integer sndr, integer num, string str, key id)
    {
        if (sndr == llGetLinkNumber()) return;
        list l;
        if (id == last_req) {
            last_req = NULL_KEY;
            if (FSM == 1) {
                FSM = 2;
                l = llParseString2List(str,["|"],[]);
                width = llList2Integer(l,0);
                height = llList2Integer(l,1);
                llSay(0,"Screen matrix size: "+(string)width+"x"+(string)height);
            }
        }
    }

    touch(integer nd)
    {
        if (FSM < 2) return;
        vector tch = llDetectedTouchST(0);
        tch.x = 1 - tch.x; //invert X axis
        tch.x *= width;
        tch.y *= height;
        string s = "#";
        s += (string)((integer)tch.x);
        s += "|";
        s += (string)((integer)tch.y);
        llOwnerSay(s);
        llMessageLinked(mtx_obj,1,s,Key_Op_SetPixel);
    }

    listen(integer ch, string nm, key id, string msg)
    {
        if (msg == "clear") llMessageLinked(mtx_obj,0,"",Key_Op_ClearScreen);
    }

    on_rez(integer p)
    {
        llListen(0,"",llGetOwner(),"");
    }
}

