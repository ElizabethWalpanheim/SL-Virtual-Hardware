-- PIC10 family nano-emulator
-- (C) Elizabeth Walpanheim, 2013

-- TODO: fix flags settings and RAM i/o

itable = {
{"ADDWF",	"Add W and f",				1,"000111dfffffff","C","DC","Z"},
{"ANDWF",	"AND W with f",				1,"000101dfffffff","Z"},
{"CLRF",	"Clear f",					1,"0000011fffffff","Z"},
{"CLRW",	"Clear W",					1,"0000010xxxxxxx","Z"},
{"COMF",	"Complement f",				1,"001001dfffffff","Z"},
{"DECF",	"Decrement f",				1,"000011dfffffff","Z"},
{"DECFSZ",	"Decrement f, Skip if 0",	6,"001011dfffffff"},
{"INCF",	"Increment f",				1,"001010dfffffff","Z"},
{"INCFSZ",	"Increment f, Skip if 0",	6,"001111dfffffff"},
{"IORWF",	"Inclusive OR W with f",	1,"000100dfffffff","Z"},
{"MOVF",	"Move f",					1,"001000dfffffff","Z"},
{"MOVWF",	"Move W to f",				1,"0000001fffffff"},
{"NOP",		"No Operation",				1,"0000000xx00000"},
{"RLF",		"Rotate Left thr Carry",	1,"001101dfffffff","C"},
{"RRF",		"Rotate Right thr Carry",	1,"001100dfffffff","C"},
{"SUBWF",	"Subtract W from f",		1,"000010dfffffff","C","DC","Z"},
{"SWAPF",	"Swap nibbles in f",		1,"001110dfffffff"},
{"XORWF",	"Exclusive OR W with f",	1,"000110dfffffff","Z"},

{"BCF",		"Bit Clear f",				1,"0100bbbfffffff"},
{"BSF",		"Bit Set f",				1,"0101bbbfffffff"},
{"BTFSC",	"Bit Test f, Skip if Clear",6,"0110bbbfffffff"},
{"BTFSS",	"Bit Test f, Skip if Set",	6,"0111bbbfffffff"},

{"ADDLW",	"Add literal and W",		1,"11111xkkkkkkkk","C","DC","Z"},
{"ANDLW",	"AND literal with W",		1,"111001kkkkkkkk","Z"},
{"CALL",	"Call Subroutine",			2,"100kkkkkkkkkkk"},
{"CLRWDT",	"Clear Watchdog Timer",		1,"00000001100100","TO","PD"},
{"GOTO",	"Go to address",			2,"101kkkkkkkkkkk"},
{"IORLW",	"Inclusive OR ltrl with W",	1,"111000kkkkkkkk","Z"},
{"MOVLW",	"Move literal to W",		1,"1100xxkkkkkkkk"},
{"RETFIE",	"Return from interrupt",	2,"00000000001001"},
{"RETLW",	"Return with literal in W",	2,"1101xxkkkkkkkk"},
{"RETURN",	"Return from Subroutine",	2,"00000000001000"},
{"SLEEP",	"Go into Standby mode",		1,"00000001100011","TO","PD"},
{"SUBLW",	"Subtract W from literal",	1,"11110xkkkkkkkk","C","DC","Z"},
{"XORLW",	"Exclusive OR ltrl with W",	1,"111010kkkkkkkk","Z"}
}

