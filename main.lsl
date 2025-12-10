integer gPinkListener = -1;

list gNameReqList      = [];
list gNamePetals       = [];
list gNameIsPublicList = [];

list gDataReqList      = [];
list gTargetKeyList    = [];
list gDataKindList     = [];

list gAvatarKeyList    = [];
list gLegacyNameList   = [];
list gDisplayNameList  = [];
list gBirthdayList     = [];
list gHasNameList      = [];
list gHasBirthdayList  = [];
list gAgentIsPublic    = [];

string trim(string s) {
    integer start = 0;
    integer end = llStringLength(s) - 1;
    while (start <= end && llGetSubString(s, start, start) == " ") start++;
    while (end >= start && llGetSubString(s, end, end) == " ") end--;
    if (end < start) return "";
    return llGetSubString(s, start, end);
}

integer startsWithCI(string hay, string needle) {
    integer n = llStringLength(needle);
    if (llStringLength(hay) < n) return FALSE;
    string a = llToLower(llGetSubString(hay, 0, n - 1));
    string b = llToLower(needle);
    return (a == b);
}

integer isValidKey(string s) {
    key k = (key)s;
    if (k) return TRUE;
    if (s == (string)NULL_KEY) return TRUE;
    return FALSE;
}

integer dateToJDN(integer y, integer m, integer d) {
    integer a = (14 - m) / 12;
    y = y + 4800 - a;
    m = m + 12 * a - 3;
    integer jdn = d + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045;
    return jdn;
}

integer ageInDays(string born) {
    if (born == "") return -1;
    integer by = (integer)llGetSubString(born, 0, 3);
    integer bm = (integer)llGetSubString(born, 5, 6);
    integer bd = (integer)llGetSubString(born, 8, 9);

    string now = llGetTimestamp();
    integer cy = (integer)llGetSubString(now, 0, 3);
    integer cm = (integer)llGetSubString(now, 5, 6);
    integer cd = (integer)llGetSubString(now, 8, 9);

    integer jBorn = dateToJDN(by, bm, bd);
    integer jNow  = dateToJDN(cy, cm, cd);

    return jNow - jBorn;
}

integer ensureAgentIndex(key k) {
    string ks = (string)k;
    integer idx = llListFindList(gAvatarKeyList, [ks]);
    if (idx == -1) {
        gAvatarKeyList    += [ks];
        gLegacyNameList   += [""];
        gDisplayNameList  += [""];
        gBirthdayList     += [""];
        gHasNameList      += [0];
        gHasBirthdayList  += [0];
        gAgentIsPublic    += [0];
        idx = llGetListLength(gAvatarKeyList) - 1;
    }
    return idx;
}

integer clearAgentIndex(integer idx) {
    gAvatarKeyList    = llDeleteSubList(gAvatarKeyList,    idx, idx);
    gLegacyNameList   = llDeleteSubList(gLegacyNameList,   idx, idx);
    gDisplayNameList  = llDeleteSubList(gDisplayNameList,  idx, idx);
    gBirthdayList     = llDeleteSubList(gBirthdayList,     idx, idx);
    gHasNameList      = llDeleteSubList(gHasNameList,      idx, idx);
    gHasBirthdayList  = llDeleteSubList(gHasBirthdayList,  idx, idx);
    gAgentIsPublic    = llDeleteSubList(gAgentIsPublic,    idx, idx);
    return TRUE;
}

integer maybePrintAgentInfo(key targetKey, integer idx) {
    integer gotName = llList2Integer(gHasNameList, idx);
    integer gotBorn = llList2Integer(gHasBirthdayList, idx);
    if (!gotName || !gotBorn) return FALSE;

    string legacy  = llList2String(gLegacyNameList,  idx);
    string display = llList2String(gDisplayNameList, idx);
    string born    = llList2String(gBirthdayList,    idx);

    integer ageDays = ageInDays(born);

    string aboutURI = "secondlife:///app/agent/" + (string)targetKey + "/about";

    string msg = "Avatar:\n";

    if (display != "") {
        msg += "• Display Name: " + display + "\n";
    }

    msg += "• Legacy Name: " + legacy + "\n";

    if (ageDays >= 0) {
        msg += "• Account Age: " + (string)ageDays + " days\n";
    }

    msg += "• UUID: " + (string)targetKey + "\n";
    msg += "• About: " + aboutURI;

    integer isPublic = llList2Integer(gAgentIsPublic, idx);
    if (isPublic) {
        llSay(0, msg);
    } else {
        llOwnerSay(msg);
    }

    clearAgentIndex(idx);
    return TRUE;
}

key requestAgentName(key targetKey, integer isPublic) {
    integer aidx = ensureAgentIndex(targetKey);

    gAgentIsPublic = llListReplaceList(gAgentIsPublic, [isPublic], aidx, aidx);

    key ridName = llRequestAgentData(targetKey, DATA_NAME);
    gDataReqList   += [(string)ridName];
    gTargetKeyList += [(string)targetKey];
    gDataKindList  += ["NAME"];

    key ridBorn = llRequestAgentData(targetKey, DATA_BORN);
    gDataReqList   += [(string)ridBorn];
    gTargetKeyList += [(string)targetKey];
    gDataKindList  += ["BORN"];

    return ridName;
}

