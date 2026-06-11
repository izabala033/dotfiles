-- Portable default for single-monitor sessions.
-- Dual-screen layout is applied dynamically at runtime when multiple outputs
-- are present, and keeps scale at 1 there.
-- Increase the final value to make the laptop screen bigger, or lower it for
-- more space.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1.25,
})

local function monitor_order_state_file()
    local state_home = os.getenv("XDG_STATE_HOME")

    if state_home == nil or state_home == "" then
        local home = os.getenv("HOME")

        if home == nil or home == "" then
            return nil
        end

        state_home = home .. "/.local/state"
    end

    return state_home .. "/hypr/monitor-order"
end

local function read_monitor_order()
    local path = monitor_order_state_file()

    if path == nil then
        return nil, nil
    end

    local file = io.open(path, "r")

    if file == nil then
        return nil, nil
    end

    local left_monitor = file:read("*l")
    local right_monitor = file:read("*l")
    file:close()

    if left_monitor == nil or right_monitor == nil or left_monitor == "" or right_monitor == "" or left_monitor == right_monitor then
        return nil, nil
    end

    return left_monitor, right_monitor
end

local left_monitor, right_monitor = read_monitor_order()

if left_monitor ~= nil and right_monitor ~= nil then
    hl.monitor({ output = left_monitor, mode = "preferred", position = "0x0", scale = 1 })
    hl.monitor({ output = right_monitor, mode = "preferred", position = "1920x0", scale = 1 })

    for workspace = 1, 9 do
        hl.workspace_rule({ workspace = tostring(workspace), monitor = right_monitor })
    end

    for workspace = 10, 20 do
        hl.workspace_rule({ workspace = tostring(workspace), monitor = left_monitor })
    end
end
