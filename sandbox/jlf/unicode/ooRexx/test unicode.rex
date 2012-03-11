-- coding=utf-8

sentences = .array~of(-
"Tomorrow morning I'll go to the countryside.",-
"Morgen früh werde ich in die Natur gehen.",-
"Demain matin, je vais aller à la campagne.",-
"غداً صباحاً سَأذهب إلى الرّيف",-
-
"Will you stay there long (a long time) ?",-
"Bleiben Sie dort lange (sehr lange) ?",-
"Resteras-tu là-bas longtemps (un long temps) ?",-
"هل ستبقى هناك وَقتاً طويلاً ؟",-
-
"Where will you Friday (the day on Friday) ?",-
"Wo wirst du Freitag (Tag am Freitag) ?",-
"Où seras-tu vendredi (le jour du vendredi) ?",-
"أين ستكون يومَ الجُمعة ؟"-
)

do s over sentences
    say s
end

-- http://www.columbia.edu/kermit/utf8.html
say
say "# English: The quick brown fox jumps over the lazy dog."
say "# Jamaican: Chruu, a kwik di kwik brong fox a jomp huova di liezi daag de, yu no siit?"
say "# Dutch: Pa's wĳze lynx bezag vroom het fikse aquaduct."
say "# German: Falsches Üben von Xylophonmusik quält jeden größeren Zwerg. (1)"
say "# German: Im finſteren Jagdſchloß am offenen Felsquellwaſſer patzte der affig-flatterhafte kauzig-höf‌liche Bäcker über ſeinem verſifften kniffligen C-Xylophon. (2)"
say "# Swedish: Flygande bäckasiner söka strax hwila på mjuka tuvor."
say "# Icelandic: Sævör grét áðan því úlpan var ónýt."
say "# Polish: Pchnąć w tę łódź jeża lub ośm skrzyń fig."
say "# Czech: Příliš žluťoučký kůň úpěl ďábelské kódy."
say "# Slovak: Starý kôň na hŕbe kníh žuje tíško povädnuté ruže, na stĺpe sa ďateľ učí kvákať novú ódu o živote."
say "# Greek (monotonic): ξεσκεπάζω την ψυχοφθόρα βδελυγμία"
say "# Greek (polytonic): ξεσκεπάζω τὴν ψυχοφθόρα βδελυγμία"
say "# Russian: Съешь же ещё этих мягких французских булок да выпей чаю."
say "# Russian: В чащах юга жил-был цитрус? Да, но фальшивый экземпляр! ёъ."
say "# Bulgarian: Жълтата дюля беше щастлива, че пухът, който цъфна, замръзна като гьон."
say "# Sami (Northern): Vuol Ruoŧa geđggiid leat máŋga luosa ja čuovžža."
say "# Hungarian: Árvíztűrő tükörfúrógép."
say "# Spanish: El pingüino Wenceslao hizo kilómetros bajo exhaustiva lluvia y frío, añoraba a su querido cachorro."
say "# Portuguese: O próximo vôo à noite sobre o Atlântico, põe freqüentemente o único médico."
say "# French: Les naïfs ægithales hâtifs pondant à Noël où il gèle sont sûrs d'être déçus et de voir leurs drôles d'œufs abîmés."
say "# Esperanto: Eĥoŝanĝo ĉiuĵaŭde."
say "# Hebrew: זה כיף סתם לשמוע איך תנצח קרפד עץ טוב בגן."
say "# Japanese (Hiragana):"
say "    いろはにほへど　ちりぬるを"
say "    わがよたれぞ　つねならむ"
say "    うゐのおくやま　けふこえて"
say "    あさきゆめみじ　ゑひもせず"
say

call interpret "multiByte"
call setCodePage 65001 -- UTF-8
call infodialog "éèöô alors ?"

::routine multiByte
s = "aé…"
say s 
say s~length
say s~mapC{return arg(1)~c2x" "}
say s~mapC{return arg(1)~c2x~x2b" "}

::routine interpret
    use strict arg routineName
    routine = .context~package~findRoutine(routineName)
    routineSource = routine~source
    do sourceline over routineSource
        if sourceline~strip~pos("--") == 1 then iterate
        if sourceline~strip == "" then say
        else do
            call charout , sourceline
            if sourceline~strip~pos("say") == 1 then call charout , " --> "
            else say
            interpret sourceline
        end
    end
    
::requires "extension/extensions.cls"
::requires "oodialog.cls"
