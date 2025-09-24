import re, json, copy, os, fileinput
from collections import OrderedDict

re_kirannumber = re.compile('[૦૧૨૩૪૫૬૭૮૯૦૧ર૩૪પ૬૭૮૯]+\\.')
re_continuation = re.compile('[ે્ંિીુૂાૈોી]+')

file_content_template = {
    "main": {
        "place": "પીપલાણા",
        "number": "",
        "title": "",
        "content": "",
        "footer": "",
        "slok_count" : 0,
        "paragraph_count" : 0,
        "word_count" : 0
    },
    "meta": {
        "history": "",
        "moral": ""
    }
}

kiran_list_template = {
    "name" : "",
    "part" : "",
    "list" : []
}

kiran_entry_template = {
    "index" : 0,
    "number": "",
    "title": "",
    "word_count" : 0
}

meaning_list = {
    "list": []
}

meaning_item_template = {
    "word": "",
    "meaning": "",
    "count": 0,
    "index": 0,
    "kirans" : []
}

errors = []

def ExtractKirans(book, inputfile, location, directory, range, fileErrorLog, bFormat):
    totalWordCount = 0
    input = open(inputfile, "r", encoding='utf-8')
    if os.path.exists(location + directory)==False:
        os.mkdir(location + directory)
    nIndex = -1
    file_content = []
    for line in input:
        if len(line.strip()) != 0:
            m = re_kirannumber.match(line)
            if m!=None:
                nIndex += 1
                file_content.append(copy.deepcopy(file_content_template))

                number = m.group()
                title = line.replace(m.group(),"").strip()
                footer = "।। ઇતિ શ્રી કિરણ " + number.replace('.','') + " ।।"

                file_content[nIndex]["main"]["number"] = number
                file_content[nIndex]["main"]["title"] = title
                file_content[nIndex]["main"]["footer"] = footer

            elif nIndex!=-1:
                file_content[nIndex]["main"]["content"] += line

    if file_content.__len__() != range.__len__():
        print("Error: " + directory + " Parsed :" + str(file_content.__len__()) + " Actual :" + str(range.__len__()))
        for con in file_content:
            print(con["main"]["number"] + " : " + con["main"]["title"])
        return False
    
    kiran_list = copy.deepcopy(kiran_list_template)
    kiran_list["name"] = book
    kiran_list["part"] = directory

    nIndex = 0
    for kiran in range:
        kiranname = "kiran_" + str(kiran) + ".json"
        output = open(location + directory + "/" + kiranname, 'w', encoding='utf-8')
        footer = file_content[nIndex]["main"]["footer"]
        content = file_content[nIndex]["main"]["content"]

        slokCount, paraCount, wordCount = ExtractCountDetails(content)
        _, _, title_spaceCount = ExtractCountDetails(file_content[nIndex]["main"]["title"])
        #print(f"{kiranname} has {slokCount} sloks, {paraCount} paragraphs and {wordCount} words.")
        # adding header and footer words as well.
        wordCount = wordCount + title_spaceCount + 1 + 10

        file_content[nIndex]["main"]["slok_count"] = slokCount
        file_content[nIndex]["main"]["paragraph_count"] = paraCount
        file_content[nIndex]["main"]["word_count"] = wordCount

        #Disabling for flutter app
        content = content.replace("\t<slok>", "<slok>").replace("</slok>\n", "</slok>")
        content = content.replace("\t", "<p>&nbsp; &nbsp;").replace("\n", "</p>")
        
        content = content.strip().replace(footer, "", 1)
        anchor_tags = []
        anchortag_template = { "b":0, "e":0, "word":"" }
        for meaning in meaning_list["list"]:
            pos = 0
            tempcontent = content
            mainpos = 0
            count = 0
            while pos < len(tempcontent):
                tempcontent = tempcontent[pos:]
                pos = tempcontent.find(meaning["word"])
                if pos != -1:
                    if IsWithinActorTag(mainpos + pos, anchor_tags) == True:
                        pos = pos + 1
                        mainpos += pos
                    else:
                        previousOne = tempcontent[pos-1:pos]
                        previousTwo = tempcontent[pos-2:pos-1]
                        endtag = tempcontent[pos + len(meaning["word"]): pos + len(meaning["word"]) + 4]
                        if previousOne.strip() == ":" or previousOne.strip() == ">":
                            pos = pos + len(meaning["word"]) + 1
                            mainpos += pos
                        elif previousTwo.strip() == ":" or previousTwo.strip() == ">":
                            pos = pos + len(meaning["word"]) + 1
                            mainpos += pos
                        elif endtag == "</a>":
                            pos = pos + len(meaning["word"]) + 1
                            mainpos += pos
                        else:
                            found = re.search(re_continuation, tempcontent[pos + len(meaning["word"]):])
                            if found != None:
                                if int(found.span()[0]) == 0:
                                    fileErrorLog.write("kiran : " + str(kiran) + " :: " + meaning["word"] + " != "+ tempcontent[pos:pos + len(meaning["word"]) + 1] + "\n")
                                    pos = pos + len(meaning["word"]) + 1
                                    mainpos = pos
                                    continue
                                elif int(count) == 0:
                                    count = 1
                                    meaning["count"] += 1
                                    anchor_tag = copy.deepcopy(anchortag_template)
                                    anchor_tag["b"] = mainpos + pos
                                    anchor_tag["word"] = meaning["word"]
                                    replacement = "<a href=\"dict:"+meaning["word"]+"\">" + meaning["word"] + "</a>"
                                    anchor_tag["e"] = mainpos + pos + len(meaning["word"])
                                    pos = pos + len(meaning["word"]) + int(found.span()[0])
                                    mainpos += pos
                                    anchor_tags.append(anchor_tag)
                                    meaning["kirans"].append(kiran)
                                    break
                            break
                else:
                    break
        sorted_anchor_tags = sorted(anchor_tags, key=lambda k: k["b"], reverse=True)
        for tag in sorted_anchor_tags:
            replacement = "<a href=\"dict:"+tag["word"]+"\">" + tag["word"] + "</a>"
            content = content[0:tag["b"]] + content[tag["b"]:].replace(tag["word"], replacement, 1)

        file_content[nIndex]["main"]["content"] = content
        if bFormat == True:
            json.dump(file_content[nIndex], output, ensure_ascii=False, sort_keys=True, indent=4)
        else:
            json.dump(file_content[nIndex], output, ensure_ascii=False, sort_keys=True)
        output.close()

        '''
        htmlkiranname = "kiran_" + str(kiran) + ".html"
        output = open(location + directory + "/" + htmlkiranname, 'w', encoding='utf-8')
        output.write("<html><style>a { font-weight:bold; text-decoration:none; }</style><body style='text-align:justify;color:#743c0a;font-size:20px'>" + content + "</body></html>")
        output.close()
        '''

        kiran_entry = copy.deepcopy(kiran_entry_template)
        kiran_entry["index"] = kiran
        kiran_entry["number"] = file_content[nIndex]["main"]["number"]
        kiran_entry["title"] = file_content[nIndex]["main"]["title"]
        kiran_entry["word_count"] = wordCount
        kiran_list["list"].append(kiran_entry)

        nIndex += 1

        totalWordCount += wordCount

    input.close()

    kiran_list_file = open(location + directory + "/_kirans_.json", 'w', encoding='utf-8')
    if bFormat == True:
        json.dump(kiran_list, kiran_list_file, ensure_ascii=False, sort_keys=True, indent=4)
    else:
        json.dump(kiran_list, kiran_list_file, ensure_ascii=False, sort_keys=True)
    kiran_list_file.close()

    print("Successful parsing : " + inputfile)

    return True, totalWordCount

