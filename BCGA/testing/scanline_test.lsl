string mtx_obj_name = "display plane";

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

integer mtx_obj;
key last_req = NULL_KEY;
integer FSM = 0;
integer width;
integer height;
integer cy;

next()
{
    string s = "";
    integer x;
    for (x=0; x<width; x++) {
        if (llFrand(1) < 0.5) s += "1";
        else s += "0";
    }
    FSM = 3;
    last_req = Key_Op_SetScanline;
    llOwnerSay((string)cy);
    llMessageLinked(mtx_obj,cy,s,Key_Op_SetScanline);
    if (++cy >= height) {
        FSM = 2;
        llSay(0,"ok");
        llMessageLinked(mtx_obj,0,"",Key_Op_Retrace);
        return;
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
        llMessageLinked(mtx_obj,0,"",Key_Op_SetColorMode);
        llMessageLinked(mtx_obj,0,"",Key_Op_ClearScreen);
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
            } else if ((FSM == 3) && (num == 255)) {
                FSM = 4;
                //llMessageLinked(mtx_obj,0,"",Key_Op_Retrace);
                next();
            }
        }
    }

    touch_start(integer p)
    {
        if (FSM == 2) {
            cy = 0;
            next();
        }
    }
}

