extends Node3D

const GAME_NAMES=["CRYSTAL ARENA","LAVA ESCAPE","TURBO RACE","BALL BASH","SKYFALL SURVIVAL","TREASURE HUNT"]
var game_id=0
var local_mode=false
var players=[]
var pickups=[]
var hazards=[]
var scores=[0,0]
var timer=60.0
var ended=false
var rng=RandomNumberGenerator.new()
var hud:Label
var ball:RigidBody3D
var player_colors=[Color("#2dd4bf"),Color("#a78bfa")]
var jump_velocity=[0.0,0.0]
var grounded=[true,true]
var touch_vec=[Vector2.ZERO,Vector2.ZERO]
var touch_active=[false,false]
var race_laps=[0,0]
var goal_z=-8.0

func _ready():
 rng.randomize()
 game_id=int(get_tree().root.get_meta("party_game",0))
 local_mode=get_tree().root.get_meta("party_mode","solo")=="local"
 _make_environment()
 _make_arena()
 _make_players()
 _setup_game_objects()
 _make_camera()
 _make_hud()

func _make_environment():
 var env=WorldEnvironment.new()
 var e=Environment.new()
 e.background_mode=Environment.BG_COLOR
 e.background_color=Color("#08142a")
 e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color=Color("#a8c8ff")
 e.ambient_light_energy=.9
 env.environment=e
 add_child(env)
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-55,-25,0)
 light.light_energy=1.35
 add_child(light)

func _make_arena():
 var floor=MeshInstance3D.new()
 var fm=BoxMesh.new()
 fm.size=Vector3(18,.5,18)
 floor.mesh=fm
 floor.position=Vector3(0,-.3,0)
 var mat=StandardMaterial3D.new()
 mat.albedo_color=Color("#203c67")
 floor.material_override=mat
 add_child(floor)
 _wall(Vector3(0,1,-9),Vector3(18,2,.4),Color("#36547e"))
 _wall(Vector3(0,1,9),Vector3(18,2,.4),Color("#36547e"))
 _wall(Vector3(-9,1,0),Vector3(.4,2,18),Color("#36547e"))
 _wall(Vector3(9,1,0),Vector3(.4,2,18),Color("#36547e"))
 for i in range(5):
  var stripe=MeshInstance3D.new()
  var sm=BoxMesh.new()
  sm.size=Vector3(17,.03,.06)
  stripe.mesh=sm
  stripe.position=Vector3(0,-.02,-6.5+i*3.2)
  var mm=StandardMaterial3D.new()
  mm.albedo_color=Color("#2d5b88")
  stripe.material_override=mm
  add_child(stripe)

func _wall(p,s,c):
 var n=StaticBody3D.new()
 var mesh=MeshInstance3D.new()
 var box=BoxMesh.new()
 box.size=s
 mesh.mesh=box
 var m=StandardMaterial3D.new()
 m.albedo_color=c
 mesh.material_override=m
 n.add_child(mesh)
 var cs=CollisionShape3D.new()
 var sh=BoxShape3D.new()
 sh.size=s
 cs.shape=sh
 n.add_child(cs)
 n.position=p
 add_child(n)

func _make_players():
 _make_player(0,Vector3(-3,.85,3),player_colors[0])
 _make_player(1,Vector3(3,.85,3),player_colors[1])

func _make_player(idx,p,c):
 var body=CharacterBody3D.new()
 body.position=p
 body.name="Player"+str(idx+1)
 var mesh=MeshInstance3D.new()
 var cap=CapsuleMesh.new()
 cap.radius=.48
 cap.height=1.55
 mesh.mesh=cap
 var m=StandardMaterial3D.new()
 m.albedo_color=c
 m.metallic=.15
 m.roughness=.25
 mesh.material_override=m
 body.add_child(mesh)
 var head=MeshInstance3D.new()
 var sphere=SphereMesh.new()
 sphere.radius=.29
 sphere.height=.58
 head.mesh=sphere
 head.position.y=.83
 var hm=StandardMaterial3D.new()
 hm.albedo_color=Color("#ffe0bd")
 head.material_override=hm
 body.add_child(head)
 var cs=CollisionShape3D.new()
 var sh=CapsuleShape3D.new()
 sh.radius=.48
 sh.height=1.55
 cs.shape=sh
 body.add_child(cs)
 add_child(body)
 players.append(body)

func _setup_game_objects():
 match game_id:
  0,5:
   for i in range(18 if game_id==5 else 14): _spawn_pickup()
  1:
   _build_lava_course()
  2:
   _build_race_track()
  3:
   _build_ball()
   _make_goal(Vector3(0,.1,-7.8),Color("#34d399"))
   _make_goal(Vector3(0,.1,7.8),Color("#a78bfa"))
  4:
   for i in range(8): _spawn_hazard()