key requestUserByName(string rawName, integer isPublic) {
    string name = trim(rawName);
    if (name == "") {
        if (isPublic) {
            llSay(0, "Usage: p lookup name <first> [last]");
        } else {
            llOwnerSay("Usage: lookup name <first> [last]");
        }
        return NULL_KEY;
    }

    if (llSubStringIndex(name, " ") == -1 && llSubStringIndex(name, ".") == -1) {
        name = name + " Resident";
    }

    key rid = llRequestUserKey(name);
    gNameReqList      += [(string)rid];
    gNamePetals       += [name];
    gNameIsPublicList += [isPublic];
    return rid;
}

integer clearState() {
    gNameReqList      = [];
    gNamePetals       = [];
    gNameIsPublicList = [];
    gDataReqList      = [];
    gTargetKeyList    = [];
    gDataKindList     = [];
    gAvatarKeyList    = [];
    gLegacyNameList   = [];
    gDisplayNameList  = [];
    gBirthdayList     = [];
    gHasNameList      = [];
    gHasBirthdayList  = [];
    gAgentIsPublic    = [];

    llOwnerSay("Cleared pending lookups and state.");
    return TRUE;
}

default
{
    state_entry() {
        if (gPinkListener != -1) llListenRemove(gPinkListener);
        gPinkListener = llListen(2, "", llGetOwner(), "");
        llOwnerSay(
            "Hails.AV-resolver Module\n"
            + "Commands: (use /2)\n"
            + "• lookup avatar <uuid>\n"
            + "• lookup name <first> [last]\n"
            + "• p lookup avatar <uuid>\n"
            + "• p lookup name <first> [last]\n"
            + "• hails clear"
        );
    }

    on_rez(integer p) { 
        llResetScript(); 
    }

    listen(integer channel, string name, key id, string message) {
        string msg = trim(message);

        if (startsWithCI(msg, "hails clear")) {
            clearState();
            return;
        }

        if (startsWithCI(msg, "lookup avatar ")) {
            string arg = trim(llGetSubString(msg, 14, -1));
            if (!isValidKey(arg)) {
                llOwnerSay("Invalid UUID.");
                return;
            }
            requestAgentName((key)arg, FALSE);
            return;
        }

        if (startsWithCI(msg, "lookup name ")) {
            string arg = trim(llGetSubString(msg, 12, -1));
            requestUserByName(arg, FALSE);
            return;
        }

        if (startsWithCI(msg, "p lookup avatar ")) {
            string arg = trim(llGetSubString(msg, 16, -1));
            if (!isValidKey(arg)) {
                llSay(0, "Invalid UUID.");
                return;
            }
            requestAgentName((key)arg, TRUE);
            return;
        }

        if (startsWithCI(msg, "p lookup name ")) {
            string arg = trim(llGetSubString(msg, 14, -1));
            requestUserByName(arg, TRUE);
            return;
        }
    }

    dataserver(key request_id, string data) {
        integer ridx = llListFindList(gDataReqList, [(string)request_id]);
        if (ridx != -1) {
            key targetKey = (key)llList2String(gTargetKeyList, ridx);
            string rType  = llList2String(gDataKindList, ridx);

            gDataReqList   = llDeleteSubList(gDataReqList,   ridx, ridx);
            gTargetKeyList = llDeleteSubList(gTargetKeyList, ridx, ridx);
            gDataKindList  = llDeleteSubList(gDataKindList,  ridx, ridx);

            integer aidx = ensureAgentIndex(targetKey);

            if (rType == "NAME" && data != "") {
                gLegacyNameList  = llListReplaceList(gLegacyNameList,  [data], aidx, aidx);
                gDisplayNameList = llListReplaceList(gDisplayNameList, [llGetDisplayName(targetKey)], aidx, aidx);
                gHasNameList     = llListReplaceList(gHasNameList,     [1], aidx, aidx);
            }
            else if (rType == "BORN" && data != "") {
                gBirthdayList    = llListReplaceList(gBirthdayList,    [data], aidx, aidx);
                gHasBirthdayList = llListReplaceList(gHasBirthdayList, [1], aidx, aidx);
            }

            maybePrintAgentInfo(targetKey, aidx);
            return;
        }

        integer nidx = llListFindList(gNameReqList, [(string)request_id]);
        if (nidx != -1) {
            string lookedUpName = llList2String(gNamePetals, nidx);
            integer isPublic    = llList2Integer(gNameIsPublicList, nidx);

            gNameReqList      = llDeleteSubList(gNameReqList,      nidx, nidx);
            gNamePetals       = llDeleteSubList(gNamePetals,       nidx, nidx);
            gNameIsPublicList = llDeleteSubList(gNameIsPublicList, nidx, nidx);

            key foundKey = (key)data;
            if (foundKey) {
                requestAgentName(foundKey, isPublic);
            } else {
                if (isPublic) {
                    llSay(0, "No user found for name: " + lookedUpName);
                } else {
                    llOwnerSay("No user found for name: " + lookedUpName);
                }
            }
            return;
        }
    }
}
