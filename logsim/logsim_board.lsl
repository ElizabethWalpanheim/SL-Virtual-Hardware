/*
  LSCAD LSL dynamic logic simulator
  (C) Elizabeth Walpanheim, 2012
  The code may be licensed under the terms of GNU General Public License version 2

  BOARD SIDE script
*/

list types_nm = ["BUF","2AND","2OR","1NOT","2AND-NOT","TRIG","GEN f/4","INSWITCH","LED","DIFF1"];
string logelem = "elem";
integer CtrlChan = 7829;
integer DataChan = -222;
float z_offset = 0.10;
vector msize;
list lpos;
list keys;
vector mypos;
integer waitrez;
key selected;

integer bool_keynull(key k)
{
    // The fucking LSL makes the fucking difference between NULL_KEY and empty string
    // even the empty string IS a key and IS valid!!! And NOT EQUAL to fuckin' NULL_KEY!!!
    // What! The! Fuck?! Eh, Lindens?!
    if (k == NULL_KEY) return 1;
    else if (k == "") return 1;
    else if (llStringLength(k) < 36) return 1; // even that >8-[
    else return 0;
}

newelem(integer type)
{
    if (waitrez) return;
    vector vp = llGetPos() - msize;
    vp.z += z_offset;
    llRezObject(logelem,vp,ZERO_VECTOR,ZERO_ROTATION,type);
    vp += msize*2; // first correction
    lpos += [vp];
    waitrez = 1;
}

commandpu(string str)
{
    list vl = llParseString2List(str,["|"],[]);
    string cmd = llList2String(vl,0);
    key trg = NULL_KEY;
    integer ti;
    if ((cmd == "del") && (!bool_keynull(selected))) {
        ti = llListFindList(keys,[selected]);
        if (ti < 0) return; // strange, but...
        keys = llDeleteSubList(keys,ti,ti);
        lpos = llDeleteSubList(lpos,ti,ti);
        llSay(0,(string)selected+" deregistered");
        selected = NULL_KEY;
    } else if (cmd == "edit") {

    } else if (cmd == "action") {

    } else if (cmd == "select") {
        trg = (key)llList2String(vl,1);
        if (!bool_keynull(trg)) selected = trg;
        else selected = NULL_KEY;
        llSay(0,(string)selected+" selected");
    } else if ((cmd == "changemind") && (!bool_keynull(selected))) {

    } else if (cmd == "move") {
        // user will not even know about the MOVE command
    } else if ((cmd == "ln") && (!bool_keynull(selected))) {

    } else if (cmd == "new") {
        ti = llListFindList(types_nm,[llList2String(vl,1)]);
        if (ti < 0) {
            llSay(0,"Unknown object type");
            llSay(0,"Registered object types are:\n"+llDumpList2String(types_nm,"\n"));
        } else newelem(ti);
    }
}

default
{
    state_entry()
    {
        msize = llGetScale();
        llSay(0,(string)msize);
        msize.x = msize.x / 2;
        msize.y = msize.y / 2;
        msize.z = 0.0;
        lpos = [];
        keys = [];
        waitrez = 0;
        mypos = llGetPos();
        llListen(0,"",llGetOwner(),"");
        llListen(CtrlChan,"","","");
        llListen(DataChan,"","","");
        llSetTimerEvent(1.0);
    }

    touch_start(integer total_number)
    {
        if (bool_keynull(selected)) return;
        vector tch = llDetectedTouchST(0);
        //llSay(0,"Touched @ "+(string)tch);
        integer i = llListFindList(keys,[selected]);
        if (i < 0) return;
        tch.x *= msize.x*2;
        tch.x -= msize.x;
        tch.y *= msize.y*2;
        tch.y -= msize.y;
        tch.z = 0.0;
        tch = llGetPos() - tch;
        vector lps = llList2Vector(lpos,i);
        lpos = llListReplaceList(lpos,[tch],i,i);
        tch = tch - lps;
        tch *= -1.0; // invert to region co-ords
        llSay(0,(string)tch);
        llSay(CtrlChan,"move|"+(string)selected+"|"+(string)tch.x+"|"+(string)tch.y+"|0.0");
    }
    
    listen(integer chan, string name, key id, string msg)
    {
        if ((chan == 0) || (chan == CtrlChan)) commandpu(msg);
    }
    
    object_rez(key id)
    {
        if (waitrez) {
            llSay(0,(string)id+" registered");
            keys += [id];
            waitrez = 0;
        }
    }
    
    timer()
    {
        if (llVecDist(mypos,llGetPos()) > .001) {
            vector vt = llGetPos() - mypos;
            key vk = NULL_KEY;
            llRegionSay(CtrlChan,"move|"+(string)vk+"|"+(string)vt.x+"|"+(string)vt.y+"|"+(string)vt.z);
            mypos = llGetPos();
            llResetTime();
        }
    }
}
