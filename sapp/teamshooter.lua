-- Teamshooter by BUM Mouse v1.0

api_version = "1.12.0.0"
scores={}
dmg={
    {"globals\\vehicle_collision"},
    {"vehicles\\banshee\\banshee bolt"},
    {"vehicles\\banshee\\mp_fuel rod explosion"},
    {"vehicles\\ghost\\ghost bolt"},
    {"vehicles\\scorpion\\bullet"},
    {"vehicles\\scorpion\\shell explosion"},
    {"vehicles\\warthog\\bullet"},
    {"weapons\\assault rifle\\bullet"},
    {"weapons\\assault rifle\\melee"},
    {"weapons\\ball\\melee"},
    {"weapons\\flag\\melee"},
    {"weapons\\flamethrower\\burning"},
    {"weapons\\flamethrower\\explosion"},
    {"weapons\\flamethrower\\melee"},
    {"weapons\\frag grenade\\explosion"},
    {"weapons\\needler\\explosion"},
    {"weapons\\needler\\impact damage"},
    {"weapons\\needler\\melee"},
    {"weapons\\pistol\\bullet"},
    {"weapons\\pistol\\melee"},
    {"weapons\\plasma grenade\\explosion"},
    {"weapons\\plasma grenade\\attached"},
    {"weapons\\plasma pistol\\bolt"},
    {"weapons\\plasma pistol\\melee"},
    {"weapons\\plasma rifle\\bolt"},
    {"weapons\\plasma rifle\\charged bolt"},
    {"weapons\\plasma rifle\\melee"},
    {"weapons\\plasma_cannon\\impact damage"},
    {"weapons\\rocket launcher\\explosion"},
    {"weapons\\rocket launcher\\melee"},
    {"weapons\\shotgun\\melee"},
    {"weapons\\shotgun\\pellet"},
    {"weapons\\sniper rifle\\melee"},
    {"weapons\\sniper rifle\\sniper bullet"},
}
score_cooldown={}
function OnScriptLoad()

    register_callback(cb['EVENT_DAMAGE_APPLICATION'], "OnDamageApplication")
    register_callback(cb["EVENT_JOIN"],"OnJoin")
    register_callback(cb['EVENT_TICK'],"OnTick")
    for i=1,16,1 do
        score_cooldown[i]=0
    end
end
global_score_cooldown=300
function OnTick()
    global_score_cooldown=global_score_cooldown-1
    if (global_score_cooldown<0) then
        global_score_cooldown=300
        for k,v in pairs(scores) do
            if (scores[k]>0) then
                scores[k]=scores[k]-1
                --print(scores[k])
            end
        end
    end

    for i=1,16,1 do
        if (score_cooldown[i]>0) then
            score_cooldown[i]=score_cooldown[i]-1
        end
    end
end

function OnJoin(PlayerIndex)
    local PlayerIndex=tonumber(PlayerIndex)
    local ip=get_var(PlayerIndex,"$ip")
    if (scores[ip]==nil) then
        scores[ip]=0
    end
    for k,v in pairs(scores) do
        --print(k,v)
    end
    score_cooldown[PlayerIndex]=0
end


function OnDamageApplication(PlayerIndex, Causer, MetaID, Damage, HitString, Backtap)

    local player_team=get_var(PlayerIndex,"$team")
    local causer_team=get_var(Causer,"$team")

    if (player_team==causer_team) then
        if (player_present(Causer)) then
            for k,v in pairs(dmg) do
                if (get_tag_info("jpt!",v[1])==MetaID) then
                    --print(v[1])
                    Causer=tonumber(Causer)
                    local ip=get_var(Causer,"$ip")
                    --print(ip)
                    if (scores[ip]~=nil) then
                        if (score_cooldown[Causer]<=0) then
                            if (get_tag_info("jpt!","globals\\vehicle_collision")==MetaID) then
                                scores[ip]=scores[ip]+2
                            else
                                scores[ip]=scores[ip]+1
                            end
                            score_cooldown[Causer]=30
                            if (scores[ip]>9) then
                                say(Causer,"Keep teamshooting and you will be kicked")
                            end
                            if (scores[ip]>19) then
                                execute_command("k "..Causer)
                            end
                        end
                    end
                end
            end
        end
    end

end

function get_tag_info(obj_type, obj_name)
        local tag_id = lookup_tag(obj_type, obj_name)
        return tag_id ~= 0 and read_dword(tag_id + 0xC) or nil
end
