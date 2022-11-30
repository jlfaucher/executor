prompt off address directory
demo on

drop t
t = "Joyeux"~text "Noel"
< include_concatenation_infos s/$(text)/t/

drop t
t = "Joyeux"~text "Noël"
< include_concatenation_infos s/$(text)/t/

drop t
t = "Joyeux" "Noel"~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Joyeux" "Noël"~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Joyeux"~text || " Noel"
< include_concatenation_infos s/$(text)/t/

drop t
t = "Joyeux"~text || " Noël"
< include_concatenation_infos s/$(text)/t/

drop t
t = "Joyeux" || " Noel"~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Joyeux" || " Noël"~text
< include_concatenation_infos s/$(text)/t/