sfrs = {
{"INDF", 0x000},
{"TMR0", 0x001},
{"PCL", 0x002},
{"STATUS", 0x003},
{"FSR", 0x004},
{"PORTA", 0x005},
{"TRISA", 0x006},
{"LATA", 0x007},
{"ANSELA", 0x008},
{"WPUA", 0x009},
{"PCLATH", 0x00A},
{"INTCON", 0x00B},
{"PIR1", 0x00C},
{"PIE1", 0x00D},
{"OPTION_REG", 0x00E},
{"PCON", 0x00F},
{"OSCCON", 0x010},
{"TMR2", 0x011},
{"PR2", 0x012},
{"T2CON", 0x013},
{"PWM1DCL", 0x014},
{"PWM1DCH", 0x015},
{"PWM1CON", 0x016},
{"PWM2DCL", 0x017},
{"PWM2DCH", 0x018},
{"PWM2CON", 0x019},
{"IOCAP", 0x01A},
{"IOCAN", 0x01B},
{"IOCAF", 0x01C},
{"FVRCON", 0x01D},
{"ADRES", 0x01E},
{"ADCON", 0x01F},
{"PMADR", 0x020},
{"PMADRH", 0x021},
{"PMDAT", 0x022},
{"PMDATH", 0x023},
{"PMCON1", 0x024},
{"PMCON2", 0x025},
{"CLKRCON", 0x026},
{"NCO1ACC", 0x027},
{"NCO1ACCH", 0x028},
{"NCO1ACCU", 0x029},
{"NCO1INC", 0x02A},
{"NCO1INCH", 0x02B},
{"NCO1INCU", 0x02C},
{"NCO1CON", 0x02D},
{"NCO1CLK", 0x02E},
{"WDTCON", 0x030},
{"CLC1CON", 0x031},
{"CLC1SEL0", 0x032},
{"CLC1SEL1", 0x033},
{"CLC1POL", 0x034},
{"CLC1GLS0", 0x035},
{"CLC1GLS1", 0x036},
{"CLC1GLS2", 0x037},
{"CLC1GLS3", 0x038},
{"CWG1CON0", 0x039},
{"CWG1CON1", 0x03A},
{"CWG1CON2", 0x03B},
{"CWG1DBR", 0x03C},
{"CWG1DBF", 0x03D},
{"VREGCON", 0x03E},
{"BORCON", 0x03F}}

IP = 0
W = "0"
C = "0"
Z = "0"
DC = "0"
TO = "0"
PD = "0"
RAM = {}
stack = {}
lC = "0"

function modstatus(name,val)
	ss = specreg("STATUS","r","0")
	r = "0"
	if val ~= "?" then
		specreg("STATUS","w",r)
	end
	return r
end

function specreg(name,op,val)
	r = "00000000"
	x = 0xFFF
	for i = 1, #sfrs do
		if name == sfrs[i][1] then
			x = sfrs[i][2]
		end
	end
	if x == 0xFFF then return r
	elseif name == "INDF" then
		aa = modstatus("IRP","?")
	elseif name == "FSR" then
	elseif name == "STATUS" then
	elseif name == "PCL" then
	end
	return r
end

function ramread(adr)
	adr = tonumber(adr,2)
	r = "00000000"
	for i = 1, #sfrs do
		if adr == sfrs[i][2] then
			return specreg(sfrs[i][1],"r","0")
		end
	end
	--TODO
	return r
end

function ramwrite(adr,val)
	adr = tonumber(adr,2)
	r = "00000000"
	for i = 1, #sfrs do
		if adr == sfrs[i][2] then
			return specreg(sfrs[i][1],"w",val)
		end
	end
	--TODO
	return r
end

function ramreadnamed(name)
	return specreg(name,"r","0")
end

function ramwritenamed(name,val)
	return specreg(name,"w",val)
end

function bin8neg(x)
	r = ""
	for i = 1, #x do
		if x:sub(i,i) == "1" then
			r = r.."0"
		else
			r = r.."1"
		end
	end
	return r
end

function bin8swap(x)
	hi = x:sub(1,4)
	lo = x:sub(5,8)
	x = lo..hi
	return x
end

function bin1or(a,b)
	if (a == "1") or (b == "1") then
		return "1"
	else
		return "0"
	end
end

function bin8or(a,b)
	r = ""
	for i = 1, 8 do
		r = r..bin1or(a:sub(i,i),b:sub(i,i))
	end
	return r
end

function bin1and(a,b)
	if (a == "1") and (b == "1") then
		return "1"
	else
		return "0"
	end
end

function bin8and(a,b)
	r = ""
	for i = 1, 8 do
		r = r..bin1and(a:sub(i,i),b:sub(i,i))
	end
	return r
end

function bin1xor(a,b)
	if bin1and(a,b) == "1" then
		return "0"
	else
		return bin1or(a,b)
	end
end

function bin8xor(a,b)
	r = ""
	for i = 1, 8 do
		r = r..bin1xor(a:sub(i,i),b:sub(i,i))
	end
	return r
end

function bin8rotleft(x,carry)
	r = ""
	lC = x:sub(1,1)
	r = x:sub(2,8)..carry
	return r
end

function bin8rotright(x,carry)
	r = ""
	lC = x:sub(8,8)
	r = carry..x:sub(1,7)
	return r
end

function bin82ct(x)
	-- two's complement
	r = ""
	f = 0
	for i = #x, 1, -1 do
		cx = x:sub(i,i)
		if f == 1 then
			if cx == "1" then cx = "0"
			else cx = "1" end
		else
			if cx == "1" then f = 1 end
		end
		r = cx..r
	end
	return r
