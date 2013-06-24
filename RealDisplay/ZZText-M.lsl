/*
 ZZText (5 Face, Multi Texture)

 Originally Written by Xylor Baysklef

 Modified by Thraxis Epsilon January 20, 2006
 Added Support for 5 Face Prim, based on modification
 of XyText v1.1.1 by Kermitt Quick for Single Texture.

 Modified by Salahzar Stenvaag for International and new textures
 produced with GIMP. See wiki page ZZText for further info
 Obtain ME (starting linking channel from Object name)
 thane can use all the other commands
 IDEAL for linked structures

 Modified by Elizabeth Walpanheim, 2012-2013
 for a faster parallel loading methods.
*/
 
// XyText Message Map.
integer DISPLAY_STRING      = 0;
integer DISPLAY_EXTENDED    = 1000;
integer REMAP_INDICES       = 2000;
integer RESET_INDICES       = 3000;
integer SET_CELL_INFO       = 4000;
integer SET_THICKNESS       = 6000;
integer SET_COLOR           = 7000;
 
// This is an extended character escape sequence.
string  ESCAPE_SEQUENCE = "\\e";
 
// This is used to get an index for the extended character.
string  EXTENDED_INDEX  = "123456789abcdef";
 
// Face numbers.
integer FACE_1          = 3;
integer FACE_2          = 7;
integer FACE_3          = 4;
integer FACE_4          = 6;
integer FACE_5          = 1;
 
// to handle special characters from CP850 page for european countries
list decode = [];
 
// Used to hide the text after a fade-out.
key     TRANSPARENT     = "701917a8-d614-471f-13dd-5f4644e36e3c";
 
// This is a list of textures for all 2-character combinations.
list    CHARACTER_GRID  = [
    "96f4578b-879e-44ae-d223-427cc615f5a4", // my slice-0-0
    "eab5360f-6653-593f-b679-69c68b0dd001", // 1-0
    "367330be-717a-277d-5205-131cd6ded458", // 1-1
    "32046675-6e7e-2425-ce77-69000b0b4d96", // 2-0
    "40085901-bde6-2dd4-40cd-b6d48d242997", // 2-1
    "205d318b-09b7-7ecc-922e-801c93a546c8", // 2-2
    "841e7826-3645-d4f0-d48b-389586dd8e90", // 3-0
    "e2db78c5-fb47-d767-4744-8cb6d84610d0", // 3-1
    "15312c89-afd4-854c-9d9b-5b9e11844aed", // 3-2
    "d180e771-0393-d09b-8cac-0af6d550ae4a", // 3-3
    "c6c1d2c8-5dfd-b13a-7f1e-c3ede8126769", // 4-0
    "bc100d0c-a445-947f-caa4-285d9cc8a9de", // 4-1
    "0b31e862-75a4-9ed3-6331-e9e700a0fedb", // 4-2
    "0eacc306-6bd5-ab31-de47-c686141a6733", // 4-3
    "b68de1d9-4890-74a0-4d25-d4d5c83a0dba", // 4-4
    "04b2bf9b-a8bb-0a39-1062-9b005229eba9", // 5-0
    "be293f10-25ec-beb9-738b-fe1892b82aef", // 5-1
    "5e9c8317-71f5-f073-76ab-7c412d3acb84", // 5-2
    "030b441b-9022-2aba-f7a7-af6810c354b8", // 5-3
    "9f455858-8ae6-3a9a-c2d4-bc5ee92430ac", // 5-4
    "ee741143-f01e-f730-667e-66a3cd57d1cc", // 5-5
    "710282bc-bd80-5a44-6987-0c4c11a4c294", // 6-0
    "c9c410db-675a-1e98-4107-debd3c73a754", // 6-1
    "486c2336-71c5-b962-266c-838a865c067c", // 6-2
    "d4722155-0b6d-3673-0208-a727729bc117", // 6-3
    "bc7af3cd-ee48-08df-fe8b-a6ca8a425733", // 6-4
    "f23d7a73-00c3-1ffd-69a7-0cca031c939d", // 6-5
    "aa95bfd1-ac80-f962-7acf-d6aeed9c7e81", // 6-6
    "53fd52e3-0e8b-dcc8-42f8-332aef421bd2", // 7-0
    "da3f6f09-3e3a-e156-8e2e-1040111a5635", // 7-1
    "409a95c0-b685-2036-d0de-75e8ab654243", // 7-2
    "14e05aca-3a61-b892-3632-dcde72324779", // 7-3
    "546c0e4f-b678-895d-2035-0f39bb7f4979", // 7-4
    "cf2fc337-109f-ba25-8ff5-786f7d6ceb5b", // 7-5
    "9943204b-a4de-868a-3cdd-8785d1864ede", // 7-6
    "765cfd9c-9703-b5ba-2c5d-f1c8bd44e0f4"  // 7-7
        ];
 