def ExtractCountDetails(content) :
    contentTemp = content
    # slok count
    search = '<slok>'
    slokCount = contentTemp.count(search)
    contentTemp = contentTemp.replace("\t<slok>", "").replace("</slok>\n", "")
    # paragraph count
    search = '\t'
    paraCount = contentTemp.count(search)
    contentTemp = contentTemp.replace("\t", "").replace("\n", "")

    # word count
    search = ' '
    spaceCount = contentTemp.count(search)

    return slokCount, paraCount, spaceCount

tabs = re.compile('\t+')
def ExtractMeanings(inputfile):
    meaning_list["list"].clear()
    input = open("meanings.txt", 'r', encoding='utf-8')

    nIndex = 1
    for line in input:
        if line.strip() != None:
            pair = re.split(tabs, line, 2)
            meaning = copy.deepcopy(meaning_item_template)
            meaning["index"] = nIndex
            meaning["word"] = pair[0]
            meaning["meaning"] = pair[1].strip()
            meaning_list["list"].append(meaning)
            nIndex += 1

    print("Successful parsing : " + inputfile)
    return

Input = [["ભાગ-૧", "part1.txt", "part1", range(1, 171)],
         ["ભાગ-૨", "part2.txt", "part2", range(171, 363)],
         ["ભાગ-૩", "part3.txt", "part3", range(363, 502)],
         ["ભાગ-૪", "part4.txt", "part4", range(502, 601)],
         ["ભાગ-૫", "part5.txt", "part5", range(601, 698)]]

def IsWithinActorTag(pos, anchor_tags):
    for anchor_tag in anchor_tags:
        if pos >= anchor_tag["b"] and pos <= anchor_tag["e"]:
            return True
    return False

def ExtractAllKirans(location, fileErrorLog, bFormat):
    for entry in Input:
        ret, nTotalWordCount = ExtractKirans(entry[0], entry[1], location, entry[2], entry[3], fileErrorLog, bFormat)
        print(f"{entry[0]} has {nTotalWordCount} words.")
        if ret == False:
            print("Error Parsing!")
            break
    return

def SaveMeanings(location, outputfile, bFormat):
    if os.path.exists(location + "meanings")==False:
        os.mkdir(location + "meanings")
    output = open(location + "/meanings/" + outputfile, 'w', encoding='utf-8')
    if bFormat == True:
        json.dump(meaning_list, output, ensure_ascii=False, sort_keys=True, indent=4)
    else:
        json.dump(meaning_list, output, ensure_ascii=False, sort_keys=True)
    output.close()

def SaveAll(location, bFormat):
    print("Location : " + location)
    if os.path.exists(location)==False:
        os.mkdir(location)
    fileErrorLog = open(location + "errors.txt", 'w', encoding='utf-8')
    ExtractMeanings("meanings.txt")
    ExtractAllKirans(location, fileErrorLog, bFormat)
    SaveMeanings(location, "meanings.json", bFormat)
    fileErrorLog.close()

def VerifyPart(location, part, range):
    for kiran in range:
        file = open(location + "/" + part + "/kiran_" + str(kiran) + ".json", 'r', encoding='utf-8')
        nStartP = 0
        nEndP = 0
        for line in file:
            nStartP += line.count("<p>")
            nEndP += line.count("</p>")
        if nStartP != nEndP:
            print("Error in File : kiran_" + str(kiran) + ".json : " + str(nStartP) + "!=" + str(nEndP))
        file.close()

def Verify(location):
    for entry in Input:
        VerifyPart(location, entry[2], entry[3])

def main():
    #SaveAll("../feature/src/main/assets/saxatsavita/", False)
    SaveAll("../assets/book/saxatsavita/", True)
    SaveAll("saxatsavita/", True)

    Verify("saxatsavita/")
    return

main()