end

function bin8sum(a,b)
	lC = "0"
	r = ""
	for i = 8, 1, -1 do
		ca = a:sub(i,i)
		cb = b:sub(i,i)
		x = bin1xor(ca,cb)
		y = bin1xor(x,lC)
		lC = bin1or(bin1and(x,lC),bin1and(ca,cb))
		r = y..r
	end
	return r
end

function bin8sub(a,b)
	return bin8sum(a,bin82ct(b))
end

function modbit(val,bit,new)
	b = 8 - tonumber(bit,2)
	r = ""
	if b > 1 then
		r = val:sub(1,b-1)
	end
	r = r..new
	if b < 8 then
		r = r..val:sub(b+1,8)
	end
	return r
end

function stackpush(val)
	local sx = {val}
	for i = 1, stack do
		sx[i+1] = stack[i]
	end
	if #sx > 9 then
		print("Error: stack overflow!")
		pic10dump()
		return stack
	end
	return sx
end

function stackpop()
	if #stack < 1 then
		print("Error: stack underflow!")
		pic10dump()
		return 0
	end
	local sx = {}
	for i = 2, stack do
		sx[i-1] = stack[i]
	end
	val = stack[1]
	stack = {}
	stack = sx
	sx = {}
	return val
end

function getfullIP(low)
	x = ramreadnamed("PCLATH")
	x = tonumber((x:sub(4,5)..low),2)
	return x
end

function pic10dump()
	print("\n------DUMP------")
	sf = string.format
	print(sf("IP = 0x%x (%d)\nW = 0x%x (%d)",IP,IP,W,W))
	print("Flags:\nC\tZ\tDC\tTO PD")
	print(sf("%d\t%d\t%d\t%d  %d",C,Z,DC,TO,PD))
	if #stack > 0 then
		print("Stack:")
		for i = 1, #stack do
			print(sf("%02d: 0x%x (%d)",i,stack[i],stack[i]))
		end
	else
		print("Empty stack")
	end
end

