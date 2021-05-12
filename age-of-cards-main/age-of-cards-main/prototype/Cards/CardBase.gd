extends MarginContainer


# Declare member variables here. Examples:
onready var CardDatabase = preload("res://Assets/Cards/CardsDatabase.gd")
var Cardname = 'Mentor'
onready var CardInfo = CardDatabase.DATA[CardDatabase.get(Cardname)]
onready var CardImg = str("res://Assets/Cards/",CardInfo[0],"/",Cardname,".png")
var startpos = Vector2()
var targetpos = Vector2()
var startrot = 0
var targetrot = 0
var t = 0
var DRAWTIME = 1
var ORGANISETIME = 0.5
onready var Orig_scale = rect_scale
enum{
	InHand
	InPlay
	InMouse
	FocusInHand
	MoveDrawnCardToHand
	ReOrganiseHand
	MoveDrawnCardToDiscard
	MegaZoom
}

onready var Attack = (CardInfo[1])
onready var Retaliation = (CardInfo[2])
onready var Health = (CardInfo[3])
onready var Cost = (CardInfo[4])
onready var Name = (CardInfo[5])
onready var SpecialText = (CardInfo[6])
# Called when the node enters the scene tree for the first time.
func _ready():
#	print(CardInfo)
	var CardSize = rect_size
	$Border.scale *= CardSize/$Border.texture.get_size()
	$HighlightBorder.scale *= CardSize/$HighlightBorder.texture.get_size()
	$Card.texture = load(CardImg)
	$Card.scale *= CardSize/$Card.texture.get_size()
	$CardBack.scale *= CardSize/$CardBack.texture.get_size()
	$Focus.rect_scale *= CardSize/$Focus.rect_size
	
	
	$Bars/TopBar/Name/CenterContainer/Name.text = str(Name)
	$Bars/TopBar/Cost/CenterContainer/Cost.text = str(Cost)
	$Bars/SpecialText/Text/CenterContainer/Type.text = str(SpecialText)
	$Bars/BottomBar/Health/CenterContainer/Health.text = str(Health)
	$Bars/BottomBar/Attack/CenterContainer/AandR.text = str(Attack,'/',Retaliation)

# Called every frame. 'delta' is the elapsed time since the previous frame.
var MegaZooming = false
var MegaZoomInSize = 4
var state = InHand
var setup = true
var startscale = Vector2()
var Cardpos = Vector2()
var ZoomInSize = 2
var ZOOMINTIME = 0.2
var ReorganiseNeighbours = true
var NumberCardsHand = 0
var Card_Numb = 0
var NeighbourCard
var Move_Neightbour_Card_Check = false
var Zooming_In = true
var oldstate = INF
var CARD_SELECT = true
var INMOUSETIME = 0.1
var MovingtoInPlay = false
var targetscale = Vector2()
var DiscardPile = Vector2()
var MovingtoDiscard = false
###
onready var CardSlots = $'../../../CardSlots'
onready var CardSlotEmpty = $'../../../'.CardSlotEmpty
var CardSlotPos =  Vector2()
var CardSlotSize = Vector2()
var mousepos = Vector2()
var LeftHandSide = false
var CardInPlay = false
var ZoomInSizeInPlay = 1.2
var oldpos =  Vector2()
var oldscale = Vector2()
var Reparent = true # whether or not I can reparent this
###
var BaseTarget = []
var ListofTargets = []
var CardSlotNo = 0
var OtherCardsVis = false
var CanAttackBase = false
func FindTargets():
	CanAttackBase = false
	var NextRow = 1
	var NexRowCount = 1
	var EnemyinWay = false
	var StartorFinish = 0
	ListofTargets = []
	if LeftHandSide:
		NextRow = CardSlotNo + NexRowCount*$'../../../'.NumberRows
		StartorFinish = 2*$'../../../'.CardSlotsPerSide - 1
	else:
		NextRow = CardSlotNo - NexRowCount*$'../../../'.NumberRows
		StartorFinish = 0
	while NextRow >= 0 && NextRow <= 2*$'../../../'.CardSlotsPerSide - 1:
		if abs(NextRow - StartorFinish) <= $'../../../'.CardSlotsPerSide:
			if $'../../../'.CardSlotEmpty[NextRow] == false: # if enemy in square
				EnemyinWay = true
				ListofTargets.append($'../../../CardSlots'.get_child(NextRow).rect_position)
				ListofTargets.append(($'../../../CardSlots'.get_child(NextRow).rect_size)*($'../../../CardSlots'.get_child(NextRow).rect_scale))
				var ChildNumber = $'../../../'.FindCardsInPlayLog(NextRow,true)
				ListofTargets.append(ChildNumber)
				$'../../'.get_child(ChildNumber).get_node('CardBase').Make_Vis()
				OtherCardsVis = true
		NexRowCount += 1
		if LeftHandSide:
			NextRow = CardSlotNo + NexRowCount*$'../../../'.NumberRows
		else:
			NextRow = CardSlotNo - NexRowCount*$'../../../'.NumberRows
	if EnemyinWay == false:
		if LeftHandSide:
			BaseTarget = $'../../../Enemies/EnemyRight'
		else:
			BaseTarget = $'../../../Enemies/EnemyLeft'
		BaseTarget.Make_Vis()
		OtherCardsVis = true
		CanAttackBase = true
		ListofTargets.append(BaseTarget.rect_position)
		ListofTargets.append(BaseTarget.rect_size*BaseTarget.rect_scale)
		ListofTargets.append(INF)

