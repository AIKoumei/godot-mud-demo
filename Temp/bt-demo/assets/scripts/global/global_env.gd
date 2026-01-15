extends Node

# settings

var Debug = {
	"verbose":true
}


enum Teams  {
	__Empty__
	,Player
	,Enemy
	,Wall
}
var TeamNames = {
	Teams.__Empty__:"__Empty__"
	,Teams.Player:"Player"
	,Teams.Enemy:"Enemy"
	,Teams.Wall:"Wall"
}

var EntityKeyNames = {
	"teammates":"teammates"
	,"enemies":"enemies"
	# actor attribute
	,"alive_status":"alive_status"
}

var TeamTableForEachAsEnemy = {
	Teams.__Empty__:[]
	,Teams.Enemy:[Teams.Player]
	,Teams.Player:[Teams.Enemy]
}


enum STATIC_ActiveStatus {
	None
	,Active
	,Dead
	,Pause
	,Freaze
}


enum E_Direction {
	UP
	,DOWN
	,LEFT
	,RIGHT
}
