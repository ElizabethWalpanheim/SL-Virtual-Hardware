//    Objects matrix generator
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
string ledname = "tranz-4.4";
integer ledchan = -113730;
float delay = 0.15;
integer qty = 64;
vector ledcolor = <1, 1, 1>;
vector size = <0.01, 0.01, 0.02>;
float dx = 0.01;
float dy = 0.01;
float dz = 0.01;
integer ret = 0;
vector cpos;
vector rect;
integer cur;

default
{
    state_entry()
    {
        if (ret) {
            llShout(ledchan,"done");
            llSay(0,"Creation done");
        } else {
            integer x = llFloor(llSqrt(qty));
            cpos = llGetPos();
            cpos.x -= (float)x/2 * dx;
            cpos.y -= (float)x/2 * dy;
            cpos.z += dz;
            rect.x = cpos.x + (float)x * dx;
            rect.y = cpos.y + (float)x * dy;
            rect.z = cpos.x;
            llSay(0,"x = "+(string)x+"\ncpos = "+(string)cpos+"\nrect = "+(string)rect);
            state creator;
        }
        ret = 0;
    }
}

state creator
{
    state_entry()
    {
        cur = 0;
        ret = 1;
        llRezObject(ledname,cpos,ZERO_VECTOR,ZERO_ROTATION,1);
    }

    object_rez(key id)
    {
        llRegionSayTo(id,ledchan,"setcolor|"+(string)ledcolor);
        llRegionSayTo(id,ledchan,"setsize|"+(string)size);
        llRegionSayTo(id,ledchan,"setname|icmem");
        llRegionSayTo(id,ledchan,"setdesc|"+(string)(cur+1));
        llSleep(delay);
        llOwnerSay((string)cur);
        if (++cur >= qty) {
            state default;
        } else {
            cpos.x += dx;
            if (cpos.x > rect.x) {
                cpos.y += dy;
                if (cpos.y > rect.y) {
                    llSay(0,"No room to make more LEDs!");
                    state default;
                }
                cpos.x = rect.z;
            }
            llRegionSay(ledchan,"done");
            llRezObject(ledname,cpos,ZERO_VECTOR,ZERO_ROTATION,1);
        }
    }
}
