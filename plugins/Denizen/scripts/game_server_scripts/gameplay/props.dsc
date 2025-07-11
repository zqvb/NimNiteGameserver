fort_prop_handler:
  type: world
  debug: false
  definitions: data
  events:
    # - [ Special Props ] - #
    on player steps on barrier:
    #could in theory let players sit on chairs if they stand on it
    - if !<context.location.has_flag[fort.prop]>:
      - stop
    - define prop_hb <context.location.flag[fort.prop.hitbox]>
    - stop if:!<[prop_hb].is_spawned>
    - define name    <[prop_hb].flag[fort.prop.name]>
    - choose <[name]>:
      #only problem: the bounce is constantly the same height, not based on momentum, eh whatever
      - case tires:
        - playsound <context.location> sound:BLOCK_BAMBOO_WOOD_FALL pitch:1.1
        - adjust <player> velocity:0,1,0

    on INTERACTION damaged:
    - stop if:<context.entity.has_flag[fort.prop].not>
    - define damager <context.damager||null>
    - define prop_hb    <context.entity>
    - define prop_model <[prop_hb].flag[fort.prop.model]>


    - if <[prop_hb].flag[fort.prop.health]> == unbreakable:
      - run fort_prop_handler.damage_prop def:<map[prop_hb=<[prop_hb]>;damage=0]>
      - stop

    #-if players break it with a pickaxe, run the harvesting stuff
    - if <[damager]> != null && <[damager].item_in_hand.script.name.starts_with[fort_pickaxe]||false>:
      - define damage 50
      - run fort_pic_handler.harvest def:<map[type=<[prop_hb].flag[fort.prop.material]>]>

    #this part would only fire if it's either by hand, or pickaxe (ill let hands destroy too, whatever)
    #if check in case damage was already defined by pickaxe
    - define damage <context.damage> if:!<[damage].exists>

    #-run breaking stuff
    - run fort_prop_handler.damage_prop def:<map[prop_hb=<[prop_hb]>;damage=<[damage]>]>

    on player right clicks block with:fort_prop_*:
    - determine passively cancelled
    - ratelimit <player> 1t
    - define i   <context.item>
    - define loc <context.location.above.center||null>

    - if <[loc]> == null || <[loc].material.name> != air:
      - narrate "<&c>Invalid spot."
      - stop

    #- define yaw <player.eye_location.yaw>
    #angle snapping
    - define yaw <map[North=180;Northeast=-135;East=-90;West=90;Northwest=135;South=0;Southeast=-45;Southwest=45].get[<player.eye_location.direction>]>
    - define angle <[yaw].to_radians>
    - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

    #so itll always use the data from the actual SCRIPT and not the i
    - define default_i     <[i].script.name.as[item]>
    - define cmd           <[default_i].custom_model_data>
    - define scale         <[default_i].flag[scale]||1,1,1>
    #- define scale         1,1,1
    - define translation   <[default_i].flag[translation]||0,0,0>
    #- define translation   0,0,0

    - define model_loc <[loc]>

    #not using <[i]>, because it would store unecessary extra data
    - define item <item[gold_nugget].with[custom_model_data=<[cmd]>;flag=scale:<[scale].as[location]>]>
    - spawn ITEM_DISPLAY[item=<[item]>;scale=<[scale]>;left_rotation=<[left_rotation]>;translation=<[translation]>] <[model_loc]> save:prop
    - define prop_model <entry[prop].spawned_entity>

    #- spawn INTERACTION[height=1.31;width=1.15] <[model_loc].below[0.5]> save:prop_hitbox
    - spawn INTERACTION[height=<[default_i].flag[hitbox.height]>;width=<[default_i].flag[hitbox.width]>] <[model_loc].below[0.5]> save:prop_hitbox
    - define prop_hb <entry[prop_hitbox].spawned_entity>

    - define placed_on <context.location>
    - if <[placed_on].has_flag[build.center]>:
      - define center_attached_to <[placed_on].flag[build.center]>
      - flag <[center_attached_to]> build.attached_props:->:<[prop_hb]>

    - if <[i].has_flag[barrier]>:
      - define height <[prop_hb].height.round>
      - repeat <[height]>:
        - define barrier_loc <[prop_hb].location.above[<[value].sub[1]>]>
        - modifyblock <[barrier_loc]> barrier
        - flag <[barrier_loc]> fort.prop.hitbox:<[prop_hb]>
        - flag <[prop_hb]> fort.prop.barriers:->:<[barrier_loc]>
      #-barriers around the bed
      - if <[i].script.name.after_last[_]> == bed:
        - define hb_loc <[prop_hb].location>
        - define around <list[<[hb_loc].left>|<[hb_loc].right>|<[hb_loc].forward_flat>|<[hb_loc].backward_flat>|<[hb_loc].forward_flat.left>|<[hb_loc].forward_flat.right>|<[hb_loc].backward_flat.left>|<[hb_loc].backward_flat.right>]>
        - foreach <[around]> as:barrier_loc:
          - modifyblock <[barrier_loc]> barrier
          - flag <[barrier_loc]> fort.prop.hitbox:<[prop_hb]>
          - flag <[prop_hb]> fort.prop.barriers:->:<[barrier_loc]>
    - flag <[model_loc]> fort.prop.hitbox:<[prop_hb]>

    - flag <[prop_hb]> fort.prop.loc:<[model_loc]>
    - flag <[prop_hb]> fort.prop.model:<[prop_model]>
    - flag <[prop_hb]> fort.prop.material:<[default_i].flag[material]>
    - flag <[prop_hb]> fort.prop.health:<[default_i].flag[health]>
    - flag <[prop_hb]> fort.prop.name:<[i].script.name.after[fort_prop_]>
    - flag <[prop_hb]> fort.prop.attached_center:<[center_attached_to]> if:<[center_attached_to].exists>

    - flag <[loc].world> fort.props:->:<[model_loc]>

    - narrate "<&a>Set <[i].display> at <&f><[loc].simple>"

  damage_prop:
    - define prop_hb    <[data].get[prop_hb]>
    - define prop_model <[prop_hb].flag[fort.prop.model]>
    - define mat_type   <[prop_hb].flag[fort.prop.material]>
    - define health     <[prop_hb].flag[fort.prop.health]>
    - define damage     <[data].get[damage]>

    - define fx_loc <[prop_model].location.add[<[prop_model].translation>]>
    - definemap mat_data_list:
        wood:
          special_data: OAK_PLANKS
          sound: BLOCK_CHERRY_WOOD_HIT
          pitch: 1.4
        brick:
          special_data: BRICKS
          #bone blocks work too
          sound: BLOCK_MUD_BRICKS_STEP
          pitch: 0.9
        metal:
          special_data: IRON_BARS
          sound: BLOCK_NETHERITE_BLOCK_HIT
          pitch: 1.3
    - define mat_data <[mat_data_list].get[<[mat_type]>]>

    - if <[health]> == unbreakable:
      - playsound <[prop_hb].location> sound:BLOCK_STONE_BREAK pitch:2
      - playeffect effect:BLOCK_CRACK at:<[fx_loc]> offset:0.1 special_data:<[mat_data].get[special_data]> quantity:10 visibility:30
      - stop

    - run fort_prop_handler.damage_anim def:<map[prop_model=<[prop_model]>;mat_type=<[mat_type]>]>
    - define new_health <[health].sub[<[damage]>]>

    #remove the health display
    - flag player fort.build_health:!
    #-break it
    - if <[new_health]> <= 0:
      - run fort_prop_handler.break def:<map[prop_hb=<[prop_hb]>]>
      - stop

   # - define yaw <map[North=0;South=180;West=-90;East=90].get[<player.location.yaw.simple>]>
    - define health_display_loc <[prop_hb].flag[fort.prop.loc].below[0.85]>
    - run fort_pic_handler.display_build_health def:<map[is_prop=true;tile_center=<[health_display_loc]>;health=<[new_health]>;max_health=<item[fort_prop_<[prop_hb].flag[fort.prop.name]>].flag[health]>]>

    - playeffect effect:BLOCK_CRACK at:<[fx_loc]> offset:0.1 special_data:<[mat_data].get[special_data]> quantity:10 visibility:30
    - playsound <[fx_loc]> sound:<[mat_data].get[sound]> pitch:<[mat_data].get[pitch]>

    - flag <[prop_hb]> fort.prop.health:<[new_health]>

  damage_anim:
    - define prop_model <[data].get[prop_model]>
    - define scale      <[prop_model].item.flag[scale]>

    - adjust <[prop_model]> interpolation_start:0
    - adjust <[prop_model]> scale:<[scale].add[0.08,0.08,0.08]>
    - adjust <[prop_model]> interpolation_duration:2t

    - wait 2t

    - stop if:!<[prop_model].is_spawned>
    - adjust <[prop_model]> interpolation_start:0
    - adjust <[prop_model]> scale:<[scale]>
    - adjust <[prop_model]> interpolation_duration:2t

  break:
    - define prop_hb    <[data].get[prop_hb]>
    - define prop_model <[prop_hb].flag[fort.prop.model]>
    - define mat_type   <[prop_hb].flag[fort.prop.material]>
    - definemap mat_data_list:
        wood:
          special_data: OAK_PLANKS
          sound: BLOCK_CHERRY_WOOD_BREAK
          pitch: 1.3
        brick:
          special_data: BRICKS
          sound: BLOCK_MUD_BRICKS_BREAK
          pitch: 1.2
        metal:
          special_data: IRON_BARS
          sound: BLOCK_NETHERITE_BLOCK_BREAK
          pitch: 1.2
    - define mat_data <[mat_data_list].get[<[mat_type]>]>
    - define fx_loc <[prop_model].location.add[<[prop_model].translation>]>

    #have this flag just in case i wanted to check if the prop is broken in the future
    - flag <[prop_hb].flag[fort.prop.loc]> fort.prop.broken

    - if <[prop_hb].has_flag[fort.prop.barriers]>:
      - define barrier_locs <[prop_hb].flag[fort.prop.barriers]>
      - flag <[barrier_locs]> fort:!
      - modifyblock <[barrier_locs]> air

    - playsound <[fx_loc]> sound:<[mat_data].get[sound]> pitch:<[mat_data].get[pitch]>
    - playeffect effect:BLOCK_CRACK at:<[fx_loc]> offset:0.3 special_data:<[mat_data].get[special_data]> quantity:25 visibility:30
    #no need to remove attached centers flag from attached center, since it'll check if it's spawned or not
    - remove <[prop_model]>|<[prop_hb]>

