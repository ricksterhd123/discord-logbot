--[[
    Utility functions
]]

function string.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function prependZero(str)
    str = tostring(str)
    return #str < 2 and "0"..str or str
end

function getTimeStamp()
    local time = getRealTime()

    local year = time.year + 1900
    local month = prependZero(time.month + 1)
    local day = prependZero(time.monthday)
    local hour = prependZero(time.hour)
    local minute = prependZero(time.minute)
    local second = prependZero(time.second)

    return year.."-"..month.."-"..day.."T"..hour..":"..minute..":"..second
end

--[[
    Settings & State
]]

--- Message Queue
local queue = {}

--- Discord webhook URL
local webhookURL

--- Number of messages to batch before sending to discord
local batchSize

--- A comma separated string of words to censor and replace with "******"
local censoredWords

addEventHandler("onSettingChange", root, function (setting, _, newValue)
    iprint(setting, newValue)
    if setting == "*discord-logbot.BatchSize" then
        batchSize = fromJSON(newValue) or 10
    elseif setting == "*discord-logbot.WebhookURL" then
        webhookURL = newValue
    elseif setting == "*discord-logbot.CensoredWords" then
        censoredWords = string.split(fromJSON(newValue) or "")
    end
end)

--[[
    Discord webhook functions
]]
function onWebhookSend(responseData, responseInfo)
    if not responseInfo.success then
        outputDebugString("Failed to send message to webhook, got status: "..toJSON(responseInfo)..", response: "..responseData)
    end
end

function sendLogMessage(message)
    local settings = {
        formFields = {
            content = message
        }
    }
    fetchRemote(webhookURL, settings, onWebhookSend)
end

--[[
    Buffer queue webhook posts
]]
function sanitizeMessage(message)
    for _, censoredWord in ipairs(censoredWords) do
        local replacementWord = ""
        for i = 1, #censoredWord do
            replacementWord = replacementWord .. "*"
        end
        message = message:gsub(censoredWord, replacementWord)
    end
    -- Now URL encode any @ to prevent ping in discord
    message = message:gsub("@", "%%40")
    return message
end

--- Completely flush the queue
function flushLogMessages()
    local messages = ""
    for i, message in ipairs(queue) do
        local sanitizedMessage = sanitizeMessage(message)
        messages = messages..sanitizedMessage.."\n"
    end

    queue = {}
    sendLogMessage(messages)
end

--- Queue the message to be sent
function queueLogMessage(message)
    table.insert(queue, message)

    if #queue >= batchSize then
        flushLogMessages()
    end
end

--[[
    Registered server-side events to log
]]
addEventHandler("onPlayerChat", root, function (message, messageType)
	if not isElement(source) then return end
    if messageType == 0 then
        local playerName = getPlayerName(source)
        local serial = getPlayerSerial(source)
        queueLogMessage("["..getTimeStamp().."] ["..serial.."] [CHAT] "..playerName..": "..message)
    end
end)

addEventHandler("onPlayerACInfo", root, function (detectedACList, d3d9Size, _, d3d9SHA256)
    local playerName = getPlayerName(source)
    local serial = getPlayerSerial(source)
    queueLogMessage("["..getTimeStamp().."] [PLAYER ACINFO] Nick: " .. playerName .. ", Serial: " .. serial 
    .. ", detectedACList: " .. table.concat(detectedACList,",")
    .. ", d3d9Size: " .. d3d9Size
    .. ", d3d9SHA256: " .. d3d9SHA256)
end)

addEventHandler("onPlayerBan", root, function (ban, responsibleElement)
    local bannerName = getPlayerName(responsibleElement) or "Console"
    local bannerSerial = getPlayerSerial(responsibleElement)
    local bannedName = getPlayerName(source)
    local bannedSerial = getPlayerSerial(source)
    local banReason = getBanReason(ban) or "N/A"
    queueLogMessage("["..getTimeStamp().."] [PLAYER BANNED] Banner Nick: "..bannerName..", Banner Serial: "..bannerSerial..", Banned Nick: "..bannedName..", Banned Serial: "..bannedSerial..", Reason: "..banReason)
end)

addEventHandler("onPlayerMute", root, function ()
    local playerName = getPlayerName(source)
    local serial = getPlayerSerial(source)
    queueLogMessage("["..getTimeStamp().."] [PLAYER MUTED] Nick: "..playerName..", Serial: "..serial)
end)

addEventHandler("onPlayerUnmute", root, function ()
    local playerName = getPlayerName(source)
    local serial = getPlayerSerial(source)
    queueLogMessage("["..getTimeStamp().."] [PLAYER UNMUTED] Nick: "..playerName..", Serial: "..serial)
end)

addEventHandler("onPlayerJoin", root, function ()
    local playerName = getPlayerName(source)
    local serial = getPlayerSerial(source)
    queueLogMessage("["..getTimeStamp().."] [PLAYER JOIN] Nick: "..playerName..", Serial: "..serial)
end)

addEventHandler("onPlayerQuit", root, function (quitType, reason)
    local playerName = getPlayerName(source)
    local serial = getPlayerSerial(source)
    local reason = reason or "N/A"
    queueLogMessage("["..getTimeStamp().."] [PLAYER QUIT] Nick: "..playerName..", Serial: "..serial..", QuitType: "..quitType..", Reason: "..reason)
end)

addEventHandler("onPlayerChangeNick", root, function (old, new)
    local serial = getPlayerSerial(source)
    queueLogMessage("["..getTimeStamp().."] [PLAYER NICK CHANGED] Old nick: "..old..", New nick: "..new, " Serial: "..serial)
end)

addEventHandler("onResourceStart", resourceRoot, function ()

    --- Discord webhook URL
    webhookURL = get("WebhookURL")

    --- Number of messages to batch before sending to discord
    batchSize = get("BatchSize")

    --- A comma separated string of words to censor and replace with "******"
    censoredWords = string.split(get("CensoredWords") or "")

    queueLogMessage("["..getTimeStamp().."] [RESOURCE START] Hello")
    flushLogMessages()
end)

addEventHandler("onResourceStop", resourceRoot, function ()
    queueLogMessage("["..getTimeStamp().."] [RESOURCE STOP] Goodbye")
    flushLogMessages()
end)

function outputDiscordLog(message)
    queueLogMessage("["..getTimeStamp().."] "..message)
end
