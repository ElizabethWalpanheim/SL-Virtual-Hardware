/*
  LSCAD LSL dynamic logic simulator
  (C) Elizabeth Walpanheim, 2012
  The code may be licensed under the terms of GNU General Public License version 2

  BOARD SIDE script
*/

string version = "ver. 0.1.2 build 201";

list types_nm = ["BUF","2AND","2OR","1NOT","2AND-NOT","TRIG","GEN f/4","INSWITCH","LED","DIFF1"];
string logelem = "elem.obj";
integer CtrlChan = 7829;
integer DataChan = -222;
float z_offset = 0.10;
integer waitrez_limit = 12;
float crtdelay = 0.73;

vector msize;
list lpos;
list keys;
vector mypos;
integer waitrez;
key selected;
list answs;
integer run;
list etypes;
integer waitlinks;
key qNote;
integer lNote;
string sNote;
list tmpload;
integer linksbusy;

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

integer find_notecard(string name)
{
    integer n = llGetInventoryNumber(INVENTORY_NOTECARD);
    while(n)
        if (llGetInventoryName(INVENTORY_NOTECARD,--n) == name)
            return 1;
    return 0;
}

nextnoteline()
{
    lNote++;
    qNote = llGetNotecardLine(sNote,lNote);
    llOwnerSay("reading line "+(string)lNote);
}

newelem(integer type)
{
    if (waitrez) return;
    vector vp = llGetPos() - msize;
    vp.z += z_offset;
    llRezObject(logelem,vp,ZERO_VECTOR,ZERO_ROTATION,type);
    vp += msize*2; // first correction
    lpos += [vp];
    etypes += [type];
    //llOwnerSay("lastpos = "+(string)vp);
    waitrez = 1;
}

createlinks(key rx, list txds)
{
    integer i;
    integer n = llGetListLength(txds);
    integer k;
    key curtx;
    //create links in forward (as stored) direction!
    llOwnerSay((string)rx+" connects to:");
    for (i=0; i<n; i++) {
        k = llList2Integer(txds,i);
        if (k >= 0) {
            llShout(CtrlChan,"select|"+(string)rx);
            llSleep(crtdelay);
            llShout(CtrlChan,"ln");
            llSleep(crtdelay);
            curtx = llList2Key(keys,k);
            llOwnerSay((string)curtx);
            llShout(CtrlChan,"select|"+(string)curtx);
            if (n > 1) {
                llSleep(crtdelay);
                llSay(0,"%"+(string)i);
                llShout(CtrlChan,"%"+(string)i);
            }
            llSleep(crtdelay);
        }
    }
    llSay(0,(string)rx+" linked");
}

string transform_keys_to_links(string inp)
{
    //llSay(0,"transform() called with:\n"+inp);
    list vl = llParseString2List(inp,["|"],[]);
    if (llList2String(vl,0) == "reply_links") return inp;
    string r = "";
    integer i;
    integer k;
    integer m = llGetListLength(vl);
    string vs;
    // only forward direction of transformation!
    for (i=0; i<m; i++) {
        vs = llList2String(vl,i);
        k = llListFindList(keys,[(key)vs]);
        if (k < 0) {
            //llSay(0,"Element ["+vs+"] not found in keys[] !");
            r += "0|";
        } else {
            r += (string)(k+1) + "|";
        }
    }
    return r;
}

clear_mem()
{
    run = 0;
    linksbusy = 0;
    qNote = NULL_KEY;
    answs = [];
    keys = [];
    lpos = [];
    etypes = [];
    selected = NULL_KEY;
    waitrez = 0;
    waitlinks = 0;
    tmpload = [];
}

