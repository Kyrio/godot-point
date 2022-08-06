extends Control


const CARD_SCENE = preload("res://gui/installs/install_card.tscn")

@onready var cards := %Cards as Control
@onready var placeholder := %Placeholder as Control


func _ready():
    refresh_list()
    InstallManager.registered.connect(_on_registered)
    InstallManager.unregistered.connect(_on_unregistered)


func _on_registered(_version_name: String, _module_config: Release.ModuleConfig):
    refresh_list()


func _on_unregistered(_version_name: String, _module_config: Release.ModuleConfig):
    refresh_list()


func refresh_list():
    var child_count = cards.get_child_count()

    for i in child_count:
        cards.get_child(i).queue_free()
    
    for version_name in InstallManager.get_installed_versions():
        var installs = InstallManager.get_installs(version_name)
        
        var install_card := CARD_SCENE.instantiate() as InstallCard
        install_card.version_name = version_name
        install_card.installs = installs
        cards.add_child(install_card)
        
    placeholder.visible = cards.get_child_count() == 0
