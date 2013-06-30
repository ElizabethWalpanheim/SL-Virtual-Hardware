// (C) Elizabeth Walpanheim, 2012-2013
// License GPL
// rev 20130630-01

key Key_Cell_Control = "01010101-0000-0000-0000-123456780bb2";
integer NumSides = 8;
integer qty = 256;
list uids = [
"4a8eafe5-03c6-479f-918a-8a4c28b57df9",
"7655546b-5b38-8d96-60c9-b55ff8357f49",
"8f4bbdb6-5e48-8eee-2297-7a4277f91805",
"249ccf33-509c-e04c-cada-feb2b18b5348" ];

integer ntxd;
integer qdr;
float size;
float half;
float fth;

setn(integer side, integer x)
{
    integer gx = x % qty;
    if (gx >= qty) return;
    integer gy = x / qty;
    if (gy >= qty) return;
    integer tex = (gy / qdr) * (ntxd / 2) + gx / qdr;
    if ((tex < 0) || (tex >= ntxd)) tex = 0; //just to prevent crashes
    key uid = llList2Key(uids,tex);
    float ax = (fth-1) - (gx%qdr);
    float ay = (fth-1) - (gy%qdr);
    vector off = <-half, half, 0>;
    off.x -= size * ax;
    off.y += size * ay;
    llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_TEXTURE,side,uid,<size,size,0>,off,0]);
}

default
{
    state_entry()
    {
        ntxd = llGetListLength(uids);
        qdr = qty / 2;
        size = 1.0 / (float)qdr;
        half = size / 2.0;
        fth = (float)qdr / 2.0;
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if (id != Key_Cell_Control) return;
        if (str == "RESET") {
            llResetScript();
            return;
        }
        list l = llParseString2List(str,["|"],[]);
        integer i;
        integer n = llGetListLength(l);
        for (i=0; ((i<NumSides) && (i<n)); i++)
            setn(i,(integer)llList2String(l,i));
    }
}

