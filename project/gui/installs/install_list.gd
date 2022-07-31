extends Control


const CARD_SCENE = preload("res://gui/installs/install_card.tscn")

@onready var cards := %Cards as Control
@onready var placeholder := %Placeholder as Control


func _ready():
    refresh_list()


func refresh_list():
    var child_count = cards.get_child_count()

    for i in child_count:
        cards.get_child(i).queue_free()
    
    var installs = InstallManager.get_installs()
    
    for version in installs:
        var install_card := CARD_SCENE.instantiate() as InstallCard
        install_card.version_name = version
        install_card.installs = installs[version]
        cards.add_child(install_card)
        
    placeholder.visible = cards.get_child_count() == 0
