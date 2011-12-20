-- Thinkpad ACPI Battery Status for ion3 / notion Statusbar.
-- Developed by Arian [ab@gospel-virus.net]
--
-- This script supports both ion3-statusd and running as a console cmd.
--
-- Licensed to other developers under the Unlicense.

-- Get the current remaining battery time from the internal chipset.
-- According to my calculations, it reports this in minutes. It's
-- constantly adjusting itself, but it's accurate enough to get a sense
-- of how much time is left.
--
-- Sadly, once disconnected from AC power it takes a minute or two for
-- the chipset to accurately calculate how much time is left, so you'll
-- see crazy things like 9:10 (98%) as it dips down to the more normal
-- running times.
--
-- The chipset will return 'not_discharging' if it's on AC power and we
-- can use this to our advantage.
function get_thinkpad_acpi_battery_runtime()
    -- Once again, we assume a single battery in the laptop.
    -- Check back if I ever get the slice batteries for my T420. ;)
    local f = io.open('/sys/devices/platform/smapi/BAT0/remaining_running_time')
    local status = f:read('*a')
    f:close()

    if status ~= 'not_discharging' then
        -- The readout contains a newline that disturbs the output.
        local mins = string.len(status)
        status = string.sub(status, 1, (mins-1))
        return tonumber(status)
    else
        return nil
    end
end

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
    local runtime = get_thinkpad_acpi_battery_runtime()
    local percent = get_thinkpad_acpi_battery_percentage()

    -- If needed, calculate hh:mm for battery runtime.
    if runtime == nil then
        if statusd ~= nil then
            statusd.inform('thinkpad_battery', 'On AC Power')
            statusd.inform('thinkpad_battery_hint', 'normal')
        else
            print("On AC Power")
        end
    else
        local hours     = math.floor(runtime / 60)
        local minutes   = (runtime % 60)

        local pnum      = tonumber(percent)
        local state     = 'normal'

        if pnum < 30 then
            if pnum < 10 then
                state = 'critical'
            end
            state = 'important'
        end

        -- Form the final output string.
        local output = hours..":"..minutes.." ("..pnum.."%)"
        if statusd ~= nil then
            statusd.inform('thinkpad_battery', output)
            statusd.inform('thinkpad_battery_hint', state)
        else
            print(output)
        end
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
