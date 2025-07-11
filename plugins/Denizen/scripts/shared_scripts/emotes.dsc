fort_emote_handler:
  type: world
  debug: false
  events:

    #-minor problem: can't emote while in build mode
    #(probs because item updates every tick)
    on player clicks in inventory slot:2|3|4|5:
    - if <context.clicked_inventory.inventory_type> != CRAFTING:
      - stop
    - determine passively cancelled

    - if <bungee.server> == fort_lobby:
      - narrate "<&e>To prevent lag, emotes are disabled in the lobby temporarily."
      - stop

    - if <player.has_flag[fort.disable_emotes]> || <player.has_flag[fort.on_bus]> || <player.has_flag[fort.using_glider]>:
      - stop

    - if <player.has_flag[fort.emote_cooldown]>:
      - if !<player.has_flag[fort.emote_cooldown_msg_cooldown]>:
        - narrate "<&c>Your emotes are on cooldown. (<player.flag_expiration[fort.emote_cooldown].from_now.formatted>)"
        - flag player fort.emote_cooldown_msg_cooldown duration:3s
      - stop

    - define players_emoting <server.online_players_flagged[fort.emote]>
    - if <[players_emoting].size> >= 10:
      - narrate "<&c>There are too many players emoting right now."
      - stop

    - define emote <map[2=default;3=none;4=none;5=none].get[<context.slot>]>

    #second check is for if they're already emoting
    - if <[emote]> == none || <player.has_flag[fort.emote]>:
      - stop

    - define emote_loc <player.location.above[0.35]>
    - if <player.has_flag[fort.in_menu]>:
      - if !<player.has_flag[fort.menu.player_npc]> || !<player.flag[fort.menu.player_npc].is_spawned>:
        - narrate "<&c>[error] Your player isn't spawned."
        - stop
      - define emote_loc <player.flag[fort.menu.player_npc].location.above[0.4]>

    - choose <[emote]>:
      - case default:
        - define sound fort.emotes.default.<util.random.int[1].to[3]>

    - if <player.has_flag[fort.in_menu]>:
      - define sound_loc <player>
      #using fake_to def to hide the emote from other players
      - run dmodels_spawn_model def.player:<player> def.model_name:emotes def.location:<[emote_loc].above[2]> def.fake_to:<player> save:result
    - else:
      - define sound_loc <[emote_loc]>
      - run dmodels_spawn_model def.player:<player> def.model_name:emotes def.location:<[emote_loc].above[2]> save:result

    - playsound <[sound_loc]> custom sound:<[sound]> volume:1.2

    - define spawned <entry[result].created_queue.determination.first||null>
    - if !<[spawned].is_truthy>:
        - narrate "<&[error]>Emote spawning failed?"
        - stop

    - if !<player.has_flag[fort.in_menu]>:
      #"remove" everything for their hands
      - fakeequip <player> for:<server.online_players> hand:air duration:10s

    #- run dmodels_set_yaw def.root_entity:<[spawned]> def.yaw:<player.location.yaw>
    - run dmodels_set_scale def.root_entity:<[spawned]> def.scale:1.87,1.87,1.87

    #no need for hitbox in menu
    - if !<player.has_flag[fort.in_menu]>:
      - spawn INTERACTION[height=2;width=1] <player.location> save:hitbox
      - define hb <entry[hitbox].spawned_entity>
      - flag <[hb]> emote.hitbox.host:<player>
      - flag <[spawned]> emote_hitbox:<[hb]>

    - flag player fort.emote.sound:<[sound]>
    - flag player spawned_dmodel_emotes:<[spawned]>
    - flag <[spawned]> emote_host:<player>
    - flag <[spawned]> emote_loc:<[emote_loc]>
    - flag <[spawned]> emote_sound:<[sound]>

    - run dmodels_animate def.root_entity:<[spawned]> def.animation:<[emote]>
    - flag player fort.emote_cooldown duration:20s

    - wait 1t
    - inventory close

    on player damages INTERACTION flagged:fort.emote:
    - flag player fort.emote:!

    on player clicks block flagged:fort.emote:
    - flag player fort.emote:!

    #this flag is added in dmodels_animating.dsc for the third person viewer
    #this event also fires when the player goes offline (but doesnt work?)
    on player exits vehicle flagged:fort.emote:
    - flag player fort.emote:!

    on player quits flagged:fort.emote:
    - if <player.has_flag[fort.in_menu]>:
      - stop
    - invisible <player> false
    - fakeequip <player> for:<server.online_players> reset
    - if <player.has_flag[spawned_dmodel_emotes]>:
      - define model <player.flag[spawned_dmodel_emotes]>
      - define cam   <[model].flag[camera]>
      - define stand <[model].flag[stand]>
      - define hb    <[model].flag[emote_hitbox]>
      - remove <[cam]>   if:<[cam].is_spawned>
      - remove <[stand]> if:<[stand].is_spawned>
      - remove <[hb]>    if:<[hb].is_spawned>
    - flag player fort.emote:!