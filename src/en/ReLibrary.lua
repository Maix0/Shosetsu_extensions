-- {"id":-1,"ver":"0.0.1","libVer":"1.0.0","author":"Maix","repo":"https://github.com/Maix0/Shosetsu_extensions","dep":["url"]}

local baseURL = "https://re-library.com"
local settings = {}

--- @param path string
--- @return string
local function getUrlFromPath(path)
    return baseURL .. path
end

--- @param chapterURL string
--- @return string
local function getPassage(chapterURL)
    return ""
end

--- @param novelURL string
--- @return NovelInfo
local function parseNovel(novelURL)
    return NovelInfo()
end

--- @param filters table @of applied filter values [QUERY] is the search query, may be empty
--- @return Novel[]
local function search(data)


end

--- @param doc Document
--- @return string[]
local function getAssociatedNames(doc)
    return map(AsList(split(doc:select("#editassociated"):text(), "<br>")), function(s)
        return string.gsub(s, '^%s*(.-)%s*$', '%1')
    end)
end

-- split("a,b,c", ",") => {"a", "b", "c"}
-- split("a,b,c", ",", f) => {f("a"), f("b"), f("c")}
--- @param str string
--- @param sep string
--- @return string[]
local function split(s, sep)
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(str, pattern, function(c)
        fields[#fields + 1] = c
    end)
    return fields
end

--- @param name string
--- @param novelType string | nil
--- @return NovelInfo
local function getNovelDataFromUrl(name, novelType)
    local novelType = novelType or "translation"
    local doc = GETDocument(getUrlFromPath("/" .. novelType .. "/" .. name))
    local title = doc:selectFirst("h1.entry-title"):text()

    local imageLink = doc:selectFirst("div.entry-content > table > tr > td > img"):attr("src")
    local summary =  table.concat(map(doc:select("div.entry-content > p"), function (p) p:text() end), "\n")
    local order = 0
    local chapterList = map2flat(doc:select("div.entry-content > div > div"), function (elem)
        local divList = elem:children()
        local collectionName = divList:get(0):text()
        local chapters = map(divList:et(1):select("ul > li > a"), function (chap)
            local chapInstance = NovelChapter()
            chapInstance:setOrder(order)
            order = order + 1
            chapInstance:setLink(chap:attr("href"))
            chapInstance:setTitle(collectionName.." - "..chap:text())
            chapInstance:setRelease("")
            return chapInstance
        end,
        function (l) return l end
        )

    end)

    local genres = map(doc:select("div.entry-content > table > tbody > tr > td > p > span > p"), function (link) link:text() end)

    local novel = NovelInfo()
    novel:setTitle(title)
    novel:setDescription(summary)
    novel:setChapters(chapterList)
    novel:setImageURL(imageLink)
    novel:setLanguage("English")
    novel:setGenres(genres)

    return novel

end

return {
    id = -1,
    name = "Re:Library",
    baseURL = baseURL,

    -- Optional values to change
    imageURL = "",
    hasCloudFlare = false,
    hasSearch = true,


    -- Must have at least one value
    listings = {
        Listing("Something", false, function(data)
            return {}
        end),
        Listing("Something (with pages!)", true, function(data, index)
            return {}
        end),
        Listing("Something without anything", false, function()
            return {}
        end)
    },

    -- Optional if usable
    searchFilters = {
        TextFilter(1, "RANDOM STRING INPUT"),
        SwitchFilter(2, "RANDOM SWITCH INPUT"),
        CheckboxFilter(3, "RANDOM CHECKBOX INPUT"),
        TriStateFilter(4, "RANDOM TRISTATE CHECKBOX INPUT"),
        RadioGroupFilter(5, "RANDOM RGROUP INPUT", { "A", "B", "C" }),
        DropdownFilter(6, "RANDOM DDOWN INPUT", { "A", "B", "C" })
    },
    settings = {
        TextFilter(1, "RANDOM STRING INPUT"),
        SwitchFilter(2, "RANDOM SWITCH INPUT"),
        CheckboxFilter(3, "RANDOM CHECKBOX INPUT"),
        TriStateFilter(4, "RANDOM TRISTATE CHECKBOX INPUT"),
        RadioGroupFilter(5, "RANDOM RGROUP INPUT", { "A", "B", "C" }),
        DropdownFilter(6, "RANDOM DDOWN INPUT", { "A", "B", "C" })
    },

    -- Default functions that have to be set
    getPassage = getPassage,
    parseNovel = parseNovel,
    search = search,
    updateSetting = function(id, value)
        settings[id] = value
    end
}
