local screenW, screenH = guiGetScreenSize()
local browser = nil
local mdtOpen = false

local function openMDT()
    if mdtOpen then return end
    mdtOpen = true

    browser = createBrowser(screenW, screenH, true, false)

    addEventHandler("onClientBrowserCreated", browser, function()
        loadBrowserURL(browser, "http://mta/local/ui/index.html")
        focusBrowser(browser)
        showCursor(true)
        guiSetInputEnabled(true)
    end)
end

local function closeMDT()
    if not mdtOpen then return end
    mdtOpen = false

    if browser and isElement(browser) then
        destroyElement(browser)
        browser = nil
    end
    showCursor(false)
    guiSetInputEnabled(false)
end

bindKey("F6", "down", function()
    if mdtOpen then closeMDT() else openMDT() end
end)

addCommandHandler("mdt", function()
    if mdtOpen then closeMDT() else openMDT() end
end)

addEventHandler("onClientRender", root, function()
    if browser and isElement(browser) and not isBrowserRenderingPaused(browser) then
        dxDrawImage(0, 0, screenW, screenH, browser, 0, 0, 0, tocolor(255,255,255,255))
    end
end)

-- INPUT INJECTION (CLICK + TYPE)
addEventHandler("onClientCursorMove", root, function(_, _, absX, absY)
    if not mdtOpen or not (browser and isElement(browser)) then return end
    if injectBrowserMouseMove then
        injectBrowserMouseMove(browser, absX, absY)
    end
end)

addEventHandler("onClientClick", root, function(button, state, absX, absY)
    if not mdtOpen or not (browser and isElement(browser)) then return end
    focusBrowser(browser)

    if injectBrowserMouseMove then
        injectBrowserMouseMove(browser, absX, absY)
    end

    if state == "down" then
        if injectBrowserMouseDown then injectBrowserMouseDown(browser, button) end
    else
        if injectBrowserMouseUp then injectBrowserMouseUp(browser, button) end
    end
end)

-- Mouse wheel
addEventHandler("onClientKey", root, function(button, press)
    if not mdtOpen or not (browser and isElement(browser)) then return end
    if press and (button == "mouse_wheel_up" or button == "mouse_wheel_down") then
        if injectBrowserMouseWheel then
            local delta = (button == "mouse_wheel_up") and 120 or -120
            injectBrowserMouseWheel(browser, delta)
            cancelEvent()
        end
    end
end)

-- Keyboard special keys (compat)
addEventHandler("onClientKey", root, function(button, press)
    if not mdtOpen or not (browser and isElement(browser)) then return end

    if injectBrowserKeyDown and injectBrowserKeyUp then
        if press then injectBrowserKeyDown(browser, button) else injectBrowserKeyUp(browser, button) end
        return
    end

    if injectBrowserKey then
        injectBrowserKey(browser, button, press)
        return
    end
end)

-- Text input
addEventHandler("onClientCharacter", root, function(character)
    if not mdtOpen or not (browser and isElement(browser)) then return end
    if injectBrowserInput then
        injectBrowserInput(browser, character)
    end
end)

-- UI -> LUA
addEvent("mdt:uiSearchCitizens", true)
addEventHandler("mdt:uiSearchCitizens", resourceRoot, function(q)
    triggerServerEvent("mdt:searchCitizens", resourceRoot, tostring(q or ""))
end)

addEvent("mdt:uiGetCitizenProfile", true)
addEventHandler("mdt:uiGetCitizenProfile", resourceRoot, function(id)
    triggerServerEvent("mdt:getCitizenProfile", resourceRoot, tonumber(id) or 0)
end)

-- SERVER -> UI
addEvent("mdt:citizensResult", true)
addEventHandler("mdt:citizensResult", resourceRoot, function(rows)
    if not (browser and isElement(browser)) then return end
    outputChatBox("MDT Citizens: received "..tostring((rows and #rows) or 0).." rows", 255, 255, 0)
    local json = toJSON(rows or {})
    executeBrowserJavascript(browser, ("window.MDT && MDT.setCitizens(%s);"):format(json))
end)

addEvent("mdt:citizenProfileResult", true)
addEventHandler("mdt:citizenProfileResult", resourceRoot, function(row)
    if not (browser and isElement(browser)) then return end
    local json = toJSON(row or {})
    executeBrowserJavascript(browser, ("window.MDT && MDT.setCitizenProfile(%s);"):format(json))
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    closeMDT()
end)
