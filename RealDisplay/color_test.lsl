integer scr_pin = 103600;
vector tcolor = <1,0,1>;

mtext(string txt, integer on)
{
    if (on) llSetText(txt,tcolor,1.0);
    else llSetText("",ZERO_VECTOR,0.0);
}

default
{
    state_entry()
    {
        mtext("",0);
        llListen(0,"",llGetOwner(),"");
    }

    listen(integer chan, string name, key id, string msg)
    {
        if (msg == "purple") llMessageLinked(LINK_ALL_OTHERS,-601,"color<1,0,1>",NULL_KEY);
        else if (msg == "white") llMessageLinked(LINK_ALL_OTHERS,-601,"color<1,1,1>",NULL_KEY);
        else if (msg == "black") llMessageLinked(LINK_ALL_OTHERS,-601,"color<0,0,0>",NULL_KEY);
        else if (msg == "red") llMessageLinked(LINK_ALL_OTHERS,-601,"color<1,0,0>",NULL_KEY);
        else if (msg == "green") llMessageLinked(LINK_ALL_OTHERS,-601,"color<0,1,0>",NULL_KEY);
        else if (msg == "clear") llMessageLinked(LINK_ALL_OTHERS,-601,"clear",NULL_KEY);
        else if (msg == "solid") llMessageLinked(LINK_ALL_OTHERS,-601,"solid",NULL_KEY);
    }
}

