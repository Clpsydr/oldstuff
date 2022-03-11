# old projects
A few projects from before 2014, both games and work related

## C# XAML photo measurement application

* MainWindow.xaml/editmode.cs : central window counting, controls, serialization, loading photos
* listscroll.xaml/cs	: side window with a list of measurements and photos in a model
* measure.cs		: class for a visual line object in central window
* view.cs		: class for a "model" view including set of measures and photos
* viewproxy.cs		: data structure for xml/xslt
* YesNoDialog.xaml/cs	: general dialog returning a boolean parameter
* InputDialog.xaml/cs	: general dialog window returning userinput text parameter

// mostly unused yet

* options.xaml		: settings UI
* config.cs 		: manages settings UI 

## Lua/Love2d
### Shocking

Topdown arcade with player having to connect facilities and avoid projectiles caused by his own network.

* main.lua                : main file, controls, announcements
* gameplay.lua            : gameloop
* citybuild.lua           : canvas that draws in buildings that are not participating
                            in the gameplay anymore
* calamity_class.lua      : projectile emitters
* bonus_class.lua         : pickup objects
* relay_class.lua         : energy relay towers
* spark_class.lua         : hostile projectiles
* facilities_class.lua    : building objects, including relay wires
* gameover.lua            : gameover screen gamestate
* hiscore.lua             : hiscore screen gamestate
* howto.lua               : help screen gamestate
* intro.lua               : intro screen gamestate
* transition.lua          : animation between gamestates and levels
* conf.lua                : love2d game definition file

### Skeletris

Just a tetris clone with fancy enemies and random blocks.

* main.lua            : main file, controls, announcements
* gameplay.lua        : gameloop definition
* gamover.lua         : gameoverstate behavior
* monsters.lua        : dynamic entities
* effects.lua         : effect entities
* block_class.lua     : block entities
* animations.lua      : visual effects for row removal
* conf.lua            : love2d game definition file

/// borrowed Love2D libraries
* gamestate.lua
* vector.lua
* timer.lua
* easing.lua





