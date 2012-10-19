// Atmel (r) AVR (r) ATTiny 85  LSL emulator
// (C) Elizabeth Walpanheim, 2012
// This code can be licensed under the terms of GPL v2
// For techical details about instruction set
// refer to Atmel's "8-bit AVR instruction set" Rev. 0856I–AVR–07/10
// For details about ATTiny85 chip, refer to it datasheet.

integer debug = 1;
integer IP = 0;
list regs;
list ioreg;
list sram;
integer sram_length = 512; //SRAM length only
string sreg; // status register (ITHSVNZC)
integer opresult;
string accum;
integer X_register = 27; // XHigh byte (R26 - low)
integer Y_register = 29; // Yhigh
integer Z_register = 31; // Zhigh

sout(string msg)
{
    llSay(0,msg);
}

wdebug(string msg)
{
    if (debug) sout("DEBUG: "+msg);
}

string ss(string in, integer a, integer b)
{
    // just shorthand function
    return (llGetSubString(in,a,b));
}

string invertb(string b)
{
    if (b == "0") return ("1");
    else return ("0");
}

string invertw(string b)
{
    integer i = llStringLength(b);
    string r = "";
    while (--i >= 0) {
        if (ss(b,i,i) == "1") r = "0" + r;
        else r = "1" + r;
    }
    return r;
}

string int2bin(integer a)
{
    integer i;
    string buf = "";
    if (a > 255)
        return ("11111111");
    integer j = 128;
    for (i=7; i>=0; i--) {
        if (a-j >= 0) {
            buf += "1";
            a -= j;
        } else buf += "0";
        j = j >> 1;
    }
    return buf;
}

integer bin2int(string s)
{
    integer i = llStringLength(s);
    integer j = 1;
    integer r = 0;
    while (--i >= 0) {
        if (llGetSubString(s,i,i) == "1") r += j;
        j = j << 1;
    }
    return r;
}

string int2hex(integer a)
{
    string r;
    //
    return r;
}

integer hex2int(string s)
{
    //
    return 0;
}

integer pack2(integer hi, integer lo)
{
    return ( ((hi & 255) << 8) | lo );
}

integer unpack2(integer val, integer k)
{
    if (k)
        return ((val >> 8) & 255);
    else
        return (val & 255);
}

integer msk(string in, string mask)
{
    integer i = llStringLength(mask);
    string vchar;
    while (--i >= 0) {
        vchar = ss(mask,i,i);
        if ((vchar != "x") && (vchar != ss(in,i,i)))
            return FALSE;
    }
    return TRUE;
}

integer getregi(string num)
{
    integer n = bin2int(num);
    if (n > 31) return 0;
    return (llList2Integer(regs,n));
}

setregi(string num, integer val)
{
    val = val & 255; // watch for overflow!
}

integer getmem(integer addr)
{
    if (addr > sram_length + 96) return 0;
    if (addr < 32)
        return (llList2Integer(regs,addr));
    integer r;
    integer s;
    if (addr < 64) {
        // I/O registers
        addr -= 32;
        r = llList2Integer(ioreg,(addr/4));
    } else {
        addr -= 96;
        r = llList2Integer(sram,(addr/4));
    }
    s = llAbs((addr % 4) - 3) * 8;
    wdebug("getmem(): $"+(string)addr+": word '"+(string)r+"' with "+(string)s+" shifts");
    r = (r >> s) & 255;
    return r;
}

setmem(integer addr, integer val)
{
    //TODO
}

integer getflag(string flg)
{
    integer i = llListFindList(["I","T","H","S","V","N","Z","C"],[flg]);
    if (i < 0) return 0;
    else if (ss(sreg,i,i) != "0") return 1;
    else return 0;
}

setflag(string flg, string sta)
{
    if ((sta != "1") && (sta != "0")) return;
    integer i = llListFindList(["I","T","H","S","V","N","Z","C"],[flg]);
    if (i < 0) return;
    wdebug("set flag "+flg+" to "+sta);
    if ((i > 0) && (i < 7))
        sreg = ss(sreg,0,i-1) + sta + ss(sreg,i+1,-1);
    else if (i == 0)
        sreg = sta + ss(sreg,1,-1);
    else
        sreg = ss(sreg,0,6) + sta;
    wdebug("Status REG = "+sreg);
}

flags(string which)
{
    // sets the flags which described in input string
}

push(integer word, integer len)
{
    //
}

integer pop(integer len)
{
    //
    return 0;
}

macro_ldd(string Rd, integer xyz, integer inc)
{
    opresult = pack2(getmem(xyz),getmem(xyz-1));
    if (inc < 0) opresult--;
    setregi(Rd,getmem(opresult));
    if (inc > 0) opresult++;
    setmem(xyz,unpack2(opresult,1));
    setmem(xyz-1,unpack2(opresult,0));
}