integer ME;
 
// All displayable characters.  Default to ASCII order.
string gCharIndex;
 
// This is the channel to listen on while acting
// as a cell in a larger display.
integer gCellChannel      = -1;
 
// This is the starting character position in the cell channel message
// to render.
integer gCellCharPosition = 0;
 
// This is whether or not to use the fade in/out special effect.
integer gCellUseFading      = FALSE;
 
// This is how long to display the text before fading out (if using
// fading special effect).
// Note: < 0  means don't fade out.
float   gCellHoldDelay      = 1.0;
 
ResetCharIndex()
{
    gCharIndex  = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`";
    // \" <-- Fixes LSL syntax highlighting bug.
    gCharIndex += "abcdefghijklmnopqrstuvwxyz{|}~";
    //        cap cedille      u:         e/            a^         a:          a/         a ring      cedille     e^           e:
    decode=  ["%C3%87", "%C3%BC", "%C3%A9", "%C3%A2", "%C3%A4", "%C3%A0", "%C3%A5", "%C3%A7", "%C3%AA", "%C3%AB",
 
 
        //                    e\           i:               i^            i\                A:          A ring          E/              ae           AE           marker >
        "%C3%A8", "%C3%AF", "%C3%AE", "%C3%AC", "%C3%84", "%C3%85", "%C3%89", "%C3%A6", "%C3%86", "%E2%96%B6" ,
 
        //                 o:               o/           u^          u\              y:               O:             U:          cent           pound        yen
        "%C3%B6", "%C3%B2", "%C3%BB", "%C3%B9", "%C3%BF", "%C3%96", "%C3%9C", "%C2%A2", "%C2%A3", "%C2%A5",
 
        //                 A^              a/              i/                o/            u/              n~           E:            y/              inv ?         O^
        "%C3%82", "%C3%A1", "%C3%AD", "%C3%B3", "%C3%BA", "%C3%B1", "%C3%8B", "%C3%BD", "%C2%BF", "%C3%94",
 
        //                   inv !             I\             I/           degree       E^              I^            o^            U^
        "%C2%A1", "%C3%8C", "%C3%8D", "%C2%B0", "%C3%8A", "%C3%8E", "%C3%B4", "%C3%9B",
 
        //                     Y:          euro           german ss         E\              A\           A/              U\           U/               O\           O/
        "%C3%9D", "%E2%82%AC", "%C3%9F", "%C3%88", "%C3%80", "%C3%81", "%C3%99", "%C3%9A", "%C3%92", "%C3%93",
 
        //                   Sv           sv             zv             Zv              Y:             I:
        "%C5%A0", "%C5%A1", "%C5%BE", "%C5%BD", "%C3%9D", "%C3%8C" ];
}
 
vector GetGridPos(integer index1, integer index2)
{
    // There are two ways to use the lookup table...
    integer Col;
    integer Row;
    if (index1 >= index2)
    {
        // In this case, the row is the index of the first character:
        Row = index1;
        // And the col is the index of the second character (x2)
        Col = index2 * 2;
    }
    // Index1 < Index2
    else
    {
        // In this case, the row is the index of the second character:
        Row = index2;
        // And the col is the index of the first character, x2, offset by 1.
        Col = index1 * 2 + 1;
    }
 
    return <Col, Row, 0>;
}
 
string GetGridTexture(vector grid_pos)
{
    // Calculate the texture in the grid to use.
    integer GridCol = llRound(grid_pos.x) / 40; // PK was 20
    integer GridRow = llRound(grid_pos.y) / 20; // PK was 10
 
    // Lookup the texture.
    key Texture = llList2Key(CHARACTER_GRID, GridRow * (GridRow + 1) / 2 + GridCol);
    return Texture;
}
 
vector GetGridOffset(vector grid_pos)
{
    // Zoom in on the texture showing our character pair.
    integer Col = llRound(grid_pos.x) % 40; // PK was 20
    integer Row = llRound(grid_pos.y) % 20; // PK was 10
 
    // Return the offset in the texture.
    return <-0.45 + 0.025 * Col, 0.45 - 0.05 * Row, 0.0>; // PK was 0.05 and 0.1
}
 
ShowChars(vector grid_pos1, vector grid_pos2, vector grid_pos3, vector grid_pos4, vector grid_pos5)
{
    // Set the primitive textures directly.
 
 
    llSetLinkPrimitiveParamsFast(LINK_THIS, [
        PRIM_TEXTURE, FACE_1, GetGridTexture(grid_pos1), <0.125, 0.05, 0>, GetGridOffset(grid_pos1) + <0.0375-0.025-0.002, 0.025, 0>, 0.0,
        PRIM_TEXTURE, FACE_2, GetGridTexture(grid_pos2), <0.05, 0.05, 0>, GetGridOffset(grid_pos2)+<-0.025-0.002, 0.025,0>, 0.0,
        PRIM_TEXTURE, FACE_3, GetGridTexture(grid_pos3), <-0.74, 0.05, 0>, GetGridOffset(grid_pos3)+ <-.34-0.002, 0.025, 0>, 0.0,
        PRIM_TEXTURE, FACE_4, GetGridTexture(grid_pos4), <0.05, 0.05, 0>, GetGridOffset(grid_pos4)+<-0.025-0.002, 0.025,0>, 0.0,
        PRIM_TEXTURE, FACE_5, GetGridTexture(grid_pos5), <0.125, 0.05, 0>, GetGridOffset(grid_pos5) + <0.0375-0.025-0.077-0.002, 0.025, 0>, 0.0
//      PRIM_TEXTURE, FACE_1, GetGridTexture(grid_pos1), <0.25, 0.1, 0>, GetGridOffset(grid_pos1) + <0.075, 0, 0>, 0.0,
//      PRIM_TEXTURE, FACE_2, GetGridTexture(grid_pos2), <0.1, 0.1, 0>, GetGridOffset(grid_pos2), 0.0,
//      PRIM_TEXTURE, FACE_3, GetGridTexture(grid_pos3), <-1.48, 0.1, 0>, GetGridOffset(grid_pos3)+ <0.37, 0, 0>, 0.0,
//      PRIM_TEXTURE, FACE_4, GetGridTexture(grid_pos4), <0.1, 0.1, 0>, GetGridOffset(grid_pos4), 0.0,
//  PRIM_TEXTURE, FACE_5, GetGridTexture(grid_pos5), <0.25, 0.1, 0>, GetGridOffset(grid_pos5) - <0.075, 0, 0>, 0.0
            ]);
}
 
integer GetIndex(string char)
{
    integer ret = llSubStringIndex(gCharIndex, char);
 
    if(0 <= ret)
        return ret;
 
    // special char do nice trick :)
    string escaped = llEscapeURL(char);
 
    // remap ’
    if(escaped == "%E2%80%99")
        return 7;
 
    //llSay(PUBLIC_CHANNEL, "Looking for " + escaped);
    integer found = llListFindList(decode, [escaped]);
 
    // not found
    if(found < 0)
        return FALSE;
 
    // return correct index
    return llStringLength(gCharIndex) + found;
 
}
 
RenderString(string str)
{
    // Get the grid positions for each pair of characters.
    vector GridPos1 = GetGridPos( GetIndex(llGetSubString(str, 0, 0)),
        GetIndex(llGetSubString(str, 1, 1)) );
    vector GridPos2 = GetGridPos( GetIndex(llGetSubString(str, 2, 2)),
        GetIndex(llGetSubString(str, 3, 3)) );
    vector GridPos3 = GetGridPos( GetIndex(llGetSubString(str, 4, 4)),
        GetIndex(llGetSubString(str, 5, 5)) );
    vector GridPos4 = GetGridPos( GetIndex(llGetSubString(str, 6, 6)),
        GetIndex(llGetSubString(str, 7, 7)) );
    vector GridPos5 = GetGridPos( GetIndex(llGetSubString(str, 8, 8)),
        GetIndex(llGetSubString(str, 9, 9)) );
 
    // Use these grid positions to display the correct textures/offsets.
    ShowChars(GridPos1, GridPos2, GridPos3, GridPos4, GridPos5);
}
 
RenderWithEffects(string str)
{
    // Get the grid positions for each pair of characters.
    vector GridPos1 = GetGridPos( llSubStringIndex(gCharIndex, llGetSubString(str, 0, 0)),
        llSubStringIndex(gCharIndex, llGetSubString(str, 1, 1)) );
    vector GridPos2 = GetGridPos( llSubStringIndex(gCharIndex, llGetSubString(str, 2, 2)),
        llSubStringIndex(gCharIndex, llGetSubString(str, 3, 3)) );
    vector GridPos3 = GetGridPos( llSubStringIndex(gCharIndex, llGetSubString(str, 4, 4)),
        llSubStringIndex(gCharIndex, llGetSubString(str, 5, 5)) );
    vector GridPos4 = GetGridPos( llSubStringIndex(gCharIndex, llGetSubString(str, 6, 6)),
        llSubStringIndex(gCharIndex, llGetSubString(str, 7, 7)) );
    vector GridPos5 = GetGridPos( llSubStringIndex(gCharIndex, llGetSubString(str, 8, 8)),
        llSubStringIndex(gCharIndex, llGetSubString(str, 9, 9)) );
 
    // First set the alpha to the lowest possible.
    llSetAlpha(0.05, ALL_SIDES);
 
    // Use these grid positions to display the correct textures/offsets.
    ShowChars(GridPos1, GridPos2, GridPos3, GridPos4, GridPos5);
 
    float Alpha;
    for (Alpha = 0.10; Alpha <= 1.0; Alpha += 0.05)
        llSetAlpha(Alpha, ALL_SIDES);
 
    // See if we want to fade out as well.
    if (gCellHoldDelay < 0.0)
        // No, bail out. (Just keep showing the string at full strength).
        return;
 
    // Hold the text for a while.
    llSleep(gCellHoldDelay);
 
    // Now fade out.
    for (Alpha = 0.95; Alpha >= 0.05; Alpha -= 0.05)
        llSetAlpha(Alpha, ALL_SIDES);
 
    // Make the text transparent to fully hide it.
    llSetTexture(TRANSPARENT, ALL_SIDES);
}
 
RenderExtended(string str)
{
    // Look for escape sequences.
    list Parsed       = llParseString2List(str, [], [ESCAPE_SEQUENCE]);
    integer ParsedLen = llGetListLength(Parsed);
 
    // Create a list of index values to work with.
    list Indices;
    // We start with room for 6 indices.
    integer IndicesLeft = 10;
 
    integer i;
    string Token;
    integer Clipped;
    integer LastWasEscapeSequence = FALSE;
    // Work from left to right.
    for (i = 0; i < ParsedLen && IndicesLeft > 0; i++)
    {
        Token = llList2String(Parsed, i);
 
        // If this is an escape sequence, just set the flag and move on.
        if (Token == ESCAPE_SEQUENCE)
        {
            LastWasEscapeSequence = TRUE;
        }
        // Token != ESCAPE_SEQUENCE
        else
        {
            // Otherwise this is a normal token.  Check its length.
            Clipped = FALSE;
            integer TokenLength = llStringLength(Token);
 
            // Clip if necessary.
            if (TokenLength > IndicesLeft)
            {
                Token = llGetSubString(Token, 0, IndicesLeft - 1);
                TokenLength = llStringLength(Token);
                IndicesLeft = 0;
                Clipped = TRUE;
            }
            else
                IndicesLeft -= TokenLength;
 
            // Was the previous token an escape sequence?
            if (LastWasEscapeSequence)
            {
                // Yes, the first character is an escape character, the rest are normal.
 
                // This is the extended character.
                Indices += [llSubStringIndex(EXTENDED_INDEX, llGetSubString(Token, 0, 0)) + 95];
 
                // These are the normal characters.
                integer j;
                for (j = 1; j < TokenLength; j++)
                    Indices += [llSubStringIndex(gCharIndex, llGetSubString(Token, j, j))];
            }
            // Normal string.
            else
            {
                // Just add the characters normally.
                integer j;
                for (j = 0; j < TokenLength; j++)
                    Indices += [llSubStringIndex(gCharIndex, llGetSubString(Token, j, j))];
            }
 
            // Unset this flag, since this was not an escape sequence.
            LastWasEscapeSequence = FALSE;
        }
    }
 
    // Use the indices to create grid positions.
    vector GridPos1 = GetGridPos( llList2Integer(Indices, 0), llList2Integer(Indices, 1) );
    vector GridPos2 = GetGridPos( llList2Integer(Indices, 2), llList2Integer(Indices, 3) );
    vector GridPos3 = GetGridPos( llList2Integer(Indices, 4), llList2Integer(Indices, 5) );
    vector GridPos4 = GetGridPos( llList2Integer(Indices, 6), llList2Integer(Indices, 7) );
    vector GridPos5 = GetGridPos( llList2Integer(Indices, 8), llList2Integer(Indices, 9) );
 
    // Use these grid positions to display the correct textures/offsets.
    ShowChars(GridPos1, GridPos2, GridPos3, GridPos4, GridPos5);
}
 
integer ConvertIndex(integer index)
{
    // This converts from an ASCII based index to our indexing scheme.
    // ' ' or higher
    if (index >= 32)
        index -= 32;
    // index < 32
    else
    {
        // Quick bounds check.
        if (index > 15)
            index = 15;
 
        index += 94; // extended characters
    }
 
    return index;
}
 
default
{
    state_entry()
    {
        // Initialize the character index.
        ResetCharIndex();
        ME=(integer)llGetObjectName();
        //llOwnerSay("Channel:"+(string)ME);
        //llSay(0, "Free Memory: " + (string) llGetFreeMemory());
    }
 
    link_message(integer sender, integer channel, string data, key id)
    {
        if (channel == -601) {
            if (data == "!REMOVE!") {
                llRemoveInventory(llGetScriptName());
            } else if (data == "solid") {
                llSetTexture("5748decc-f629-461c-9a36-a35a221fe21f",ALL_SIDES); //default blank
            } else if (data == "clear") {
                llSetTexture("8dcd4a48-2d37-4909-9f78-f7a9eb4ef903",ALL_SIDES); //default transparent
            } else if (data == "RESET") {
                llResetScript();
            } else if (llGetSubString(data,0,4) == "color") {
                llSetColor((vector)llGetSubString(data,5,-1),ALL_SIDES);
            }
        }
        if (channel == (ME+DISPLAY_STRING))
        {
            RenderString(data);
            return;
        }
        if (channel == (ME+DISPLAY_EXTENDED))
        {
            RenderExtended(data);
            return;
        }
        if (channel == gCellChannel)
        {
            // Extract the characters we are interested in, and use those to render.
            string TextToRender = llGetSubString(data, gCellCharPosition, gCellCharPosition + 9);
            if (gCellUseFading)
                RenderWithEffects( TextToRender );
            else // !gCellUseFading
                RenderString( TextToRender );
            return;
        }
        if (channel == (ME+REMAP_INDICES))
        {
            // Parse the message, splitting it up into index values.
            list Parsed = llCSV2List(data);
            integer i;
            // Go through the list and swap each pair of indices.
            for (i = 0; i < llGetListLength(Parsed); i += 2)
            {
                integer Index1 = ConvertIndex( llList2Integer(Parsed, i) );
                integer Index2 = ConvertIndex( llList2Integer(Parsed, i + 1) );
 
                // Swap these index values.
                string Value1 = llGetSubString(gCharIndex, Index1, Index1);
                string Value2 = llGetSubString(gCharIndex, Index2, Index2);
 
                gCharIndex = llDeleteSubString(gCharIndex, Index1, Index1);
                gCharIndex = llInsertString(gCharIndex, Index1, Value2);
 
                gCharIndex = llDeleteSubString(gCharIndex, Index2, Index2);
                gCharIndex = llInsertString(gCharIndex, Index2, Value1);
            }
            return;
        }
        if (channel == (ME+RESET_INDICES))
        {
            // Restore the character index back to default settings.
            ResetCharIndex();
            return;
        }
        if (channel == (ME+SET_CELL_INFO))
        {
            // Change the channel we listen to for cell commands, and the
            // starting character position to extract from.
            list Parsed = llCSV2List(data);
            gCellChannel        = (integer) llList2String(Parsed, 0);
            gCellCharPosition   = (integer) llList2String(Parsed, 1);
            gCellUseFading      = (integer) llList2String(Parsed, 2);
            gCellHoldDelay      = (float)   llList2String(Parsed, 3);
            return;
        }
        if (channel == (ME+SET_THICKNESS))
        {
            // Set our z scale to thickness, while staying fixed
            // in position relative the prim below us.
            vector Scale    = llGetScale();
            float Thickness = (float) data;
            // Reposition only if this isn't the root prim.
            integer ThisLink = llGetLinkNumber();
            if (ThisLink != 0 || ThisLink != 1)
            {
                // This is not the root prim.
                vector Up = llRot2Up(llGetLocalRot());
                float DistanceToMove = Thickness / 2.0 - Scale.z / 2.0;
                vector Pos = llGetLocalPos();
                llSetPos(Pos + DistanceToMove * Up);
            }
            // Apply the new thickness.
            Scale.z = Thickness;
            llSetScale(Scale);
            return;
        }
        if (channel == (ME+SET_COLOR))
        {
            vector newColor = (vector)data;
            llSetColor(newColor, ALL_SIDES);
        }
    }
}

