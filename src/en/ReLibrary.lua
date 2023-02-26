-- {"id":5252,"ver":"1.0.0","libVer":"1.0.0","author":"Maix","repo":"https://github.com/Maix0/Shosetsu_extensions","dep":[]}

local baseURL = "https://re-library.com/"
local ongoingTitlePrefix = "* "
--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-re%-library%.com/?", "")
end

--- @param url string
--- @return string
local function expandURL(url)
    return baseURL .. url
end

--- @param page_type string @only "translations" is used for now
--- @return Novel[]
local function getAllNovelFromPage(page_type)
    local page = GETDocument(expandURL(page_type))

    local all = map(page:select(".entry-content >  table >  tbody > tr > td > p > a"), function(anchor)
        local titlePrefixed = anchor:text()
        -- Non-Completed novels have the "* " prefix
        local title = (titlePrefixed:sub(0, #ongoingTitlePrefix) == ongoingTitlePrefix) and titlePrefixed:sub(#ongoingTitlePrefix + 1) or titlePrefixed;
        return Novel {
            title = title,
            imageURL = "",
            link = shrinkURL(anchor:attr("href") or "")
        }
    end)

    print(#all)
    return filter(all, function(e)
        print(e)
        return e ~= nil
    end)
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
    local doc = GETDocument(expandURL(novelURL))

    local title = doc:selectFirst("h1.entry-title"):text()

    local imageLink = doc:selectFirst("div.entry-content > table.rounded > tbody > tr > td > img"):attr("src")
    local summary = table.concat(map(doc:select("div.entry-content > p"),
            function(p)
                return p:text()
            end), "\n")
    local order = 0

    local chapterList = map(doc:select("div.entry-content > div > div"), function(elem)
        local divList = elem:children()
        if divList:size() == 0 then
            return {}
        end
        local collectionName = divList:get(0):text()
        local chap_list_per_volume = map(divList:select("ul > li > a"), function(e)
            local chapInstance = NovelChapter {
                order = order,
                link = shrinkURL(e:attr("href") or ""),
                title = collectionName .. " - " .. e:text(),
                release = ""
            }
            order = order + 1
            return chapInstance
        end)
        return chap_list_per_volume
    end)

    local flattenList = flatten(chapterList)

    local genres = map(doc:select("div.entry-content > table > tbody > tr > td > p > span > p"), function(link)
        link:text()
    end)

    return NovelInfo {
        title = title,
        description = summary,
        chapters = flattenList,
        imageURL = imageLink,
        language = "English",
        genres = genres,
    }
end

--- @param data table @of applied filter values [QUERY] is the search query, may be empty
--- @return Novel[]
local function search(data)

    local all1 = getAllNovelFromPage("translation")
    -- Uncomment this if you want to also search on the "original" category
    -- local all2 = getAllNovelFromPage("original")

    local all2 = {}
    local allNovels = flatten({ all1, all2 })

    return filter(allNovels, function(novel)
        return string.find(novel:getTitle():lower(), data[0]:lower())
    end)

end

return {
    id = 5252,
    name = "Re:Library",
    baseURL = baseURL,

    shrinkURL = shrinkURL,
    expandURL = expandURL,
    parseNovel = parseNovel,
    getPassage = getPassage,
    search = search,

    imageURL = "",
    hasCloudFlare = false,
    hasSearch = true,


    listings = {
        Listing("Translation", false, function(_)
            print("hello")
            return getAllNovelFromPage("translation")
        end),
        -- Uncomment this to have a new listing for "original" novels

        --Listing("Original", false, function(_)
        --    return getAllNovelFromPage("original")
        --end),
    },

    searchFilters = {
    },
    settings = {
    },


    chapterType = ChapterType.HTML,
    updateSetting = function(_, _)

    end
}
