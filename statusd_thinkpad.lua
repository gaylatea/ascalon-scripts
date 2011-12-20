-- Thinkpad ACPI Battery Status for ion3 / notion Statusbar.
-- Developed by Arian [ab@gospel-virus.net]
--
-- This script supports both ion3-statusd and running as a console cmd.
--
-- Licensed to other developers under the Unlicense.


-- Get the current percentage of battery life from tp_smapi readings.
function get_thinkpad_acpi_battery_percentage()
    -- Here, we're assuming a single battery.
    -- Feel free to fork this script to add support for more, or for
    -- just changing the ones being monitored. My Thinkpad only has a
    -- single battery so I don't feel the need to generalize here.
    local f = io.open('/sys/devices/platform/smapi/BAT0/remaining_percent')
    local percent = f:read('*a')
    f:close()

    local plen = string.len(percent)
    percent = string.sub(percent, 1, (plen-1))
    return percent
end

-- Timer function that actually updates the statusbar.
function update_thinkpad_acpi_battery()
    local percent = get_thinkpad_acpi_battery_percentage()

    -- Hint to ion-statusd what state the battery is in.
    -- As I understand, it does colour-coding depending on the state.
    local pint = tonumber(percent)
    local state = 'normal'
    if pint < 30 then
        if pint < 10 then
            state = 'critical'
        end

        state = 'important'
    end
    
    if statusd ~= nil then
        statusd.inform("thinkpad_battery", percent .. "%")
        statusd.inform("thinkpad_battery_hint", state)
    else
       print("Battery Percentage: " .. percent .. "% (".. state ..")")
    end

    -- Restart the timer for the next update.
    if statusd ~= nil then
        -- Was originally 15 seconds.
        -- I figured that if my battery was getting low I would want to
        -- know much faster than that.
        thinkpad_acpi_battery_timer:set((10*1000), update_thinkpad_acpi_battery)
    end
end

-- Make sure the script keeps running.
if statusd ~= nil then
    thinkpad_acpi_battery_timer = statusd.create_timer()
end

update_thinkpad_acpi_battery()