cpu(integer opcode)
{
    /*if (opcode > 65535) {
        wdebug("Invalid opcode: "+(string)opcode+" @ "+(string)IP);
        return;
    }*/
    // warning! opcode transferred in left-aligned form with full 32 bits
    integer orcode = opcode & 65535; // for 32-bit instructions (we need it, sic!)
    opcode = (opcode >> 16) & 65535;
    string bhi = int2bin((opcode >> 8) & 255);
    string blo = int2bin(opcode & 255);
    wdebug("cmd: "+bhi+" "+blo);
    string Rd = "";
    string Rr = "";
    string K = "";
    opresult = 0;
    // WARNING! Instruction mask test below this line is not optimized!
    // FIXME: mix branches in instruction groups to speed up the code
    if (msk(bhi,"000x11xx")) {            // ADC / ROL / ADD / LSL
        wdebug("ADC/ROL/ADD/LSL");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        Rr = ss(bhi,6,6) + ss(blo,4,7);
        opresult = getregi(Rd);
        if (Rd == Rr) opresult = opresult << 1;
        else opresult += getregi(Rr);
        if (ss(bhi,3,3) == "1") // ADC/ROL
            opresult += getflag("C");
        setregi(Rd,opresult);
        flags("HSVNZC");
        IP++;
    } else if (bhi == "10010110") {     //adiw
        IP++;
    } else if (msk(bhi,"001000xx")) {     //and
        IP++;
    } else if (msk(bhi,"0111xxxx")) {     //andi
        IP++;
    } else if ((msk(bhi,"1001010x")) && (msk(blo,"xxxx0101"))) {     //asr
        IP++;
    } else if ((msk(bhi,"111101xx")) && (msk(blo,"xxxxx000"))) {     //brcc
        IP++;
    } else if ((msk(bhi,"111100xx")) && (msk(blo,"xxxxx000"))) {     //brcs
        IP++;
    } else if ((msk(bhi,"111100xx")) && (msk(blo,"xxxxx001"))) {     //breq
        IP++;
    } else if ((msk(bhi,"111100xx")) && (msk(blo,"xxxxx010"))) {     //brmi
        IP++;
    } else if ((msk(bhi,"111101xx")) && (msk(blo,"xxxxx001"))) {     //brne
        IP++;
    } else if ((msk(bhi,"111100xx")) && (msk(blo,"xxxxx110"))) {     //brts
        IP++;
    } else if ((bhi == "10010100") && (msk(blo,"0xxx1000"))) {     //bset
        IP++;
    } else if ((bhi == "10010100") && (blo == "10001000")) {     //clc
        IP++;
    } else if (msk(bhi,"001001xx")) {     //clr
        IP++;
    } else if ((bhi == "10010100") && (blo == "11101000")) {     //clt
        IP++;
    } else if ((msk(bhi,"1001010x")) && (msk(blo,"xxxx0000"))) {     //com
        IP++;
    } else if (msk(bhi,"000101xx")) {     //cp
        IP++;
    } else if (msk(bhi,"0011xxxx")) {     //cpi
        IP++;
    } else if (msk(bhi,"000100xx")) {     //cpse
        IP++;
    } else if ((msk(bhi,"1001010x")) && (msk(blo,"xxxx1010"))) {     //dec
        IP++;
    } else if (msk(bhi,"001001xx")) {     //eor
        IP++;
    } else if ((bhi == "10010100") && (blo == "00001001")) {     //ijmp
        IP++;
    } else if (msk(bhi,"10110xxx")) {     //in
        IP++;
    } else if ((msk(bhi,"1001010x")) && (msk(blo,"xxxx0011"))) {     //inc
        IP++;
    } else if ((msk(bhi,"1001000x")) && (msk(blo,"xxxx1100"))) {      // LD(1)
        wdebug("LD: Rd <- X; x unchanged");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        macro_ldd(Rd,X_register,0);
        //flags unchanged in all LD/LDD instructions
        IP++;
    } else if ((msk(bhi,"1001000x")) && (msk(blo,"xxxx1101"))) {      // LD(2)
        wdebug("LD: Rd <- X; X <- X+1");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        macro_ldd(Rd,X_register,1);
        IP++;
    } else if ((msk(bhi,"1001000x")) && (msk(blo,"xxxx1110"))) {      // LD(3)
        wdebug("LD: X <- X-1; Rd <- X");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        macro_ldd(Rd,X_register,-1);
        IP++;
    } else if ((msk(bhi,"1000000x")) && (msk(blo,"xxxx1000"))) {      // LD/D Y (1)
        wdebug("LDD: Rd <- Y");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        macro_ldd(Rd,Y_register,0);
        IP++;
    } else if ((msk(bhi,"1001000x")) && (msk(blo,"xxxx1001"))) {      // LD/D Y (2)
        wdebug("LDD: Rd <- Y; Y <- Y+1");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        macro_ldd(Rd,Y_register,1);
        IP++;
    } else if ((msk(bhi,"1001000x")) && (msk(blo,"xxxx1010"))) {      // LD/D Y (3)
        wdebug("LDD: Y <- Y-1; Rd <- Y");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        macro_ldd(Rd,Y_register,-1);
        IP++;
    } else if ((msk(bhi,"10x0xx0x")) && (msk(blo,"xxxx1xxx"))) {      // LD/D Y (4)
        wdebug("LDD: Rd <- (Y+q)");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        K = ss(bhi,2,2) + ss(bhi,4,5) + ss(blo,5,7);
        opresult = pack2(getmem(Y_register),getmem(Y_register-1));
        setregi(Rd,getmem(opresult+bin2int(K)));
        IP++;
    } else if ((msk(bhi,"1000000x")) && (msk(blo,"xxxx0000"))) {      // LD/D Z (1)
        wdebug("LDD: Rd <- Z");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        macro_ldd(Rd,Z_register,0);
        IP++;
    } else if ((msk(bhi,"1001000x")) && (msk(blo,"xxxx0001"))) {      // LD/D Z (2)
        wdebug("LDD: Rd <- Z; Z <- Z+1");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        macro_ldd(Rd,Z_register,1);
        IP++;
    } else if ((msk(bhi,"1001000x")) && (msk(blo,"xxxx0010"))) {      // LD/D Z (3)
        wdebug("LDD: Z <- Z-1; Rd <- Z");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        macro_ldd(Rd,Z_register,-1);
        IP++;
    } else if ((msk(bhi,"10x0xx0x")) && (msk(blo,"xxxx0xxx"))) {      // LD/D Z (4)
        wdebug("LDD: Rd <- (Z+q)");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        K = ss(bhi,2,2) + ss(bhi,4,5) + ss(blo,5,7);
        opresult = pack2(getmem(Z_register),getmem(Z_register-1));
        setregi(Rd,getmem(opresult+bin2int(K)));
        IP++;
    } else if (msk(bhi,"1110xxxx")) {                //ldi
        wdebug("LDI");
        Rd = "1" + ss(blo,0,3); // 16-31
        K = ss(bhi,4,7) + ss(blo,4,7);
        setregi(Rd,bin2int(K));
        //no flags
        IP++;
    } else if ((msk(bhi,"1001000x")) && (msk(blo,"xxxx0000"))) {     // LDS(32)
        wdebug("LDS operand = "+(string)orcode);
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        setregi(Rd,getmem(orcode));
        // no flags
        IP += 2;
    } else if (msk(bhi,"10100xxx")) {              // LDS(16)
        wdebug("LDS in 16-bit form engaged! WTF?!");
        Rd = "1" + ss(blo,0,3); // 16-31
        K = ss(bhi,7,7);
        K = invertb(K) + K + ss(bhi,5,6) + ss(blo,4,7); // holy shit! :)
        wdebug("LDS(16) address unpacked to form of "+K);
        setregi(Rd,getmem(bin2int(K)));
        IP++;
    } else if ((bhi == "10010101") && (blo == "11001000")) {        // LPM(1)
        wdebug("LPM first form");
        Rd = "00";
        // don't forget about Zlsb
        // no flags
        IP++;
    } else if ((msk(bhi,"1001000x")) && (msk(blo,"xxxx010x"))) {    // LPM (2/3)
        wdebug("LPM second and third form");
        //
        IP++;
    } else if ((msk(bhi,"1001010x")) && (msk(blo,"xxxx0110"))) {     // LSR
        wdebug("LSR");
        IP++;
    } else if (msk(bhi,"001011xx")) {     // MOV
        wdebug("MOV");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        Rr = ss(bhi,6,6) + ss(blo,4,7);
        setregi(Rd,getregi(Rr));
        //no flags
        IP++;
    } else if (bhi == "00000001") {     // MOVW
        wdebug("MOV word");
        // no flags
        IP++;
    } else if (msk(bhi,"001010xx")) {     // OR
        wdebug("OR");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        Rr = ss(bhi,6,6) + ss(blo,4,7);
        opresult = getregi(Rd) | getregi(Rr);
        setregi(Rd,opresult);
        flags("SNZ");
        setflag("V","0");
        IP++;
    } else if (msk(bhi,"0110xxxx")) {     // ORI
        wdebug("ORI");
        Rd = "1" + ss(blo,0,3);
        K = ss(bhi,4,7) + ss(blo,4,7);
        opresult = getregi(Rd) | bin2int(K);
        setregi(Rd,opresult);
        flags("SNZ");
        setflag("V","0");
        IP++;
    } else if (msk(bhi,"10111xxx")) {     // OUT
        wdebug("OUT");
        Rr = ss(bhi,7,7) + ss(blo,0,3);
        K = ss(bhi,5,6) + ss(blo,4,7);
        setmem((bin2int(K)+32),getregi(Rr));
        // no flags
        IP++;
    } else if ((msk(bhi,"1001000x")) && (msk(blo,"xxxx1111"))) {     // POP
        wdebug("POP");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        setregi(Rd,pop(8));
        IP++;
    } else if ((msk(bhi,"1001001x")) && (msk(blo,"xxxx1111"))) {     // PUSH
        wdebug("PUSH");
        Rr = ss(bhi,7,7) + ss(blo,0,3);
        push(getregi(Rr),8);
        IP++;
    } else if (msk(bhi,"1101xxxx")) {     // RCALL
        K = ss(bhi,4,7) + blo;
        wdebug("RCALL to "+K);
        // FIXME: -2k operands!
        IP++;
        push(IP,16);
        IP = (IP + bin2int(K)) & 65535;
    } else if ((bhi == "10010101") && (blo == "00001000")) {     // RET
        wdebug("RET");
        IP = pop(16) & 65535;
    } else if (msk(bhi,"1100xxxx")) {     // RJMP
        wdebug("Relative JMP");
        K = ss(bhi,4,7) + blo;
        // FIXME: -2k operands!
        IP = (IP + 1 + bin2int(K)) & 65535;
    } else if ((msk(bhi,"1001010x")) && (msk(blo,"xxxx0111"))) {     // ROR
        wdebug("ROR");
        Rd = ss(bhi,7,7) + ss(blo,0,3);
        opresult = getregi(Rd);
        if (getflag("C")) opresult = opresult | 256;
        setflag("C",((string)(opresult & 1)));
        opresult = ((opresult >> 1) & 255);
        setregi(Rd,opresult);
        flags("SVNZ");
        IP++;
    } else if (msk(bhi,"000011xx")) {     //
        //sbc
    } else if (msk(bhi,"000011xx")) {     //
        //sbci
    } else if (msk(bhi,"000011xx")) {     //
        //sbiw
    } else if (msk(bhi,"000011xx")) {     //
        //sbrc
    } else if (msk(bhi,"000011xx")) {     //
        //sbrs
    } else if (msk(bhi,"000011xx")) {     //
        //ser
    } else if (msk(bhi,"000011xx")) {     //
        //st
    } else if (msk(bhi,"000011xx")) {     //
        //std
    } else if (msk(bhi,"000011xx")) {     //sts(32)
    } else if (msk(bhi,"000011xx")) {     //sts(16)
    } else if (msk(bhi,"000011xx")) {     //
        //sub
    } else if (msk(bhi,"000011xx")) {     //
        //subi
    } else if (msk(bhi,"000011xx")) {     //
        //swap
    } else if (msk(bhi,"000011xx")) {     //
    } else {
        wdebug("INVALID OPCODE - instruction can't be decoded!!");
    }
    wdebug("Last value of Rd: "+Rd);
    wdebug("Last value of K: "+K);
}

