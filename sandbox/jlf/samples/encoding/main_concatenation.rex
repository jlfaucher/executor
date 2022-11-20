prompt directory off
demo on

t = "Joyeux"~text "Noel"
< include_concatenation_infos

t = "Joyeux"~text "Noël"
< include_concatenation_infos

t = "Joyeux" "Noel"~text
< include_concatenation_infos

t = "Joyeux" "Noël"~text
< include_concatenation_infos

t = "Joyeux"~text || " Noel"
< include_concatenation_infos

t = "Joyeux"~text || " Noël"
< include_concatenation_infos

t = "Joyeux" || " Noel"~text
< include_concatenation_infos

t = "Joyeux" || " Noël"~text
< include_concatenation_infos