func UndoMegaZoom():
	setup = true
	state = InPlay
	MovingtoInPlay = true
	targetpos = oldpos
	targetscale = oldscale
	$'../'.z_index -= 2

var FoundTargets = false
func _input(event):
	if event.is_action_released("rightclick"):
		if state == MegaZoom: # reset
			UndoMegaZoom()
		elif state == FocusInHand:
			if CardInPlay: # zoom in
				state = MegaZoom
				MegaZooming = true
				$'../'.z_index += 2
				setup = true
				targetpos = 0.5*(get_viewport().size - Orig_scale*rect_size*MegaZoomInSize)
	if event.is_action_pressed("leftclick"): # pick up card
		if state == MegaZoom: # reset
			mousepos = get_local_mouse_position()
			if mousepos.x < rect_size.x*rect_scale.x && mousepos.x > 0 \
				&& mousepos.y < rect_size.y*rect_scale.y && mousepos.y > 0: # my mouse is on the card
					state = InMouse
					targetscale = Vector2(CardSlotSize.y,CardSlotSize.x)/rect_size
					setup = true
					CARD_SELECT = false
					if CardInPlay:
						if FoundTargets == false:
							FindTargets()
							FoundTargets = true
			else:
				UndoMegaZoom()
		if state == FocusInHand:
			if CARD_SELECT:
	#					oldstate = state
				state = InMouse
				$'../'.z_index += 2
				setup = true
				CARD_SELECT = false
			if CardInPlay:
				if FoundTargets == false:
					FindTargets()
					FoundTargets = true
	if event.is_action_released("leftclick"):
		if CARD_SELECT == false:
			$'../'.z_index -= 2
			if oldstate == InHand || oldstate == ReOrganiseHand: # putting a card into a cardslot
				for i in range(CardSlots.get_child_count()):
					
					if CardSlotEmpty[i]:
						CardSlotPos = CardSlots.get_child(i).rect_position
						CardSlotSize = CardSlots.get_child(i).rect_size*CardSlots.get_child(i).rect_scale
						mousepos = get_global_mouse_position()
						if mousepos.x < CardSlotPos.x + CardSlotSize.x && mousepos.x > CardSlotPos.x \
							&& mousepos.y < CardSlotPos.y + CardSlotSize.y && mousepos.y > CardSlotPos.y:
								CardSlotEmpty[i] = false ###CardSlot now full
								$'../../../'.UpdateCardsInPlayLog(i,true)
								setup = true
								MovingtoInPlay = true
								if i < $'../../../'.CardSlotsPerSide:
									LeftHandSide = true
									targetrot = 90
									targetpos = CardSlotPos + Vector2(CardSlotSize.x,0)
								else:
									targetrot = -90
									targetpos = CardSlotPos + Vector2(0,CardSlotSize.y)
