extends Node2D

var screen := "menu"
var selected_mode := "solo"
var selected_game := 0
var game_names := [
 "Crystal Arena", "Lava Escape", "Turbo Race",
 "Ball Bash", "Skyfall Survival", "Treasure Hunt"
]
var game_desc := [
 "اجمع البلورات قبل منافسك",
 "اقفز بين المنصات وابتعد عن الحمم",
 "سباق ثلاثي الأبعاد ضد الوقت",
 "ادفع الكرة إلى منطقة التسجيل",
 "تفادى الأجسام الساقطة",
 "اعثر على الكنوز المخفية"
]
var colors := [Color("#22d3ee"),Color("#fb7185"),Color("#fbbf24"),Color("#a78bfa"),Color("#34d399"),Color("#f97316")]

func _draw():
 var s=get_viewport_rect().size
 draw_rect(Rect2(Vector2.ZERO,s),Color("#071329"))
 for i in range(22):
  draw_circle(Vector2(fposmod(i*139.0+Time.get_ticks_msec()*.005,s.x),fposmod(i*71.0,s.y)),2.5,Color(.2,.75,1,.2))
 if screen=="menu":
  draw_string(ThemeDB.fallback_font,Vector2(0,125),"PARTY LEGENDS",HORIZONTAL_ALIGNMENT_CENTER,s.x,62,Color.WHITE)
  draw_string(ThemeDB.fallback_font,Vector2(0,170),"عالم كامل من ألعاب التحدي ثلاثية الأبعاد",HORIZONTAL_ALIGNMENT_CENTER,s.x,25,Color("#72e6ff"))
  _button(Rect2(s.x*.18,275,s.x*.28,78),"لاعب واحد",Color("#0d9488"))
  _button(Rect2(s.x*.54,275,s.x*.28,78),"لاعبان محليًا",Color("#7655dc"))
  draw_string(ThemeDB.fallback_font,Vector2(0,460),"6 ألعاب ثلاثية الأبعاد • تحديات • بطولات • نقاط",HORIZONTAL_ALIGNMENT_CENTER,s.x,22,Color("#c5d2ee"))
 else:
  draw_string(ThemeDB.fallback_font,Vector2(0,65),"اختر لعبتك",HORIZONTAL_ALIGNMENT_CENTER,s.x,38,Color.WHITE)
  var cols=3
  var gap=16.0
  var w=minf(300.0,(s.x-80-gap*2)/3.0)
  var h=205.0
  var total=w*3+gap*2
  var start=(s.x-total)*.5
  for i in range(6):
   var row=i/3
   var col=i%3
   var rect=Rect2(start+col*(w+gap),105+row*(h+16),w,h)
   draw_rect(rect,Color("#203b62") if i==selected_game else Color("#142846"),true,15)
   draw_rect(Rect2(rect.position+Vector2(10,10),Vector2(w-20,7)),colors[i],true,4)
   draw_circle(rect.position+Vector2(w*.5,67),28,colors[i])
   draw_string(ThemeDB.fallback_font,rect.position+Vector2(0,125),game_names[i],HORIZONTAL_ALIGNMENT_CENTER,w,20,Color.WHITE)
   draw_string(ThemeDB.fallback_font,rect.position+Vector2(8,158),game_desc[i],HORIZONTAL_ALIGNMENT_CENTER,w-16,15,Color("#c5d2ee"))
  _button(Rect2(s.x*.35,s.y-65,s.x*.3,52),"ابدأ اللعب",Color("#0d9488"))
  _button(Rect2(18,s.y-65,130,48),"رجوع",Color("#475569"))
  draw_string(ThemeDB.fallback_font,Vector2(0,94),"الوضع: "+("لاعب واحد" if selected_mode=="solo" else "لاعبان محليًا"),HORIZONTAL_ALIGNMENT_CENTER,s.x,16,Color("#72e6ff"))

func _button(rect,label,color):
 draw_rect(rect,color,true,14)
 draw_string(ThemeDB.fallback_font,Vector2(rect.position.x,rect.position.y+rect.size.y*.64),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,22,Color.WHITE)

func _input(e):
 if not ((e is InputEventScreenTouch and e.pressed) or (e is InputEventMouseButton and e.pressed)): return
 var p=e.position
 var s=get_viewport_rect().size
 if screen=="menu":
  if Rect2(s.x*.18,275,s.x*.28,78).has_point(p): selected_mode="solo";screen="select"
  elif Rect2(s.x*.54,275,s.x*.28,78).has_point(p): selected_mode="local";screen="select"
 else:
  if Rect2(18,s.y-65,130,48).has_point(p):screen="menu"
  elif Rect2(s.x*.35,s.y-65,s.x*.3,52).has_point(p):
   get_tree().root.set_meta("party_mode",selected_mode)
   get_tree().root.set_meta("party_game",selected_game)
   get_tree().change_scene_to_file("res://scenes/arena_3d.tscn")
  else:
   var w=minf(300.0,(s.x-80-32)/3.0);var gap=16.0;var start=(s.x-(w*3+gap*2))*.5
   for i in range(6):
    var row=i/3;var col=i%3
    if Rect2(start+col*(w+gap),105+row*221,w,205).has_point(p):selected_game=i
 queue_redraw()
