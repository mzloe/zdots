mainMod = "ALT" -- Sets "ALT" key as main modifier
secondMod = "SUPER"

---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
terminal = "ghostty"
fileManager = "thunar"
mainBrowser = "brave-origin"
secondBrowser = "zen-browser"
launcher = "rofi -show drun"
runner = "rofi -show run"

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
