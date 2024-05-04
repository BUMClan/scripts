-- Telenade by 002 v1.2

-- You throw these things...
TELEPORT_GRENADES = true

-- Health packs, active camouflage, overshields, and ammo clips are teleported.
TELEPORT_POWERUPS = true

-- You can hold these things and possibly even shoot them. This also includes the flag and the oddball.
TELEPORT_WEAPONS = true

-- Teleporter radius in world units, checked using two dimensions.
-- As a reference, Halo's normal teleportation distance for players is 0.25 WU.
TELEPORTER_RADIUS = 0.25

-- Minimum 2D velocity to teleporter objects, in world units per tick. This is to prevent objects that are too slow from being caught in an endless teleporter loop.
TELEPORTER_MINIMUM_SPEED = 0.0275

-- End of configuration

api_version = "1.8.0.0"
object_table_ptr = nil


function OnScriptLoad()
    object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
    if(object_table_ptr == 0) then
        cprint("Telenade failed to find the object table.")
        cprint("Please report this bug to 002 (me) on OpenCarnage.net.")
        if(halo_type ~= nil) then
            cprint("Make sure to tell me you're using the Halo " .. halo_type .. " dedicated server.")
        else
            cprint("Make sure to tell me what type of dedicated server you're using (PC or CE).");
        end
        cprint("Also include that your version is " .. read_string(0x40000104) .. ". That might be important.")
        cprint("Telenade is now inactive. Sorry for the inconvenience.")
        return
    end

    register_callback(cb['EVENT_GAME_START'],"OnGameStart")
    register_callback(cb['EVENT_TICK'],"OnTick")

    OnGameStart()
end

function OnScriptUnload() end

teleporters_from = {}
teleporters_to = {}
grenades = {}

remove = table.remove

function OnGameStart()
    teleporters_from = {}
    teleporters_to = {}
    local scnr_tag_id = read_word(0x40440004)
    local tag_array = read_dword(0x40440000)
    local scnr_tag_data = read_dword(tag_array + scnr_tag_id * 0x20 + 0x14)

    local netgame_flags_ref = scnr_tag_data + 0x378
    local netgame_flags_count = read_dword(netgame_flags_ref)
    local netgame_flags = read_dword(netgame_flags_ref + 4)

    for i=0,netgame_flags_count-1 do
        local netgame_flag = netgame_flags + i * 148
        local coord_x,coord_y,coord_z = read_vector3d(netgame_flag + 0x0)
        local type = read_word(netgame_flag + 0x10)
        local index = read_word(netgame_flag + 0x12)
        local rotation = read_float(netgame_flag + 0xC)
        if(type == 6) then
            teleporters_from[#teleporters_from+1] = {
                x = coord_x,
                y = coord_y,
                z = coord_z,
                to = index,
                r = rotation
            }
        elseif(type == 7) then
            teleporters_to[index] = {
                x = coord_x,
                y = coord_y,
                z = coord_z,
                r = rotation
            }
        end
    end

    for i=#teleporters_from,1,-1 do
        if(teleporters_to[teleporters_from[i].to] == nil) then
            remove(teleporters_from, i)
        end
    end

    local tag_count = read_word(0x4044000C)

    grenades = {}
    for i=0,tag_count-1 do
        local tag = tag_array + i * 0x20
        if(read_dword(tag) == 1835103335 and read_string(read_dword(tag + 0x10)) == "globals\\globals") then
            local tag_data = read_dword(tag + 0x14)
            local grenades_ref = tag_data + 0x128
            local grenades_count = read_dword(grenades_ref)
            local grenades_address = read_dword(grenades_ref + 0x4)
            for g=0,grenades_count-1 do grenades[read_word(grenades_address + g * 68 + 0x34 + 0xC)] = true end
            break
        end
    end
end

sqrt = math.sqrt
sin = math.sin
cos = math.cos

function OnTick()
    local object_table = read_dword(read_dword(object_table_ptr + 2))
    local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
    for i=0,object_count-1 do
        local object = read_dword(first_object + i * 0xC + 0x8)
        if(object ~= 0 and object ~= 0xFFFFFFFF) then
            local object_type = read_word(object + 0xB4)

            local can_teleport = false

            if(TELEPORT_GRENADES and object_type == 5 and grenades[read_word(object)]) then can_teleport = true end
            if(TELEPORT_POWERUPS and object_type == 3) then can_teleport = true end
            if(TELEPORT_WEAPONS and object_type == 2) then can_teleport = true end

            if(read_dword(object + 0x11C) ~= 0xFFFFFFFF) then can_teleport = false end

            if(can_teleport) then
                local coord_x,coord_y,coord_z = read_vector3d(object + 0xA0)
                for k,v in pairs(teleporters_from) do
                    local x = (coord_x - v.x)
                    local y = (coord_y - v.y)
                    if(sqrt(x*x + y*y) <= TELEPORTER_RADIUS and coord_z > v.z - 0.10 and coord_z < v.z + 1.00) then
                        local t = teleporters_to[v.to]

                        local vel_x,vel_y,vel_z = read_vector3d(object + 0x68)
                        local total_vel_2d = sqrt(vel_x * vel_x + vel_y * vel_y)
                        if(total_vel_2d >= TELEPORTER_MINIMUM_SPEED) then
                            local r_difference = t.r - v.r

                            local s = sin(r_difference)
                            local c = cos(r_difference)

                            local new_vx = vel_x * c - vel_y * s
                            local new_vy = vel_y * c + vel_x * s

                            write_vector3d(object + 0x68,new_vx,new_vy,vel_z)

                            local cx,cy,cz = read_vector3d(object + 0x5C)
                            local bx = coord_x - cx
                            local by = coord_y - cy
                            local bz = coord_z - cz

                            local new_x = t.x
                            local new_y = t.y

                            local height = coord_z - v.z
                            local new_z = t.z
                            if(height > 0) then new_z = new_z + height end

                            write_vector3d(object + 0x5C, new_x, new_y, new_z)

                            write_vector3d(object + 0xA0, new_x + bx, new_y + by, new_z + bz)
                        end

                        break
                    end
                end
            end
        end
    end
end