#										targetpos = CardSlotPos - $'../../../'.CardSize/2
								targetscale = Vector2(CardSlotSize.y,CardSlotSize.x)/rect_size
								state = InPlay
								CARD_SELECT = true
								CardInPlay = true ###
								CardSlotNo = i
								break
				if state != InPlay:
					setup = true
					targetpos = Cardpos
					targetscale = Orig_scale
					state = ReOrganiseHand
					CARD_SELECT = true
			else: # handle once the card is in play
				FoundTargets = false
				if OtherCardsVis:
					OtherCardsVis = false
					if CanAttackBase:
						BaseTarget.Make_InVis()
					else:
						for i in range($'../../'.get_child_count()):
							$'../../'.get_child(i).get_node('CardBase').Make_InVis()
				for i in range(ListofTargets.size()/3):
					mousepos = get_global_mouse_position()
					if mousepos.x < ListofTargets[3*i].x + ListofTargets[3*i + 1].x && mousepos.x > ListofTargets[3*i].x \
						&& mousepos.y < ListofTargets[3*i].y + ListofTargets[3*i + 1].y && mousepos.y > ListofTargets[3*i].y:
							if CanAttackBase == false:
								ChangeHealth($'../../'.get_child(ListofTargets[3*i + 2]).get_node('CardBase').Retaliation)
								$'../../'.get_child(ListofTargets[3*i + 2]).get_node('CardBase').ChangeHealth(Attack)
							else:
								BaseTarget.ChangeHealth(Attack)
				if Health > 0:
					if CARD_SELECT == false:
						setup = true
						MovingtoInPlay = true
						state = InPlay
						CARD_SELECT = true
						if CardInPlay:
							targetpos = oldpos
							targetscale = oldscale

func MoveCard(delta,state,timescale,targetpos,targetscale,targetrot):
	var Finished = false
	if setup:
		Setup()
		if state == InPlay:
			if Reparent:
				$'../../../'.ReParentCard(Card_Numb)
				Reparent = false
		elif state == FocusInHand:
			if CardInPlay == false:
				if ReorganiseNeighbours:
					ReorganiseNeighbours = false
					NumberCardsHand = $'../../../'.NumberCardsHand# offset for zeroth item
					if Card_Numb - 1 >= 0:
						Move_Neighbour_Card(Card_Numb - 1,true,1) # true is left!
					if Card_Numb - 2 >= 0:
						Move_Neighbour_Card(Card_Numb - 2,true,0.25)
					if Card_Numb + 1 <= NumberCardsHand:
						Move_Neighbour_Card(Card_Numb + 1,false,1)
					if Card_Numb + 2 <= NumberCardsHand:
						Move_Neighbour_Card(Card_Numb + 2,false,0.25)
		elif state == ReOrganiseHand:
			if Move_Neightbour_Card_Check:
				Move_Neightbour_Card_Check = false
	if t <= 1: # Always be a 1
		if state == ReOrganiseHand && CardInPlay == false:
			if ReorganiseNeighbours == false:
				ReorganiseNeighbours = true
				if Card_Numb - 1 >= 0:
					Reset_Card(Card_Numb - 1) # true is left!
				if Card_Numb - 2 >= 0:
					Reset_Card(Card_Numb - 2)
				if Card_Numb + 1 <= NumberCardsHand:
					Reset_Card(Card_Numb + 1)
				if Card_Numb + 2 <= NumberCardsHand:
					Reset_Card(Card_Numb + 2)
		rect_position = startpos.linear_interpolate(targetpos, t)
		rect_rotation = startrot * (1-t) + targetrot*t
		if state == MoveDrawnCardToHand:
			rect_scale.x = Orig_scale.x * abs(2*t - 1)
			if $CardBack.visible:
				if t >= 0.5:
					$CardBack.visible = false
		else:
			rect_scale = startscale * (1-t) + targetscale*t
		t += delta/float(timescale)
	else:
		rect_position = targetpos
		rect_rotation = targetrot
		rect_scale = targetscale
		Finished = true
		return Finished