func _spawn_pickup():
 var n=Area3D.new()
 var mesh=MeshInstance3D.new()
 var sphere=SphereMesh.new()
 sphere.radius=.32
 sphere.height=.64
 mesh.mesh=sphere
 var m=StandardMaterial3D.new()
 m.albedo_color=Color("#fbbf24") if game_id==0 else Color("#fb923c")
 m.emission_enabled=true
 m.emission=Color("#a16207")
 mesh.material_override=m
 n.add_child(mesh)
 var cs=CollisionShape3D.new()
 var sh=SphereShape3D.new()
 sh.radius=.7
 cs.shape=sh
 n.add_child(cs)
 n.position=Vector3(rng.randf_range(-7,7),.65,rng.randf_range(-7,7))
 add_child(n)
 pickups.append(n)

func _build_lava_course():
 for i in range(7):
  var x=-6.0+i*2.0
  var platform=MeshInstance3D.new()
  var b=BoxMesh.new()
  b.size=Vector3(1.4,.5,1.5)
  platform.mesh=b
  platform.position=Vector3(x,.15,-i*1.7)
  var m=StandardMaterial3D.new()
  m.albedo_color=[Color("#38bdf8"),Color("#a78bfa"),Color("#f472b6")][i%3]
  platform.material_override=m
  add_child(platform)
 var lava=MeshInstance3D.new()
 var lm=BoxMesh.new()
 lm.size=Vector3(18,.2,18)
 lava.mesh=lm
 lava.position=Vector3(0,-1.3,0)
 var lmat=StandardMaterial3D.new()
 lmat.albedo_color=Color("#ef4444")
 lmat.emission_enabled=true
 lmat.emission=Color("#991b1b")
 lava.material_override=lmat
 add_child(lava)

func _build_race_track():
 for x in [-5.5,5.5]:
  _wall(Vector3(x,.4,0),Vector3(.25,.8,18),Color("#fbbf24"))
 for i in range(5):
  var gate=MeshInstance3D.new()
  var b=BoxMesh.new()
  b.size=Vector3(10,.12,.2)
  gate.mesh=b
  gate.position=Vector3(0,.15,-7+i*3.5)
  var m=StandardMaterial3D.new()
  m.albedo_color=Color("#f97316")
  gate.material_override=m
  add_child(gate)

func _build_ball():
 ball=RigidBody3D.new()
 ball.position=Vector3(0,.7,0)
 ball.mass=1.3
 var mesh=MeshInstance3D.new()
 var sphere=SphereMesh.new()
 sphere.radius=.65
 sphere.height=1.3
 mesh.mesh=sphere
 var m=StandardMaterial3D.new()
 m.albedo_color=Color("#fbbf24")
 m.metallic=.3
 mesh.material_override=m
 ball.add_child(mesh)
 var cs=CollisionShape3D.new()
 var sh=SphereShape3D.new()
 sh.radius=.65
 cs.shape=sh
 ball.add_child(cs)
 add_child(ball)

func _make_goal(p,c):
 var n=MeshInstance3D.new()
 var b=BoxMesh.new()
 b.size=Vector3(4,.15,.4)
 n.mesh=b
 n.position=p
 var m=StandardMaterial3D.new()
 m.albedo_color=c
 m.emission_enabled=true
 m.emission=c*.4
 n.material_override=m
 add_child(n)

func _spawn_hazard():
 var n=RigidBody3D.new()
 n.position=Vector3(rng.randf_range(-7,7),rng.randf_range(7,13),rng.randf_range(-7,7))
 n.gravity_scale=0.0
 n.freeze=true
 var mesh=MeshInstance3D.new()
 var b=BoxMesh.new()
 b.size=Vector3(rng.randf_range(.7,1.4),rng.randf_range(.7,1.4),rng.randf_range(.7,1.4))
 mesh.mesh=b
 var m=StandardMaterial3D.new()
 m.albedo_color=Color("#fb7185")
 mesh.material_override=m
 n.add_child(mesh)
 add_child(n)
 hazards.append(n)

func _make_camera():
 var cam=Camera3D.new()
 cam.position=Vector3(0,14,16)
 cam.rotation_degrees=Vector3(-48,0,0)
 add_child(cam)
 cam.current=true

func _make_hud():
 var layer=CanvasLayer.new()
 add_child(layer)
 hud=Label.new()
 hud.position=Vector2(18,14)
 hud.add_theme_font_size_override("font_size",22)
 hud.add_theme_color_override("font_color",Color.WHITE)
 layer.add_child(hud)
 _update_hud()

func _input(e):
 if ended:
  if (e is InputEventScreenTouch and e.pressed) or (e is InputEventMouseButton and e.pressed):
   get_tree().change_scene_to_file("res://scenes/main.tscn")
  return
 if e is InputEventScreenTouch:
  var idx=0 if e.position.x<get_viewport().size.x*.5 else 1
  touch_active[idx]=e.pressed
  if e.pressed: touch_vec[idx]=_touch_to_dir(e.position,idx)
 elif e is InputEventScreenDrag:
  var idx=0 if e.position.x<get_viewport().size.x*.5 else 1
  touch_vec[idx]=_touch_to_dir(e.position,idx)
 elif e is InputEventKey and e.pressed and e.keycode==KEY_SPACE:
  jump_velocity[0]=7.0

