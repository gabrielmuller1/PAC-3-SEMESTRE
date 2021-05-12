extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const CardSize = Vector2(125,175)*0.6
const CardBase = preload("res://Cards/CardBase.tscn")
const PlayerHand = preload("res://Cards/Player_Hand.gd")
const CardSlot = preload("res://Cards/CardSlot.tscn")
var CardSelected = []
onready var DeckSize = PlayerHand.CardList.size()
var CardOffset = Vector2()
onready var CentreCardOval = get_viewport().size * Vector2(0.5, 1.32)
onready var Hor_rad = get_viewport().size.x*0.45
onready var Ver_rad = get_viewport().size.y*0.3
var angle = 0
var Card_Numb = 0
var NumberCardsHand = -1
var CardSpread = 0.002*CardSize.x
var OvalAngleVector = Vector2()
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
# Called when the node enters the scene tree for the first time.
var CardSlotEmpty = []

var NumberColumns = 2 # per side (so 4 in total)
var NumberRows = 5
var CardSlotsPerSide = NumberColumns*NumberRows
onready var ViewPortSize = get_viewport().size
onready var OuterxMargin = ViewPortSize.x/50
onready var OuteryMargin = ViewPortSize.y/25
onready var MiddlexMargin = ViewPortSize.x/10
onready var CardZoneHeight = ViewPortSize.y - (CentreCardOval.y - CardSize.y - Ver_rad)# max height of card zone
onready var CardSlotyGaps = ViewPortSize.y/40
onready var CardSlotxGaps = ViewPortSize.x/40
onready var CardSlotBaseWidth =  ViewPortSize.x/9
onready var CardSlotTotalHeight = ViewPortSize.y - OuteryMargin - CardZoneHeight
onready var CardSlotTotalWidth = ViewPortSize.x/2 - OuterxMargin - MiddlexMargin/2 - CardSlotBaseWidth  ##### only for one side
onready var HeightforCard = (CardSlotTotalHeight - (NumberRows - 1)*CardSlotyGaps)/NumberRows
onready var WidthforCard = (CardSlotTotalWidth - (NumberColumns - 1)*CardSlotxGaps)/NumberColumns
func _ready():
	randomize()
	for i in range(2): # both sets of player
		for j in range(NumberColumns):
			for k in range(NumberRows):
				var NewSlot = CardSlot.instance()
				NewSlot.rect_size = Vector2(CardSize.y,CardSize.x)
				NewSlot.rect_scale *= (HeightforCard)/NewSlot.rect_size.y
				var SlotShift = (WidthforCard - NewSlot.rect_size.x*NewSlot.rect_scale.x)/2
				NewSlot.rect_position = Vector2(OuterxMargin + SlotShift + CardSlotBaseWidth,OuteryMargin) + k*Vector2(0,HeightforCard + CardSlotyGaps) \
					+ j*Vector2(CardSlotTotalWidth/NumberColumns,0) + i*Vector2(CardSlotTotalWidth + MiddlexMargin,0)
				
				$CardSlots.add_child(NewSlot)
				CardSlotEmpty.append(true)
	$Enemies/EnemyLeft.visible = true
	$Enemies/EnemyLeft/VBoxContainer/ImageContainer/Image.flip_h = true
	$Enemies/EnemyLeft.rect_scale *= CardSlotBaseWidth/$Enemies/EnemyLeft.rect_size.x
	$Enemies/EnemyLeft.rect_position = Vector2(OuterxMargin + CardSlotBaseWidth/2,CardSlotTotalHeight/2) \
		- $Enemies/EnemyLeft.rect_size*$Enemies/EnemyLeft.rect_scale/2
	$Enemies/EnemyRight.visible = true
	$Enemies/EnemyRight.rect_scale *= CardSlotBaseWidth/$Enemies/EnemyRight.rect_size.x
	$Enemies/EnemyRight.rect_position = Vector2(ViewPortSize.x - OuterxMargin - CardSlotBaseWidth/2,CardSlotTotalHeight/2) \
		- $Enemies/EnemyRight.rect_size*$Enemies/EnemyRight.rect_scale/2



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
onready var Deckposition = $Deck.position
onready var Discardposition = $Discard.position
func drawcard():
	angle = PI/2 + CardSpread*(float(NumberCardsHand)/2 - NumberCardsHand)
	var new_card = CardBase.instance()
	var TEMP = new_card.get_node("CardBase")
	CardSelected = randi() % DeckSize
	TEMP.Cardname = PlayerHand.CardList[CardSelected]
	TEMP.rect_position = Deckposition
	TEMP.DiscardPile = Discardposition
	TEMP.rect_scale *= CardSize/TEMP.rect_size
	TEMP.state = MoveDrawnCardToHand
	Card_Numb = 0
	$Cards.add_child(new_card)
	PlayerHand.CardList.erase(PlayerHand.CardList[CardSelected])
	angle += 0.25
	DeckSize -= 1
	NumberCardsHand += 1
	OrganiseHand()
	return DeckSize


func ReParentCard(CardNo):
	NumberCardsHand -= 1
	Card_Numb = 0
	var Card = $Cards.get_child(CardNo)
	$Cards.remove_child(Card)
	$CardsInPlay.add_child(Card)
	OrganiseHand()

func OrganiseHand():
	for Card in $Cards.get_children(): # reorganise hand
		angle = PI/2 + CardSpread*(float(NumberCardsHand)/2 - Card_Numb)
		OvalAngleVector = Vector2(Hor_rad * cos(angle), - Ver_rad * sin(angle))
		var TEMP = Card.get_node("CardBase")
		TEMP.targetpos = CentreCardOval + OvalAngleVector - Vector2(CardSize.x/2,CardSize.y)
		TEMP.Cardpos = TEMP.targetpos # card default pos
		TEMP.startrot = TEMP.rect_rotation
		TEMP.targetrot = (90 - rad2deg(angle))/4
		TEMP.Card_Numb = Card_Numb
		Card_Numb += 1
		if TEMP.state == InHand:
			TEMP.setup = true
			TEMP.targetscale = TEMP.Orig_scale
			TEMP.state = ReOrganiseHand
			TEMP.startpos = TEMP.rect_position
		elif TEMP.state == MoveDrawnCardToHand:
			TEMP.t -= 0.1
			TEMP.startpos = TEMP.targetpos - ((TEMP.targetpos - TEMP.rect_position)/(1-TEMP.t))

var CardsInPlayLog = []
var ChildNumber = 0
func UpdateCardsInPlayLog(CardSlotNumber,Adding):
	if Adding:
		CardsInPlayLog.append(Vector2(ChildNumber,CardSlotNumber))
		ChildNumber += 1
	else:
		CardsInPlayLog.remove(FindCardsInPlayLog(CardSlotNumber,false))
func FindCardsInPlayLog(CardSlotNumber,ReturnCardNo):
	for i in range(CardsInPlayLog.size()):
		if CardsInPlayLog[i].y == CardSlotNumber:
			if ReturnCardNo:
				return CardsInPlayLog[i].x
			else:
				return i
			break
