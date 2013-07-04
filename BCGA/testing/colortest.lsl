float tau = 1.0;
string mtx_obj_name = "display plane";

key Key_Op_SetPixelBlock = "01010101-0000-0000-ffff-000000000003";
key Key_Op_GetPixelBlock = "01010101-0000-0000-ffff-000000000004";
key Key_Op_GetScreenSize = "01010101-0000-0000-ffff-000000000007";
key Key_Op_ClearScreen = "01010101-0000-0000-ffff-000000000008";
key Key_Op_SetBlockColor = "01010101-0000-0000-ffff-000000000009";
key Key_Op_GetBlockColor = "01010101-0000-0000-ffff-00000000000a";
key Key_Op_SetColorMode = "01010101-0000-0000-ffff-00000000000b";
key Key_Op_GetColorMode = "01010101-0000-0000-ffff-00000000000c";
key Key_Op_Retrace = "01010101-0000-0000-ffff-00000000000d";

key Key_Answ_Ready = "01010101-1111-0000-ffff-000000000000";


integer mtx_obj;
key last_req = NULL_KEY;
integer FSM = 0;
integer width;
integer height;
integer wrows;
integer wcols;
integer pquad;
integer peak;

integer curr;
integer curc;

sub()
{
    vector v;
    string s;
    integer i;
    if ((FSM == 2) || (FSM == 6)) {
        FSM = 3;
        last_req = Key_Op_SetPixelBlock;
        i = (integer)llFrand(peak);
        s = "#" + (string)curc + "|" + (string)curr;
        llMessageLinked(mtx_obj,i,s,Key_Op_SetPixelBlock);
    } else if (FSM == 4) {
        FSM = 5;
        vector v = <llFrand(1),llFrand(1),llFrand(1)>;
        last_req = Key_Op_SetBlockColor;
        s = "#" + (string)curc + "|" + (string)curr + "|" + (string)v;
        if (++curc >= wcols) {
            if (++curr >= wrows) {
                FSM = 2;
                llSay(0,"ok");
                return;
            }
            curc = 0;
        }
        llMessageLinked(mtx_obj,0,s,Key_Op_SetBlockColor);
    }
}

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
        llMessageLinked(mtx_obj,1,"",Key_Op_SetColorMode);
        llMessageLinked(mtx_obj,0,"",Key_Op_ClearScreen);
        last_req = Key_Op_GetScreenSize;
        FSM = 1;
        llMessageLinked(mtx_obj,0,"",last_req);
        llSay(0,"Touch me");
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
                wcols = llList2Integer(l,2);
                wrows = llList2Integer(l,3);
                pquad = width / wcols;
                peak = (integer)llPow(2,pquad*pquad);
                llSay(0,"Screen matrix size: "+(string)width+"x"+(string)height);
            } else if ((FSM == 3) || (FSM == 5)) {
                if (num == 255) {
                    FSM++;
                    sub();
                } else
                    llSay(0,"Fatal error: received '"+str+"' with n="+(string)num);
            }
        }
    }

    touch_start(integer p)
    {
        if (FSM < 2) return;
        curr = 0;
        curc = 0;
        sub();
    }
}