commandpu(string str, key from)
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
        run = 0;
    } else if (cmd == "select") {
        trg = (key)llList2String(vl,1);
        if (!bool_keynull(trg)) selected = trg;
        else selected = NULL_KEY;
        llSay(0,(string)selected+" selected");
    } else if ((cmd == "changemind") && (!bool_keynull(selected))) {
        // TODO
    } else if (cmd == "move") {
        // user will not even know about the MOVE command
        // no process it
    } else if ((cmd == "deselected") && (from == selected)) {
        selected = NULL_KEY;
        llOwnerSay("deselect received");
    } else if (cmd == "new") {
        //ti = llListFindList(types_nm,[llList2String(vl,1)]);
        // case insensitive search
        ti = llGetListLength(types_nm);
        cmd = llToUpper(llList2String(vl,1));
        while (--ti >= 0) {
            if (llToUpper(llList2String(types_nm,ti)) == cmd) {
                newelem(ti);
                return;
            }
        }
        //if (ti < 0) {
            llSay(0,"Unknown object type");
            llSay(0,"Registered object types are:\n"+llDumpList2String(types_nm,"\n"));
        //} else newelem(ti);
    } else if (cmd == "run") {
        run = 1;
        answs = [];
        waitlinks = 0;
        llShout(CtrlChan,"action");
        llSleep(1.0);
        llShout(CtrlChan,"q");
        llSay(0,"Started");
    } else if (cmd == "stop") {
        run = 0;
        waitlinks = 0;
        llShout(CtrlChan,"edit");
        llSay(0,"Stopped");
    } else if (cmd == "list") {
        llSay(0,"List of element types:\n"+llDumpList2String(types_nm,"\n"));
    } else if (cmd == "erase") {
        llShout(CtrlChan,"delete_all");
        clear_mem();
        llSay(0,"Board erased.");
    } else if (cmd == "save") {
        llShout(CtrlChan,"select"); //deselect all
        llSleep(crtdelay);
        mypos = llGetPos();
        ti = llGetListLength(keys);
        if (ti < 1) return;
        // initiate the process
        llShout(CtrlChan,"dumplinks|"+(string)llList2Key(keys,0));
        waitlinks = 1;
    } else if ((cmd == "reply_links") && (waitlinks > 0)) {
        // second half of the SAVE command
        vector vv;
        vv = llList2Vector(lpos,waitlinks-1) - mypos - msize;
        vv *= -1;
        llSay(0,(string)(llList2Integer(etypes,waitlinks-1)+1)+"|"+ // type of elem incemented by one to correct recognize it later
                (string)vv+"|"+ // transformed co-ords
                transform_keys_to_links(llGetSubString(str,12,-1))); // transformed links data
        if (waitlinks >= llGetListLength(keys)) {
            waitlinks = 0;
            llSay(0,"--- end ---");
            return;
        }
        llShout(CtrlChan,"dumplinks|"+(string)llList2Key(keys,waitlinks));
        waitlinks++;
    } else if (cmd == "ldtest") {
        llShout(CtrlChan,"delete_all");
        newelem(0);
        llSleep(0.5);
        vector vv;
        vv.y = llList2Float(vl,2);
        vv.x = llList2Float(vl,1);
        llSay(CtrlChan,"move| |"+(string)vv.x+"|"+(string)vv.y+"|0.0");
        lpos = llListReplaceList(lpos,[llList2Vector(lpos,0)-vv],0,0);
    } else if (cmd == "load") {
        cmd = llList2String(vl,1);
        if (find_notecard(cmd)) {
            llShout(CtrlChan,"delete_all");
            clear_mem();
            sNote = cmd;
            lNote = -1;
            nextnoteline();
        } else llSay(0,"Notecard '"+cmd+"' was not found in object's inventory!");
    } else if (cmd == "dumpos") {
        list vl;
        for (ti=0; ti<llGetListLength(lpos); ti++) {
            trg = llList2Key(keys,ti);
            vl = llGetObjectDetails(trg,[OBJECT_POS]);
            llSay(0,(string)trg+"\nlpos: "+(string)llList2Vector(lpos,ti)+"\nreal: "+(string)llList2Vector(vl,0));
        }
        //llSay(0,llDumpList2String(lpos,"\n"));
    } else if (cmd == "getmem") {
        llSay(0,"Board's free memory: "+(string)llGetFreeMemory()+" bytes.");
        integer mm = 0;
        ti = llGetListLength(keys);
        while (--ti >= 0)
            mm += llList2Integer(llGetObjectDetails(llList2Key(keys,ti),[OBJECT_SCRIPT_MEMORY]),0);
        llSay(0,"Total memory used by logic elements: "+(string)mm+" bytes.");
    }
}