fort_prop_bookshelf:
  type: item
  material: gold_nugget
  display name: Bookshelf
  mechanisms:
    custom_model_data: 24
    hides: ALL
  flags:
    material: wood
    health: 50
    translation: 0,0.797,0
    barrier: true
    hitbox:
      height: 2.4
      width: 1.5

fort_prop_bookshelf_small:
  type: item
  material: gold_nugget
  display name: Small Bookshelf
  mechanisms:
    custom_model_data: 25
    hides: ALL
  flags:
    material: wood
    health: 50
    translation: 0,0.797,0
    barrier: true
    hitbox:
      height: 1.4
      width: 1.5

fort_prop_rack:
  type: item
  material: gold_nugget
  display name: Rack
  mechanisms:
    custom_model_data: 26
    hides: ALL
  flags:
    material: metal
    health: 120
    scale: 1.5,1.3,1.5
    translation: 0,0.88,0
    barrier: true
    hitbox:
      height: 2.2
      width: 1.5

fort_prop_closet:
  type: item
  material: gold_nugget
  display name: Closet
  mechanisms:
    custom_model_data: 27
    hides: ALL
  flags:
    material: wood
    health: 50
    translation: 0,0.797,0
    barrier: true
    hitbox:
      height: 2.4
      width: 1.5