func _touch_to_dir(p,idx):
 var half=get_viewport().size.x*.5
 var local=Vector2(p.x-(0 if idx==0 else half),p.y)
 var center=Vector2(half*.5,get_viewport().size.y*.72)
 return (local-center).normalized()

func _process(d):
 if ended:return
 timer-=d
 for i in range(2):
  var active=(i==0 or local_mode)
  if not active: _move_ai(i,d); continue
  var dir=Vector2.ZERO
  if i==0:
   if Input.is_action_pressed("ui_left"):dir.x-=1
   if Input.is_action_pressed("ui_right"):dir.x+=1
   if Input.is_action_pressed("ui_up"):dir.y-=1
   if Input.is_action_pressed("ui_down"):dir.y+=1
  else:
   if Input.is_key_pressed(KEY_A):dir.x-=1
   if Input.is_key_pressed(KEY_D):dir.x+=1
   if Input.is_key_pressed(KEY_W):dir.y-=1
   if Input.is_key_pressed(KEY_S):dir.y+=1
  if touch_active[i]:dir=touch_vec[i]
  _move_player(i,dir,d)
 _game_rules(d)
 if timer<=0:timer=0;ended=true
 _update_hud()

func _move_ai(i,d):
 var target=Vector3.ZERO
 if game_id==0 or game_id==5:
  if pickups.size()>0:target=pickups[0].global_position
 elif game_id==3 and ball:target=ball.global_position
 else:target=Vector3(sin(Time.get_ticks_msec()*.0008+i)*4,0,-3)
 var delta=target-players[i].global_position
 _move_player(i,Vector2(delta.x,delta.z).normalized(),d)

func _move_player(i,dir,d):
 var p=players[i]
 var speed=7.0
 if game_id==2:speed=10.0
 if game_id==1:
  p.velocity.x=dir.x*speed
  p.velocity.z=dir.y*speed
  p.velocity.y-=18*d
  if p.is_on_floor():p.velocity.y=0
  if Input.is_action_just_pressed("ui_accept") or (touch_active[i] and abs(dir.y)>.8):p.velocity.y=7
  p.move_and_slide()
  if p.position.y < -1.0:
   p.position=Vector3(-3 if i==0 else 3,.9,3)
   scores[i]=maxi(0,scores[i]-1)
 else:
  p.position.x=clampf(p.position.x+dir.x*speed*d,-7.5,7.5)
  p.position.z=clampf(p.position.z+dir.y*speed*d,-7.5,7.5)

func _game_rules(d):
 match game_id:
  0,5:
   for j in range(pickups.size()-1,-1,-1):
    for i in range(2 if local_mode else 1):
     if players[i].global_position.distance_to(pickups[j].global_position)<1.0:
      scores[i]+=1
      pickups[j].queue_free()
      pickups.remove_at(j)
      _spawn_pickup()
      break
  1:
   for i in range(2):
    if players[i].position.z < -7.5:scores[i]+=1;players[i].position=Vector3(-3 if i==0 else 3,.9,3)
  2:
   for i in range(2):
    if players[i].position.z < -7.8:
     race_laps[i]+=1;scores[i]+=1;players[i].position.z=8.0
  3:
   if ball:
    for i in range(2 if local_mode else 1):
     var diff=ball.global_position-players[i].global_position
     if diff.length()<1.5:ball.apply_central_impulse(Vector3(diff.x,0,diff.z).normalized()*d*35)
    if ball.position.z < -7.5:
     scores[0]+=1;ball.position=Vector3(0,.7,0);ball.linear_velocity=Vector3.ZERO
    elif ball.position.z > 7.5:
     scores[1]+=1;ball.position=Vector3(0,.7,0);ball.linear_velocity=Vector3.ZERO
  4:
   for h in hazards:
    h.position.y-=d*5.5
    if h.position.y<-.5:
     h.position=Vector3(rng.randf_range(-7,7),rng.randf_range(8,13),rng.randf_range(-7,7))
    for i in range(2 if local_mode else 1):
     if players[i].global_position.distance_to(h.global_position)<1.1:
      scores[i]=maxi(0,scores[i]-1)
      h.position.y=0
 _update_hud()

func _update_hud():
 if hud==null:return
 var status=""
 if ended:
  var winner="تعادل" if scores[0]==scores[1] else ("اللاعب الأول فاز" if scores[0]>scores[1] else "اللاعب الثاني فاز")
  status="\\nانتهت الجولة — "+winner+"\\nاضغط الشاشة للعودة"
 else:
  status="\\nP1: الأسهم أو النصف الأيسر للمس"
  status+="\\nP2: WASD أو النصف الأيمن" if local_mode else "\\nأنت ضد خصم آلي"
 hud.text=GAME_NAMES[game_id]+"     الوقت: "+str(int(ceil(timer)))+"\\nP1: "+str(scores[0])+"    P2: "+str(scores[1])+status