default
{
    state_entry()
    {
        llSay(0,"LSCAD LSL v 0.1\n(C) Elizabeth Walpanheim, 2012");
        llSay(0,version);
        msize = llGetScale();
        llSay(0,"Board dimensions is "+(string)msize);
        msize.x = msize.x / 2;
        msize.y = msize.y / 2;
        msize.z = 0.0;
        clear_mem();
        mypos = llGetPos();
        llListen(0,"",llGetOwner(),"");
        llListen(CtrlChan,"","","");
        llListen(DataChan,"","","");
        llSetTimerEvent(1.0);
        llSay(0,"LSCAD LSL board is ready now!");
        llShout(CtrlChan,"delete_all");
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
        tch.z = lps.z; // hold Z axis correctly (it's a sick hack to get rid of z-deviation error)
        lpos = llListReplaceList(lpos,[tch],i,i);
        tch = tch - lps;
        tch *= -1.0; // invert to region co-ords
        llSay(0,(string)tch);
        llShout(CtrlChan,"move|"+(string)selected+"|"+(string)tch.x+"|"+(string)tch.y+"|0.0");
    }
    
    listen(integer chan, string name, key id, string msg)
    {
        if (linksbusy) return;
        if ((chan == 0) || (chan == CtrlChan)) commandpu(msg,id);
        if ((chan == DataChan) && (run)) {
            integer a = llListFindList(answs,[id]);
            if (a >= 0) return;
            a = llListFindList(keys,[id]);
            //llOwnerSay((string)a);
            if (a < 0) return;
            answs += [id];
            if (llGetListLength(answs) == llGetListLength(keys)) {
                //llOwnerSay("cycle done");
                llSleep(0.1);
                answs = [];
                llShout(CtrlChan,"q");
            }
        }
    }
    
    object_rez(key id)
    {
        if (waitrez > 0) {
            llSay(0,(string)id+" registered");
            //list l = llGetObjectDetails(id,[OBJECT_POS]);
            //llOwnerSay("Real pos is "+llDumpList2String(l," "));
            keys += [id];
            waitrez = 0;
            if (!bool_keynull(qNote)) {
                llSleep(crtdelay);
                integer i = llGetListLength(tmpload) - 1;
                list vl = llParseString2List(llList2String(tmpload,i),["|"],[]);
                //llOwnerSay("^^^\n"+llDumpList2String(vl,"\n"));
                vector vv = (vector)llList2String(vl,1); // get vector
                //llOwnerSay("NEW vector is : "+(string)vv);
                vv.z = mypos.z + z_offset; // correct Z
                lpos = llListReplaceList(lpos,[llList2Vector(lpos,i)-vv],i,i);
                llShout(CtrlChan,"move|"+(string)id+"|"+(string)vv.x+"|"+(string)vv.y+"|0.0");
                nextnoteline();
            }
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
        if (waitrez > 0) {
            if (waitrez > waitrez_limit) {
                waitrez = 0;
                llSay(0,"Rez waiting timed out!\nFailed to rez new element.");
                integer k = llGetListLength(lpos) - 1;
                lpos = llDeleteSubList(lpos,k,k);
            } else waitrez++;
        }
    }
    
    dataserver(key qid, string data)
    {
        if (qNote != qid) return;
        list vl;
        string va;
        integer i;
        if (data == EOF) {
            integer m = llGetListLength(tmpload);
            integer j;
            integer k;
            integer w;
            integer ksn = llGetListLength(keys);
            list vbi;
            llSay(0,"Load done. Recreating the links...");
            linksbusy = 1;
            for (i=0; i<m; i++) {
                vl = llParseString2List(llList2String(tmpload,i),["|"],[]);
                k = llGetListLength(vl);
                vbi = [];
                for (j=2; j<k; j++) {
                    va = llList2String(vl,j);
                    if (va == "reply_links") {
                        j = k; //break
                    } else {
                        w = (integer)va;
                        if ((w >= 0) && (w <= ksn)) vbi += [w-1];
                    }
                }
                llSay(0,"Links prepared:\n"+llDumpList2String(vbi,", "));
                if (llGetListLength(vbi) > 0)
                    createlinks(llList2Key(keys,i),vbi);
            }
            llSleep(2.0);
            linksbusy = 0;
            tmpload = [];
            qNote = NULL_KEY;
            llSay(0,"Scheme reading finished!");
            return;
        }
        if (data == "") return;
        vl = llParseString2List(data,["|"],[]);
        va = llGetSubString(llList2String(vl,0),-2,-1); //get last symbols from beginning
        i = (integer)va;
        if ((i < 1) || (i > llGetListLength(types_nm))) {
            nextnoteline(); // just skip unrecognized line
            return;
        }
        i--;
        llSay(0,"Detected object type #"+(string)i);
        tmpload += [data];
        newelem(i);
    }
}