fort_prop_red_chair:
  type: item
  material: gold_nugget
  display name: Red Chair
  mechanisms:
    custom_model_data: 28
    hides: ALL
  flags:
    material: wood
    health: 50
    translation: 0,-0.09,0
    scale: 0.8,0.8,0.8
    hitbox:
      height: 1.3
      width: 1.05

fort_prop_television:
  type: item
  material: gold_nugget
  display name: Television
  mechanisms:
    custom_model_data: 29
    hides: ALL
  flags:
    material: wood
    health: 50
    scale: 0.8,0.8,0.8
    barrier: true
    translation: 0,-0.1,0
    hitbox:
      height: 1.3
      width: 1.1

fort_prop_refrigerator:
  type: item
  material: gold_nugget
  display name: Refrigerator
  mechanisms:
    custom_model_data: 30
    hides: ALL
  flags:
    material: brick
    health: 120
    scale: 1.1,1.1,1.1
    translation: 0,0.46,0
    barrier: true
    hitbox:
      height: 1.95
      width: 1.1

fort_prop_toilet:
  type: item
  material: gold_nugget
  display name: Toilet
  mechanisms:
    custom_model_data: 31
    hides: ALL
  flags:
    material: brick
    health: 150
    scale: 1.25,1.25,1.25
    hitbox:
      height: 1.55
      width: 1.2

fort_prop_bathtub:
  type: item
  material: gold_nugget
  display name: Bathtub
  mechanisms:
    custom_model_data: 32
    hides: ALL
  flags:
    material: brick
    health: 75
    scale: 0.85,0.85,0.85
    hitbox:
      height: 0.9
      width: 2

fort_prop_couch:
  type: item
  material: gold_nugget
  display name: Couch
  mechanisms:
    custom_model_data: 33
    hides: ALL
  flags:
    material: wood
    health: 50
    translation: 0,-0.09,0
    scale: 0.8,0.8,0.8
    hitbox:
      height: 1.3
      width: 2.1

fort_prop_bed:
  type: item
  material: gold_nugget
  display name: Bed
  mechanisms:
    custom_model_data: 34
    hides: ALL
  flags:
    material: wood
    health: 120
    barrier: true
    hitbox:
      #added .01 because barriers get in the way
      height: 1.01
      width: 3.01

fort_prop_tires:
  type: item
  material: gold_nugget
  display name: Tires
  mechanisms:
    custom_model_data: 35
    hides: ALL
  flags:
    material: metal
    health: unbreakable
    scale: 1.25,1.25,1.25
    barrier: true
    hitbox:
      height: 1
      width: 1.5

#-custom barrier block system for open/closed shipments
fort_prop_shipment_open:
  type: item
  material: gold_nugget
  display name: Shipment
  mechanisms:
    custom_model_data: 36
    hides: ALL
  flags:
    material: metal
    health: 600
    scale: 1.25,1.25,1.25
    hitbox:
      height: 1
      width: 1.5

fort_prop_shipment_closed:
  type: item
  material: gold_nugget
  display name: Shipment
  mechanisms:
    custom_model_data: 36
    hides: ALL
  flags:
    material: metal
    health: 600
    scale: 1.25,1.25,1.25
    hitbox:
      height: 1
      width: 1.5

##temp models to add:
#-bed
#-crates (an open, and unopened one) (not yet)