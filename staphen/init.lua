local addons = {}

local function present()
    for i, a in ipairs(addons) do
        a.present()
    end
end

local function init()
    table.insert(addons, {addon = require("staphen.Kill Counter")})

    for i, a in ipairs(addons) do
        a.present = a.addon.__addon.init().present
    end

    return
    {
        name = "Kill Counter",
        version = "1.1.1",
        author = "staphen",
        description = "Tracks numbers of enemy kills",
        present = present
    }
end

return 
{
    __addon =
    {
        init = init
    }
}
