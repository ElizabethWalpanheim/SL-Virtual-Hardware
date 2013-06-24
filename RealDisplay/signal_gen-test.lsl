/*
    Real 80x25 display
    Continous Signal Generator test script
    
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

float tau = 0.05;
integer mChan = -101006;
integer xChan = -102006;
string hello = "Eliz's pseudo-graphic signal generator";
list img;
integer ptr;
//string rules = "01101010"; //inverted Wolfram's rule
string rules =   "01011010";
list pattern = ["000","001","010","011","100","101","110","111"];
string border = "0";
integer tick;

string genstr(string char, integer len)
{
    string s;
    while (--len >= 0) s += char;
    return s;
}

point(integer xx, integer yy, string char)
{
    string vs = llList2String(img,yy);
    vs = llGetSubString(vs,0,xx-1) + char + llGetSubString(vs,xx+1,-1);
    img = llListReplaceList(img,[vs],yy,yy);
}

string getbit(integer x, integer y)
{
    string vs = llList2String(img,y);
    if (llGetSubString(vs,x,x) != ".") return "1";
    else return "0";
}

step()
{
    integer x;
    integer y;
    string c;
    integer a;
    for (x=1; x<79; x++) {
        y = tick - 1;
        if (y < 1) y = 23;
        if (x == 1) c = border;
        else c = getbit(x-1,y);
        c += getbit(x,y);
        if (x == 78) c += border;
        else c += getbit(x+1,y);
        y++;
        if (y > 23) y = 1;
        for (a=0; a<8; a++)
            if ((llList2String(pattern,a) == c) && (llGetSubString(rules,a,a) == "1")) {
                c = "";
                //llOwnerSay("rule "+(string)a+" accepted");
                point(x,y,"#");
                a = 8;
            }
        if (c != "") point(x,y,".");
    }
    llSetTimerEvent(tau);
}

default
{
    state_entry()
    {
        llSay(xChan,"setmode|-100");
        llSetTimerEvent(tau);
        integer i = 24;
        img = [hello+genstr("*",(80-llStringLength(hello)))];
        while (--i > 0) img += [("|"+genstr(".",78)+"|")];
        img += [genstr("*",80)];
        point(39,1,"#");
        tick = 1;
    }

    timer()
    {
        llSay(mChan,llList2String(img,ptr++));
        if (ptr > 24) {
            ptr = 0;
            llResetTime();
            llSetTimerEvent(0);
            //llSay(xChan,"framesync");
            tick++;
            if (tick > 23) tick = 1;
            step();
        }
        llSetText((string)ptr,<1,1,1>,1);
    }

    touch_start(integer total_number)
    {
        llSay(0, "Touched.");
        llSetTimerEvent(0);
    }
}