func _physics_process(delta):
	match state:
		InHand:
			pass
		InPlay:
			if MovingtoInPlay:
				if MoveCard(delta,InPlay,INMOUSETIME,targetpos,targetscale,targetrot):
					MovingtoInPlay = false
		InMouse:
			MoveCard(delta,InMouse,INMOUSETIME,get_global_mouse_position() - $'../../../'.CardSize/2,Orig_scale,0)
				
		FocusInHand:
			if Zooming_In:
				if MoveCard(delta,FocusInHand,ZOOMINTIME,targetpos,targetscale,targetrot):
					Zooming_In = false
		MoveDrawnCardToHand: # animate from the deck to my hand
			if MoveCard(delta,MoveDrawnCardToHand,DRAWTIME,targetpos,Orig_scale,targetrot):
				state = InHand
		ReOrganiseHand:
			if MoveCard(delta,ReOrganiseHand,ORGANISETIME,targetpos,targetscale,targetrot):
				if CardInPlay:
					state = InPlay
				else:
					state = InHand
		MoveDrawnCardToDiscard:
			if MovingtoDiscard:
				if MoveCard(delta,MoveDrawnCardToDiscard,DRAWTIME,DiscardPile,Orig_scale,0):
					MovingtoDiscard = false
		MegaZoom:
			if MegaZooming:
				if MoveCard(delta,MegaZoom,ZOOMINTIME,targetpos,Orig_scale*MegaZoomInSize,0):
					MegaZooming = false

func Move_Neighbour_Card(Card_Numb,Left,Spreadfactor):
	NeighbourCard = $'../../'.get_child(Card_Numb).get_node('CardBase')
	if Left:
		NeighbourCard.targetpos = NeighbourCard.Cardpos - Spreadfactor*Vector2($'../../../'.CardSize.x/2,0)
	else:
		NeighbourCard.targetpos = NeighbourCard.Cardpos + Spreadfactor*Vector2($'../../../'.CardSize.x/2,0)
	NeighbourCard.setup = true
	NeighbourCard.state = ReOrganiseHand
	NeighbourCard.targetscale = Orig_scale
	NeighbourCard.Move_Neightbour_Card_Check = true
	
func Reset_Card(Card_Numb):
#	if NeighbourCard.Move_Neightbour_Card_Check:
#		NeighbourCard.Move_Neightbour_Card_Check = false
	if NeighbourCard.Move_Neightbour_Card_Check == false:
		NeighbourCard = $'../../'.get_child(Card_Numb).get_node('CardBase')
		if NeighbourCard.state != FocusInHand:
			NeighbourCard.state = ReOrganiseHand
			NeighbourCard.targetscale = Orig_scale
			NeighbourCard.targetpos = NeighbourCard.Cardpos
			NeighbourCard.setup = true

func Setup():
	startpos = rect_position
	startrot = rect_rotation
	startscale = rect_scale
	t = 0
	setup = false

func _on_Focus_mouse_entered():
	match state:
		InHand, ReOrganiseHand, InPlay:
			if CardInPlay == true:
				oldstate = InPlay # force this
				oldpos = targetpos
				oldscale = targetscale
				if LeftHandSide:
					targetpos = oldpos + CardSlotSize*0.5*(ZoomInSizeInPlay - 1)*Vector2(1,-1)
				else:
					targetpos = oldpos + CardSlotSize*0.5*(ZoomInSizeInPlay - 1)*Vector2(-1,1)
				setup = true
				Zooming_In = true
				state = FocusInHand
				targetscale = ZoomInSizeInPlay*Vector2(CardSlotSize.y,CardSlotSize.x)/rect_size
			else:
				oldstate = state
				setup = true
				targetpos.x = Cardpos.x - $'../../../'.CardSize.x/2
				targetpos.y = get_viewport().size.y - $'../../../'.CardSize.y*ZoomInSize
				Zooming_In = true
				state = FocusInHand
				targetrot = 0
				targetscale = Orig_scale*ZoomInSize


func _on_Focus_mouse_exited():
	match state:
		FocusInHand:
			setup = true
			state = ReOrganiseHand
			if CardInPlay:
				targetpos = oldpos
				targetscale = oldscale
			else:
				targetpos = Cardpos
				targetscale = Orig_scale

func Make_Vis():
	$HighlightBorder.visible = true

func Make_InVis():
	$HighlightBorder.visible = false

func ChangeHealth(Number):
	Health -= Number
	$Bars/BottomBar/Health/CenterContainer/Health.text = str(Health)
	if Health <= 0:
		setup = true
		MovingtoDiscard = true
		state = MoveDrawnCardToDiscard
		CardSlotEmpty[CardSlotNo] = true
		$'../../../'.UpdateCardsInPlayLog(CardSlotNo,false)
		