function pic10exec(cmd)
	if (#cmd < 1) or (cmd[1] < 1) or (cmd[1] > 35) then return end
	f = cmd[2]
	k = cmd[3]
	d = cmd[4]
	b = cmd[5]
	tmp = ""
	place = 0
	if cmd[1] == 1 then -- ADDWF
		tmp = bin8sum(W,ramread(f))
		place = 1

	elseif cmd[1] == 2 then -- ANDWF
		tmp = bin8and(W,k)
		place = 1

	elseif cmd[1] == 3 then -- CLRF
		ramwrite(f,0)

	elseif cmd[1] == 4 then -- CLRW
		W = 0

	elseif cmd[1] == 5 then -- COMF
		tmp = bin8neg(ramread(f))
		place = 1

	elseif cmd[1] == 6 then -- DECF
		tmp = bin8sub(ramread(f),"00000001")
		place = 1

	elseif cmd[1] == 7 then -- DECFSZ
		tmp = bin8sub(ramread(f),"00000001")
		place = 1
		if tonumber(tmp,2) == 0 then IP = IP + 1 end

	elseif cmd[1] == 8 then -- INCF
		tmp = bin8sum(ramread(f),"00000001")
		place = 1

	elseif cmd[1] == 9 then -- INCFSZ
		tmp = bin8sum(ramread(f),"00000001")
		place = 1
		if tonumber(tmp,2) == 0 then IP = IP + 1 end

	elseif cmd[1] == 10 then -- IORWF
		tmp = bin8or(W,ramread(f))
		place = 1

	elseif cmd[1] == 11 then -- MOVF
		if tonumber(d) == 0 then W = ramread(f) end

	elseif cmd[1] == 12 then -- MOVWF
		ramwrite(f,W)

	elseif cmd[1] == 13 then -- NOP
		print("NOP")

	elseif cmd[1] == 14 then -- RLF
		tmp = bin8rotleft(ramread(f),C)
		C = tonumber(tmp:sub(1,1))
		place = 1

	elseif cmd[1] == 15 then -- RRF
		tmp = bin8rotright(ramread(f),C)
		C = tonumber(tmp:sub(1,1))
		place = 1

	elseif cmd[1] == 16 then -- SUBWF
		tmp = bin8sub(ramread(f),W)
		place = 1

	elseif cmd[1] == 17 then -- SWAPWF
		tmp = bin8swap(ramread(f))
		place = 1

	elseif cmd[1] == 18 then -- XORWF
		tmp = bin8xor(W,ramread(f))
		place = 1

	elseif cmd[1] == 19 then -- BCF
		ramwrite(f,modbit(ramread(f),b,0))

	elseif cmd[1] == 20 then -- BSF
		ramwrite(f,modbit(ramread(f),b,1))

	elseif cmd[1] == 21 then -- BTFSC
		tmp = ramread(f)
		xx = tonumber(b,2)
		if tmp:sub(xx,xx) == "0" then IP = IP + 1 end

	elseif cmd[1] == 22 then -- BTFSS
		tmp = ramread(f)
		xx = tonumber(b,2)
		if tmp:sub(xx,xx) == "1" then IP = IP + 1 end

	elseif cmd[1] == 23 then -- ADDLW
		W = bin8sum(W,k)

	elseif cmd[1] == 24 then -- ANDLW
		W = bin8and(W,k)

	elseif cmd[1] == 25 then -- CALL
		stackpush(IP+1)
		IP = getfullIP(k)
		return

	elseif cmd[1] == 26 then -- CLRWDT
		print("Clear Watchdog :)")

	elseif cmd[1] == 27 then -- GOTO
		IP = getfullIP(k)
		return

	elseif cmd[1] == 28 then -- IORLW
		W = bin8or(W,k)

	elseif cmd[1] == 29 then -- MOVLW
		W = k

	elseif cmd[1] == 30 then -- RETFIE
		--FIXME: set GIE flag at INTCON<7>
		print("Interrupt return")
		IP = stackpop()
		return

	elseif cmd[1] == 31 then -- RETLW
		W = k
		IP = stackpop()
		return

	elseif cmd[1] == 32 then -- RETURN
		IP = stackpop()
		return

	elseif cmd[1] == 33 then -- SLEEP
		print("We're sleeping now... really?! :)")

	elseif cmd[1] == 34 then -- SUBLW
		W = bin8sub(k,W)

	elseif cmd[1] == 35 then -- XORLW
		W = bin8xor(W,k)

	end
	if place > 0 then
		if d == 0 then W = tmp
		else ramwrite(f,tmp) end
	end
	if (#itable[cmd[1]] > 4) then
		x = itable[cmd[1]][5]
		print("Will аffect flags "..x)
	end
	IP = IP + 1
end

function test()
	for i = 1, #itable do
		s = "Command: "
		for j = 1, #itable[i] do
			if (j == 2) then s = s.."\tDesc: "
			elseif (j == 3) then s = s.."\t\tCyc: "
			elseif (j == 4) then s = s.."\tCode: "
			elseif (j == 5) then s = s.."\tFlags: "
			end
			s = s..itable[i][j]
		end
		print(s)
	end
	for i = 1, #sfrs do
		s = "Register name: "..sfrs[i][1]
		s = string.format("%s\t\tAddr: 0x%x",s,sfrs[i][2])
		print(s)
	end
end

function dectobin(d)
	b = ""
	while d > 0 do
		r = d % 2
		d = math.floor(d / 2)
		b = r..b
	end
	if #b > 14 then
		b = b:sub(1,14)
		print("WARNING: Binary truncated!")
	end
	while #b < 14 do b = "0"..b end
	return b
end

function decode(bin)
	found = {}
	for code = 1, 35 do
		orig = itable[code][4]
		hit = 0
		f = ""
		k = ""
		d = 0
		b = ""
		for i = 1, 14 do
			ss = orig:sub(i,i)
			if (ss == "0") or (ss == "1") then
				if ss ~= bin:sub(i,i) then
					break
				end
			elseif ss ~= "x" then
				if ss == "f" then f = bin:sub(i,i)..f
				elseif ss == "k" then k = bin:sub(i,i)..k
				elseif ss == "d" then d = bin:sub(i,i)
				elseif ss == "b" then b = bin:sub(i,i)..b
				end
			end
			hit = hit + 1
		end
		if (hit == 14) then
			print(itable[code][1].."\t("..itable[code][2]..")")
			print(string.format("f: %s k: %s d: %d b: %s",f,k,d,b))
			found = {code,f,k,d,b}
		end
	end
	return found
end

test()
print("Enter command code in hex")
hx = io.read()
bn = dectobin(tonumber(hx,16))
print(string.format("Binary: %s",bn))
cmd = decode(bn)
pic10exec(cmd)
pic10dump()