default
{
    state_entry()
    {
        integer i;
        llSetText("",ZERO_VECTOR,0);
        regs = [];
        ioreg = [];
        sram = [];
        for (i=0; i<32; i++) regs += [0];
        for (i=0; i<64/4+1; i++) ioreg += [0];
        for (i=0; i<sram_length/4; i++) sram += [0];
        sreg = "00000000";
        llListen(0,"",llGetOwner(),"");
        sout((string)llGetFreeMemory()+" bytes free.");
        sout("Ready!");
    }
    
    listen(integer ch, string nam, key id, string msg)
    {
        list l = llParseString2List(msg,[" "],[]);
        string vs = llList2String(l,0);
        integer i;
        if (vs == "getregsb") {
            sout("Reg file:");
            vs = "";
            for (i=0; i<32; i++) {
                vs += int2bin(llList2Integer(regs,i))+" | ";
                if ((i > 0) && ((i+1)%4 == 0)) {
                    sout("R"+(string)(i-3)+":\t"+vs);
                    vs = "";
                }
            }
            if (llStringLength(vs) > 1) sout(vs);
        } else if (vs == "trydecode") {
            debug = 1;
            //i = hex2int(llList2String(l,1));
            i = llList2Integer(l,1);
            sout("Trying to decode instruction with integer representation "+(string)i);
            cpu(i);
        } else if (vs == "getflags") {
            sout("Status REG = "+sreg);
        }
    }
}

