-- {"id":9999,"ver":"1.0.0","libVer":"1.0.0","author":"Maix","repo":"https://github.com/Maix0/Shosetsu_extensions","dep":[]}

local baseURL = "https://re-library.com"
local settings = {}

local function tableConcat(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

--- @param o ArrayList | table
--- @return table
local function filterNil(o)
    local t, j = {}, 0

    if type(o) == "table" then
        for _, v in ipairs(o) do
            print(v)
            if v then
                j = j + 1
                t[j] = v
            end
        end
    else
        for i = 0, o:size() - 1 do
            local v = o:get(i)
            print(v)
            if v then
                j = j + 1
                t[j] = v
            end
        end
    end

    return t
end

--- @param chapterURL string
--- @return string
local function getPassage(chapterURL)
    local doc = GETDocument(chapterURL)

    local article = doc:selectFirst("article");

    article:selectFirst("p")
           :remove() -- remove "leave a comment" button
    article:select("table, div.entry-content > div, hr, h2, ol")
           :remove()-- remove non-text stuff

    return pageOfElem(article)
end

--- @param novelURL string
--- @return NovelInfo
local function parseNovel(novelURL)
    local doc = GETDocument(novelURL)

    local title = doc:selectFirst("h1.entry-title"):text()

    local imageLink = doc:selectFirst("div.entry-content > table > tbody > tr > td > img"):attr("src")
    local summary = table.concat(map(doc:select("div.entry-content > p"), function(p)
        p:text()
    end), "\n")
    local order = 0

    local chapterList = filterNil(map(doc:select("div.entry-content > div > div"), function(elem)
        if elem:children():size() == 0 then
            return nil
        end
        local divList = elem:children()
        local collectionName = divList:get(0):text()
        local chap_list_per_volume = map(divList:select("ul > li > a"), function(e)
            local chapInstance = NovelChapter()
            chapInstance:setOrder(order)
            order = order + 1
            chapInstance:setLink(e:attr("href"))
            chapInstance:setTitle(collectionName .. " - " .. e:text())
            chapInstance:setRelease("")
            return chapInstance
        end)
        if #chap_list_per_volume == 0 then
            return nil
        end
        local out = filterNil(chap_list_per_volume)

        if #out == 0 then
            return nil
        end
        return out
    end))

    local flattenList = flatten(chapterList)

    local genres = map(doc:select("div.entry-content > table > tbody > tr > td > p > span > p"), function(link)
        link:text()
    end)

    local novel = NovelInfo()
    novel:setTitle(title)
    novel:setDescription(summary)
    novel:setChapters(flattenList)
    novel:setImageURL(imageLink)
    novel:setLanguage("English")
    novel:setGenres(genres)

    return novel
end

--- @param filters table @of applied filter values [QUERY] is the search query, may be empty
--- @return Novel[]
local function search(data)
    local page1 = GETDocument(baseURL .. "/translations/")

    local all1 = map(page1:select(".entry-content >  table >  tbody > tr > td > p > a"), function(anchor)
        local titlePrefixed = anchor:text()
        return Novel {
            title = (titlePrefixed:sub(0, #"* ") == "* ") and titlePrefixed:sub(#"* " + 1) or titlePrefixed,
            imageURL = "",
            link = anchor:attr("href")
        }
    end)

    local page2 = GETDocument(baseURL .. "/original/")
    local all2 = map(page2:select(".entry-content >  table >  tbody > tr > td > p > a"), function(anchor)
        local titlePrefixed = anchor:text()
        return Novel {
            title = (titlePrefixed:sub(0, #"* ") == "* ") and titlePrefixed:sub(#"* " + 1) or titlePrefixed,
            imageURL = "",
            link = anchor:attr("href")
        }
    end)
    print(#all1)
    print(#all2)

    local allNovels = filterNil(tableConcat(all1, all2))

    print(#allNovels)

    print("QUERY: " .. data[0]:lower())
    return filter(tableConcat(all1, all2), function(novel)
        print("TITLE: " .. novel:getTitle():lower())
        return string.find(novel:getTitle():lower(), data[0]:lower())
    end)

end

return {
    id = 9999,
    name = "Re:Library",
    baseURL = baseURL,

    -- Optional values to change
    imageURL = "",
    hasCloudFlare = false,
    hasSearch = true,


    -- Must have at least one value
    listings = {
        Listing("Translation", false, function(data)
            local page = GETDocument(baseURL .. "/translations/")
            local all = map(page:select(".entry-content >  table >  tbody > tr > td > p > a"), function(anchor)
                local titlePerfixed = anchor:text()
                Novel {
                    title = (titlePerfixed:sub(0, #" *") == " *") and titlePerfixed:sub(#" *" + 1) or titlePerfixed,
                    imageURL = "",
                    link = anchor:attr("href")
                }
            end)

            return filterNil(all)
        end),
        Listing("Original Work", false, function(data)
            local page = GETDocument(baseURL .. "/original/")
            local all = map(page:select(".entry-content >  table >  tbody > tr > td > p > a"), function(anchor)
                local titlePerfixed = anchor:text()
                Novel {
                    title = (titlePerfixed:sub(0, #" *") == " *") and titlePerfixed:sub(#" *" + 1) or titlePerfixed,
                    imageURL = "",
                    link = anchor:attr("href")
                }
            end)

            return filterNil(all)
        end),
    },

    -- Optional if usable
    searchFilters = {
    },
    settings = {
    },

    -- Default functions that have to be set
    getPassage = getPassage,
    parseNovel = parseNovel,
    search = search,
    chapterType = ChapterType.HTML,
    updateSetting = function(id, value)
        settings[id] = value
    end
}
