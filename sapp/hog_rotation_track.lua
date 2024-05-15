--
-- Hog Rotation Track by BUM Mouse v1.0
--
-- Script that reports hog stunt stats, air time above the ground and rotation
-- since leaving the ground.
--

api_version = "1.12.0.0"

hogs={}
function OnScriptLoad()
register_callback(cb["EVENT_TICK"],"OnTick")
register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
end

function OnGameEnd()
    hogs={}
end


function OnTick()

        for k,v in pairs(hogs) do
            local m_object=get_object_memory(v[1])
            if (v~=0) then
                local obj_is_on_ground = read_bit(m_object + 0x10, 1)
                if (obj_is_on_ground==0 and hogs[k][5]==false) then
                    hogs[k][2]=0
                    hogs[k][3]=0
                    hogs[k][4]=0
                    hogs[k][6]=0
                end
                if (obj_is_on_ground==0) then
                    local obj_pitch_vel = read_float(m_object + 0x8C) -- Confirmed for vehicles. Current velocity for pitch.
                    local obj_yaw_vel = read_float(m_object + 0x90) -- Confirmed for vehicles. Current velocity for yaw.
                    local obj_roll_vel = read_float(m_object + 0x94) -- Confirmed for vehicles. Current velocity for roll.
                    hogs[k][5]=true
                    hogs[k][2]=hogs[k][2]+math.abs(obj_pitch_vel)
                    hogs[k][3]=hogs[k][3]+math.abs(obj_yaw_vel)
                    hogs[k][4]=hogs[k][4]+math.abs(obj_roll_vel)
                    hogs[k][6]=hogs[k][6]+1
                end

                if (hogs[k][5]==true and obj_is_on_ground==1) then
                    local rotation=hogs[k][2]+hogs[k][3]+hogs[k][4]
                    say_all("Rotation: "..rotation.." Air: "..hogs[k][6])
                    hogs[k][5]=false
                end

                --say_all(obj_is_on_ground..','..obj_pitch_vel..','..obj_yaw_vel..','..obj_roll_vel)
            end
        end

end

function get_tag_info(obj_type, obj_name)
        local tag_id = lookup_tag(obj_type, obj_name)
        return tag_id ~= 0 and read_dword(tag_id + 0xC) or nil
end

function OnObjectSpawn(PlayerIndex, MapID, ParentID, ObjectID)
    if (MapID == get_tag_info("vehi", "vehicles\\rwarthog\\rwarthog") or MapID == get_tag_info("vehi", "vehicles\\warthog\\mp_warthog")) then
        table.insert(hogs,{ObjectID,0,0,0,false,0})

    end
end
