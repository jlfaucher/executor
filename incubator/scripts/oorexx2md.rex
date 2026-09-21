/*
Convert an ooRexx program to a Markdown file.
This Markdown file is intended to be transformed into HTML using md2html4xtr.
The ::class, ::method, ::attribute, ::constant and ::routine directives are preceded by a heading so that they appear in the HTML TOC.

Read from stdin, write to stdout.

Usage:
... | rexx scripts/oorexx2md > out.md && rexx scripts/md2html4xtr out.md
*/

.local~classDirective = ""

say "```rexx"

signal on notready

do forever
    line = .input~linein
    call titleize line
    .output~lineout(line)
end

notready:
say "```"

::routine titleize
    use strict arg line

    title = ""
    if line~startsWith("::") then do
        parse var line "::" directive name .

        titleLevel = .nil
        if directive~caselessEquals("CLASS") then titleLevel = 3
        else if directive~caselessEquals("METHOD") then titleLevel = 4
        else if directive~caselessEquals("ATTRIBUTE") then titleLevel = 4
        else if directive~caselessEquals("CONSTANT") then titleLevel = 4
        else if directive~caselessEquals("ROUTINE") then titleLevel = 3

        if .nil \== titleLevel then title = "#"~copies(titleLevel) directive name
    end

    if title \== "" then do
        .output~lineout("```")
        .output~lineout(title)
        .output~lineout("```rexx")

        if directive~caselessEquals("CLASS") then .local~classDirective = "::"directive name
        else if "OPTIONS REQUIRES RESOURCE ROUTINE"~caselessWordPos(directive) \== 0 then .local~classDirective = ""

        -- Workaround for rexx parser raising Error 99.905:  CLASS keyword on ::METHOD directive requires a matching ::CLASS directive.
        if "METHOD ATTRIBUTE CONSTANT"~caselessWordPos(directive) \== 0, .local~classDirective \== "" then .output~lineout(.local~classDirective)
    end