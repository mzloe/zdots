MAIN_MOD = "ALT" -- Sets "ALT" key as main modifier
SECOND_MOD = "SUPER"

---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
TERMINAL = "ghostty"
FILE_MANAGER = "thunar"
MAIN_BROWSER = "brave-origin"
SECOND_BROWSER = "zen-browser"
LAUNCHER = "rofi -show drun"
RUNNER = "rofi -show run"

require("modules.monitors")
require("modules.keybinds")
require("modules.autostart")
require("modules.env")
require("modules.permissions")
require("modules.looknfeel")
require("modules.decorations")
require("modules.layout")
require("modules.animations")
require("modules.misc")
require("modules.input")
require("modules.windowrules")
require("modules.theme")
