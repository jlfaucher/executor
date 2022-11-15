#!/usr/bin/rexx
/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2014 Rexx Language Association. All rights reserved.    */
/*                                                                            */
/* This program and the accompanying materials are made available under       */
/* the terms of the Common Public License v1.0 which accompanies this         */
/* distribution. A copy is also available at the following address:           */
/* http://www.oorexx.org/license.html                                         */
/*                                                                            */
/* Redistribution and use in source and binary forms, with or                 */
/* without modification, are permitted provided that the following            */
/* conditions are met:                                                        */
/*                                                                            */
/* Redistributions of source code must retain the above copyright             */
/* notice, this list of conditions and the following disclaimer.              */
/* Redistributions in binary form must reproduce the above copyright          */
/* notice, this list of conditions and the following disclaimer in            */
/* the documentation and/or other materials provided with the distribution.   */
/*                                                                            */
/* Neither the name of Rexx Language Association nor the names                */
/* of its contributors may be used to endorse or promote products             */
/* derived from this software without specific prior written permission.      */
/*                                                                            */
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS        */
/* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT          */
/* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS          */
/* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   */
/* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,      */
/* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   */
/* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,        */
/* OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY     */
/* OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    */
/* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS         */
/* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.               */
/*                                                                            */
/*----------------------------------------------------------------------------*/
/******************************************************************************/
/*  usepipe.rex         Open Object Rexx Samples                              */
/*                                                                            */
/*  Show samples usage of the pipeline implementation in pipe.rex             */
/*                                                                            */
/*                                                                            */
/* -------------------------------------------------------------------------- */
/*                                                                            */
/*  Description:                                                              */
/*  This program demonstrates how one could use the pipes implemented in the  */
/*  pipe sample.                                                              */
/******************************************************************************/

say 
say
say
say 'welcome to the pipelines demo.'
say
say
say 'we will show some examples of how the classes defined in the pipe.rex ooRexx sample,'
say 'which is a partial implementation of IBM''s CMS Pipelines in rexx, could be put to use.'
say
say
say
say 'if you''d like the screen cleared each time an example has completed and you''ve pressed'
say 'ENTER to proceed to the next one, enter the word CLS below.'
say
say 'this may make watching the video easier on the eye, although it would prevent you from'
say 'scrolling back to look at earlier examples.'
say
say 'please enter CLS, or anything else, to start the demo.'

pull cls
cls = cls = 'CLS'

call syscls
call init

say
say 'a PIPELINE consists of a sequence of STAGES, which each produce or manipulate'
say 'records.'
say
say 'the stages are connected to one another by means of the "pipe" method |.'
say 'whitespace preceding or following the method name | is optional, as per usual.'
say
say 'a stage''s predecessor, if it has one, is called its PRIMARY INPUT STREAM, and'
say 'the stage''s successor, when present, is its PRIMARY OUTPUT STREAM.'
say
say 'processing starts with the first stage of the pipeline.'
say
say 'this stage will need to produce a series of records, and send them to its'
say 'primary output stream for further processing.'
say
say 'each stage then manipulates a record at a time, and sends the result to its'
say 'primary output stage, which can then edit the record again and send it along'
say 'itself, and so on.'
say
say 'our first example consists of a pipeline comprising two stages.'
say 
say 'the first one, LITERAL, produces data by transmitting a single literal string'
say 'to its primary output stream, in this case a CONS stage; LITERAL then signals'
say 'EOF (end-of-file) to the CONS stage.'
say
say 'CONS merely displays any input records it receives on the console, and then it'
say 'passes them on to its own primary output, if it has one.'
say
say 'so here''s our first pipeline. we run it by invoking the RUN method:'

call demonstrate '.literal[''Hello World!''] | .cons'

say 'other stages able to produce initial data include STEMSTAGE and ARRAYSTAGE.'
say
say 'when running as the first stage in a pipeline, they take the contents of an'
say 'ooRexx stem or array, and pump it into the pipeline.'
say
say 'to demonstrate STEMSTAGE, we first prepare a stem:'

call prepare 'myStem.1 = ''This is line 1'';',
  'myStem.2 = ''And this is line two''; myStem.0 = 2'

sample =  '.stemStage[myStem.] | .sort[''w-1 d''] | .term'

say 'we''ll run the following pipeline in a moment:'
say
say ' ' sample
say
say 'the STEMSTAGE stage will send the variables MYSTEM.1 through MYSTEM.N (where N ='
say 'MYSTEM.0 = 2) as separate records to its primary output stream.'
say
say 'SORT then sorts the records. sorting is done on a set of key fields one can'
say 'specify; the W-1 parameter we use here stands for the last word of the input'
say 'record; when no key fields are given, SORT uses the entire record as the key.'
say
say 'the D option tells SORT to do a descending sort, while A, or ASCENDING in full,'
say 'results in an ascending sort; A is the default.'
say
say 'finally, TERM (for terminal) is a synonym TSO users may prefer over CONS.'
say
say 'let''s now run this pipeline:'

call demonstrate sample

say 'next, we prepare an array to use in subsequent examples:'

call prepare 'array = .array~new'                   -- execute this ooRexx statement

say 'we fill this array using a cascade of LITERAL stages, followed by an ARRAYSTAGE.'
say
say 'LITERAL can also run as an intermediate stage. it will then output the literal'
say 'string given by its argument first, followed by any records it receives on its'
say 'primary input stream.'
say
say 'hence a sequence like ".literal[''a''] | .literal[''b''] | .literal[''c'']" produces'
say 'the records "c", "b", "a", in that order.'
say
say 'ARRAYSTAGE, when not the first stage in the pipeline, will store input records'
say 'into the array given by its argument, before forwarding them to its primary'
say 'output stream (if it has one).'
say
say 'the CONS stage is included here merely to show what will go into the array.'
say 'it passes all input records on to its primary output stream, the ARRAYSTAGE.'
say
say 'we now fill the array just created as just described:'

call demonstrate '.literal[''Couldn''''t put Humpty together again.''] |',
  '.literal[''All the king''''s horses and all the king''''s men''] |',
  '.literal[''Humpty Dumpty had a great fall.''] |',
  '.literal[''Humpty Dumpty sat on a wall,''] | .cons | .arrayStage[array]',,,,
  'say ''(now array~size ='' array~size'')'''

say 'next, we''ll run the following pipeline:'
say
say '  .arrayStage[array] | .locate[''5-10 /''''/''] | .stemStage[myStem.] | .reverse |,'
say '  .cons'
say
say 'LOCATE searches a field (by default, the entire record) for a string; here we'
say 'specify record positions 5 through 10; 5.6 (meaning SUBSTR(5,6)) would amount'
say 'to the same.'
say
say 'the string to locate should be specified as a DELIMITEDSTRING, that is,'
say 'delimited on the left and the right by a character (here "/") that does not'
say 'occur in the string. The string we use here is a single quote, which LOCATE'
say 'detects in positions 5-10 only in the final input record, "Couldn''t put'
say 'Humpty together again."'
say
say 'LOCATE discards any records NOT containing the string.'
say
say 'when a string is not provided, LOCATE passes only those records for which the'
say 'indicated field is not empty; e.g., ".locate[1]" would discard records which'
say 'don''t have any data in position 1, that is, null records.'
say
say 'STEMSTAGE, when not first in the pipeline, stores all records it receives in'
say 'the stem and then passes them on to its primary output stream; on completion,'
say 'as part of EOF processing, MYSTEM.0 will be set to the number of records that'
say 'were received by the STEMSTAGE.'
say
say 'the REVERSE stage reverses the records'' contents.'
say
say 'here goes:'

call demonstrate '.arrayStage[array] | .locate[''5-10 /''''/''] |',
  '.stemStage[myStem.] | .reverse | .cons',,,,
  'say ''(now myStem.0 ='' myStem.0 ''and myStem.1 contains "''myStem.1''")'''

say 'CONS and TERM can also run first in the pipeline; they will then read input'
say 'lines from the console, and send them down the pipeline.'
say
say 'a console null input line will cause CONS or TERM to terminate processing;'
say 'the null record is NOT sent to the primary output stream.'
say
say 'in this example, the first CONS stage will prompt you for input.'
say
say 'any strings you enter will be echoed by the second CONS, but ONLY if they are'
say 'accepted by the LOCATE, that is, when they contain an a, b, or c character,'
say 'either in uppercase or lowercase.'
say
say 'by entering a null line, you terminate the first CONS stage.'
say
say 'ANYCASE tells LOCATE to ignore case when looking for the string; ANYOF means'
say 'scanning for any character of the string, rather than the string itself.'
say
say 'so here''is the pipeline we run:'

say; say '(.cons | .locate[''anycase anyof /Abc/''] | .cons)~run'

--
-- here we cheat a little, and use BEGIN instead of RUN to execute the pipeline.
--
-- with RUN, the pipeline would run asynchronously, and we would not know that it
-- had completed so we could safely (non-prematurely) display the TRAILER line...
--
say; say header
(.cons | .locate['anycase anyof /Abc/'] | .cons)~begin  -- run synchronously
say trailer; say                                        -- show trailer
call pleaseEnter                                        -- and prompt for an Enter
--
-- note that BEGIN bypasses READY processing, which is essential for many stages.
-- so best use RUN in general.

say 'stage FILEIN can also produce records and run as a first stage; indeed, it'
say 'cannot run other than as a first stage. FILEIN simply reads lines from the'
say 'specified file, and sends them down the pipeline. On end of file, it signals'
say 'EOF to its primary output stage.'
say
say 'FILEOUT and FILEAPPEND, for which we will not provide examples, can be used'
say 'as the final stage in a pipeline, to save any resulting output.'
say
say 'The final stage in a pipeline will normally be a CONS, STEMSTAGE, ARRAYSTAGE,'
say 'FILEOUT, or FILEAPPEND. a pipeline such as ".filein[myfile]|.reverse" can of'
say 'course be run, but there wouldn''t be much point. (notice that multistream'
say 'pipelines, to be discussed later on, form an exception.)'
say
say 'FILEOUT and FILEAPPEND cannot run as first stage in a pipeline, but they may'
say 'have a primary output stream connected; in that event, apart from storing'
say 'their input records in the file, the records are also output on the primary'
say 'output stream.'
say
say 'BETWEEN accepts groups of input records, beginning with a record that starts'
say 'with the first string and ending with a record that starts with the second'
say 'string; both strings should be specified as DELIMITEDSTRINGs:'

call demonstrate '.fileIn[''pipe.rex''] | .between[''/::class fileIn/',
  '/::class fileOut/''] | .cons',,.5

say 'stages can have more than one output stream. this is common for so called'
say 'filter or selection stages, such as LOCATE and DROP; any records such a stage'
say 'rejects (does not send to its PRIMARY output stage) will be output on the'
say 'SECONDARY OUTPUT STREAM, so that those records may be processed after all.'
say
say 'besides a secondary outstream, a tertiary, quaternary, ... one may be set up.'
say
say 'to create an additional output stream, use the CONNECT method as shown below.'
say
say 'CMS Pipelines starts numbering streams at 0, so that 0 signifies the primary'
say 'output and 1 the secondary one; we adhere to this numbering convention.'
say
say 'one effectively constructs two pipelines: the one containing the stage for which'
say 'a secondary output stream is set up, and one that starts with that secondary'
say 'output stream. for the example we will run below, these pipelines are:'
say
say '  #1: .arrayStage[array] | dr | .chop[10] | .cons'
say '  #2: d2 | .cons'
say
say 'here, "dr" will be a DROP instance, and "d2" a secondary output stage for "dr".'
say 'the second pipeline will process any records rejected by the DROP stage.'
say
say 'DROP discards a number of input records. we will use .drop[''last 1''] here, to'
say 'select all records except the final one. DROP sends "discarded" records to its'
say 'secondary output stream, if connected, so that they are not necessarily lost.'
say
say 'CHOP truncates records after a specified column; the bits chopped off (even'
say 'when null) are sent to its secondary ouput stream (not used here). in this'
say 'example, in view of the DROP, only the last entry of the input array will'
say 'escape the hands of CHOP.'
say
say 'let''s start by creating the DROP stage "dr" and its secondary output stage "d2":'

call prepare 'dr = .drop[''last 1''] -- "dr" drops the last input record = array entry;',
  'd2 = dr~connect(1,''o'') -- create a secondary output stream "d2" for "dr"'

say 'the pipelines are welded together by the + method, shown further down. this is'
say 'called a MULTISTREAM pipeline. the combined construction might be visualized as:'
say
say '                       +-----------------+'
say '                       +                 + --> primary output = a CHOP stage',
  '--> a CONS stage'
say '  ARRAYSTAGE stage --> + DROP stage "dr" +'
say '                       +                 + --> secondary output stage "d2"',
  '--> another CONS stage'
say '                       +-----------------+'
say
say 'ok, we now weld the two pipelines together using the + method, and run:'

call demonstrate '(.arrayStage[array] | dr | .chop[10] | .cons) +',
  '(d2 | .cons)',,.1

say 'a stage may also support more than one input stream; a case in point is FANINANY,'
say 'which simply transmits records it receives on any of its input streams to its'
say 'primary output stream, for common processing further down the line.'
say
say 'here is an example similar to the previous one, where FANINANY eliminates the need'
say 'for a second CONS - and indeed a third CONS to process the CHOP "offal".'
say
say 'using the CONNECT() method, we create a secondary output to CHOP, called "c2",'
say 'as well as secondary and tertiary input streams "f2" and "f3" for the FANINANY'
say 'stage we''ll call "fan".'
say
say 'we now do the necessary preparations (note that we recreate the DROP stage "dr",'
say 'because it has already been run and would require proper initialization before it'
say 'could be run again):'

call prepare 'dr = .drop[''last 1''] /* a DROP */; d2 = dr~connect(1,''o'') /* secondary out for "dr" */;',
  'ch = .chop[10] /* "ch" is a CHOP */; c2 = ch~connect(1,''o'') /* secondary out for "ch" */;',
  'fan = .faninany~new /* "fan" is a FANINANY stage */;',
  'f2 = fan~connect(1) /* connect secondary input */; f3 = fan~connect(2)',
  '/* and tertiary input for "fan" */'

say 'pipeline topology:'
say '                              +------+                                     +----------+'
say '                 +------+     +      +     CHOP''s 1out (primary output)    +          +'
say '                 +      + --> + CHOP +  ---------------------------------> + 1in      +'
say '                 +      +     + "ch" +                                     +          +'
say '  ARRAYSTAGE --> + DROP +     +      +  --> 2out = "c2" --> 2in = "f2" --> + FANINANY + --> CONS'
say '                 + "dr" +     +------+                                     +  "fan"   +'
say '                 +      +                                                  +          +'
say '                 +      + ------> 2out = "d2" -------> 3in = "f3" -------> + 3in      +'
say '                 +------+                                                  +----------+'
say
say 'this configuration will be realized by using a set of three pipelines, viz.:'
say
say '  #1: .arrayStage[array] | dr | ch | fan | .cons'
say '  #2: c2 | f2'
say '  #3: d2 | f3'
say
say 'now we''ll show and run the pipeline set described:'

call demonstrate '(.arrayStage[array] | dr | ch | fan | .cons) +',
  '(c2 | f2) + (d2 | f3)',,.1

say 'using method RUNTRACED instead of RUN produces an internal overview of the'
say 'pipeline topology, as well as a trace of events during pipeline execution.'
say
say
say 'press ENTER to demonstrate this. we will use the same pipeline set as in the'
say 'previous example. you will need to scroll back to see all of it.'
pull

call prepare 'dr = .drop[''last 1''] /* "dr" = drop the last input record */;',
  'd2 = dr~connect(1,''o'') /* connect secondary outstream "d2" for "dr" */;',
  'ch = .chop[10] /* "ch" = chop after position 10 */;',
  'c2 = ch~connect(1,''o'') /* "c2" = secondary out for the CHOP */;',
  'fan = .faninany~new /* "fan" is a FANINANY */;',
  'f2 = fan~connect(1) /* "f2" is secondary input for "fan" */;',
  'f3 = fan~connect(2) /* "f3" is tertiary input for "fan" */; say;',
  '((.arrayStage[array] | dr | ch | fan | .cons) + (c2 | f2) + (d2 | f3))~',
  'runTraced /* run and trace events */; call SysSleep .2 /* await completion */'

call pleaseEnter

say 'we touch upon a few other stages; for a full description of the syntax and'
say 'stage operations, refer to the IBM CMS Pipelines documentation; for the CMS'
say 'Pipelines stages the pipe.rex sample emulates, most of the original run-time'
say 'options are supported by pipe.rex as well.'
say
say 'to view a description of the SPEC stage, press Enter now. this will produce'
say 'more lines than will fit on a page, so please scroll back after Entering.'
say

call pleaseEnter

say 'SPEC is a very versatile stage, supporting multiple input and output streams.'
say
say 'its argument is a series of input plus output items; an INPUT item can be a'
say 'literal given by a DELIMITEDSTRING, or a section of any of the input records'
say 'SPEC has available on its connected input streams.'
say
say 'such sections are also used in LOCATE and many other stages, and they are called'
say 'INPUTRANGEs. they are of the form START-END or START.LENGTH or START;END (in'
say 'the latter case, START and/or END may be negative, which is interpreted as a'
say 'position relative to the end of the record; e.g., -1 is the last position of'
say 'the record, -2 the second to last, and so on).'
say 'to indicate a single column of the input record, END or LENGTH may be omitted.'
say
say 'the beginning and the end of a record may be specified as an asterisk, so that'
say 'e.g. *-* means the entire record and 5-* is the record from position 5 onwards.'
say
say 'of course, input records may not possess the requested positions, in which case'
say 'a null string results. null strings are NOT output. for example, .spec[''/A/ 1'
say '3-5 nw /B/ n''] (put an A in position 1, then input record positions 3 through 5'
say 'as the next word, that is, preceded by a blank, then a B at the next available'
say 'output position) will produce the string AB when presented with an input record'
say 'shorter than 3 bytes, because the 3-5 inputRange is empty and, as a result, the'
say 'requested preceding blank is also suppressed.'
say
say 'an inputRange may also be a range of WORDS, e.g. w2.3 (words 2 though 4) or w2'
say '(second word only), or a range of FIELDs, which are TAB delimited sections of'
say 'the record; records that begin or end with a TAB character are assumed to have'
say 'a null field preceding, resp. following the record; and two consecutive TABs'
say 'will delimit another field. so fields and words behave rather differently.'
say
say 'for example, the inputRange "fs 20 f1" (F1 = first field, using ''20''x, that is,'
say 'a blank, as field separator character instead of the default TAB = ''09''x) would,'
say 'when applied to a record " my word, such fields!" that begins with a blank,'
say 'produce a null string, whereas inputRange "w1" (first word, rather than first'
say 'field) would yield as result the string "my" when operating on the same input'
say 'record, even though the same separator character is being used.'
say
say 'further INPUT items are RECNO (the relative record number on the pertinent'
say 'input stream), and one or two others which we will not discuss here.'
say
say 'the OUTPUT item specifies where the input item should be placed in the output'
say 'record (for the output stream currently selected); this is coded as START (the'
say 'input item is placed starting at position START in the output record), as'
say 'START.LENGTH (starting at START, with the specified LENGTH, which may cause the'
say 'input item to be truncated or padded to the requested LENGTH), as N[.LENGTH] to'
say 'place the item at the next available (meaning unused) position in the output'
say 'record, optionally with an overriding LENGTH, as NW[.LENGTH] (output the item'
say 'as the next word; if LENGTH is used, it specifies the length in bytes), or as'
say 'NF[.LENGTH]: a TAB character is inserted in the output in front of the input item.'
say
say 'a padding character different from the default blank may be given as PAD xorc,'
say 'where xorc is an XORC, that is a character given by its hexadecimal representation'
say 'or by itself; e.g. "pad a" requests that padding is done using the letter "a",'
say 'while "pad 0a" requests ''0a''x as pad character. PAD remains in effect until'
say 'overridden by another PAD clause; BLANK and TAB are also recognized as valid XORCs.'
say
say 'note that the NW (next word) output specification always inserts a BLANK before'
say 'the input item (if it is not null), regardless of the active PAD setting.'
say
say 'when an output LENGTH is given (and also when not, although there would be no'
say 'effect), one can also request shorter input items to be aligned along the left'
say 'of the output field (this is the default), along the right, or centered, by'
say 'placing an L, an R, or a C after the output specification.'
say
say 'the input item can optionally be stripped or subjected to various conversions'
say 'before being processed by output processing, by coding STRIP, or a keyword that'
say 'indicates the desired conversion, between the input and output specifications;'
say 'for example, the input/output sequence "5-* c2b n.10 r" requests positions 5'
say 'through the end of the input record to be converted to binary, and placed at'
say 'the next unused position of the output buffer for a length of 10 bytes, right'
say 'aligned in cases where fewer than 10 bytes result.'
say
say 'TAKE is the converse of DROP; it takes the specified number of input records'
say 'and drops all remaining input (i.e., sends it to secondary out).'
say
say 'we now illustrate the use of SPEC and TAKE; note that the a''s of "alinea" are'
say 'interpreted as delimiters for a string "line"(!):'

call demonstrate '.arrayStage[array] | .spec[''alinea 1 recno strip nw.4 r',
  'w2-* nw w1 c2x nw''] | .cons | .take[3] | .stemStage[myStem.]',,,,
  'say ''(now myStem.0 ='' myStem.0 ''and myStem.1 contains "''myStem.1''")'''

say 'LOOKUP tries to match "detail" records (records on its primary input stream)'
say 'with "master" records (read from the secondary input stream); matched details'
say 'are passed to primary out, unmatched ones to secondary out, and unused master'
say 'records go to the tertiary output stream at the end of processing (EOF).'
say
say 'ANYCASE can be specified in order to ignore case when matching.'
say
say 'the master records are read in before any detail records are processed.'
say
say 'matching is done based on input keys, which may be different INPUTRANGEs in the'
say 'details and masters; a pad character (XORC) can be specified to pad shorter keys'
say 'to the right length, left aligned, but only if the key fields are of fixed length'
say '(so a key field "w3", the third word, would not be valid when PAD is in effect);'
say 'without PAD, the key fields taken from the detail and master records must be of'
say 'the same length for a match to be possible; that is, the "==" comparison method'
say 'is used.'
say
say 'the first key specified relates to the detail records; by default, it is the entire'
say 'record; if a second key is given, it pertains to the masters; if not, the input'
say 'range specified (or defaulted to) for the details is used for the masters also.'
say
say 'finally, although further options exist which we will not dwell upon here, one can'
say 'choose which records are sent to primary out: first the detail record followed by'
say 'the matching master (this is the default), the other way around, or only the detail'
say 'or only the matching master record.'
say
say 'the following example matches word 1 of detail records with word 3 of the masters,'
say 'writing both the detail and the matching master record to primary out in case of a'
say 'match; these are then combined by specMatched, a SPEC instance that uses the READ'
say 'keyword to discard the current input record and read the next one:'

call prepare 'lookup = .lookup[''w1 w3''] -- a LOOKUP stage;',
  'masters = lookup~connect(1,''i'') -- secondary input: the master records;',
  'specMatched = .spec[''/matched detail: "/ 1 1-* n /", matching master: "/ n read 1-* n /"/ n''];',
  'unMatchedDetails = lookup~connect(1,''o'') -- secondary output: unmatched details;',
  'unUsedMasters = lookup~connect(2,''o'') -- tertiary output: unused masters;',
  'faninany = .faninany~new -- a FANINANY;',
  'fin2 = faninany~connect(1,''i'') -- secondary input for faninany;',
  'fin3 = faninany~connect(2,''i'') -- tertiary input for faninany;'

call demonstrate '(.arrayStage[array] | lookup | specMatched | faninany | .cons) +',
  '(.arrayStage[array] | masters) +',
  '(unMatchedDetails | .spec[''/unmatched detail record: "/ 1 1-* n /"/ n''] | fin2) +',
  '(unUsedMasters | .spec[''/unused master record: "/ 1 1-* n /"/ n''] | fin3)',,.1

say 'the NOT stage takes a stage (or an entire pipeline) as argument, and swaps its'
say 'primary and secondary output stages.'
say
say 'typically, this is used with filter stages, to achieve the opposite effect; thus,'
say '.not[''.locate[''''2.5 any /abc/'''']''] will reject (i.e., send to secondary out)'
say 'any records that DO have an a, b or c in positions 2-6, and will send records that'
say 'don''t to the primary output stream; however, this can also be achieved by using'
say 'the "built-in" stage NLOCATE, the opposite of LOCATE: .nlocate[''2.5 any /abc/'']'
say
say 'below example uses NOT to recover the input record fragments discarded by a CHOP'
say 'without the overhead of setting up a secondary output stream for CHOP:'

call demonstrate '.arrayStage[array] | .not[.chop[10]] | .cons',,.2

say 'the LITERAL stage, when not first in the pipeline, will output the specified literal'
say 'first, followed by any records it receives on its primary input stream.'
say
say 'a similar effect is achieved by PREFACE, which runs a specified stage or pipeline,'
say 'traps and outputs its output, and then outputs any primary input records of its own.'
say
say 'the converse is APPEND, which we show here. this stage first copies all its input'
say 'records to primary out, and then runs the requested stage to produce additional'
say 'output.'
say
say 'note that PREFACE and APPEND will create an additional pipeline behind the scenes'
say '(this is revealed when RUNTRACED is used).'

call demonstrate '.arrayStage[array] | .append[.stemStage[myStem.]] | .cons',,.2

say 'PICK is a selection stage more powerful than LOCATE. basic searches are of two forms:'
say
say '  inputRange operator inputRange'
say '  inputRange operator delimitedString'
say
say 'here, the "operator" can be any one of ==, \==, <<=, <<, >>= and >>. PICK tests'
say 'whether the first operatand is in the relation given by the operator to the second'
say 'operand; e.g. with operator >>, PICK checks whether the first operand is strictly'
say 'larger than the second one in a string comparison.'
say
say 'basic searches may be combined using & (AND), | (OR) and \ (NOT), where NOT has the'
say 'highest precedence, followed by AND. use parentheses, which are mandatory for NOT,'
say 'to override the precedence rules, as you would in ooRexx.'
say
say 'PICK accepts only those input records that meet the combined tests.'
say
say 'the CHANGE stage can change records'' contents.'
say
say 'here is an example displaying both; first we issue some preliminary statements:'

call prepare 'pick = .pick[''2.5 == 9.5 & w-1 << /wall/ | \(1.1 == /H/ | 1.1 <<= /B/)''];',
  'pick2Out = pick~connect(1,''o''); faninany = .faninany~new; faninany2In = faninany~connect(1)'

say 'this PICK selects records in which positions 2-6 and 9-13 contain the same data and'
say 'the last word is strictly smaller than the string "wall", or those in which it is not'
say 'the case that the first position is an H or is less than or equal to B. the rejected'
say 'records go to secondary out, as usual, and will be subjected to a CHANGE.'
say
say 'CHANGE operation can be a bit particular, notably where ANYCASE is involved or when'
say 'the "needle" is a null string; please consult the CMS Pipelines documentation for the'
say 'details.'
say
say 'now for the pipeline set:'

call demonstrate '(.arrayStage[array] | pick | faninany | .cons) + (pick2Out |',
  '.change[''anycase /all/ /ill/''] | faninany2In)',,.1

say 'lastly, we mention the ZONE stage.'
say
say 'some selection stages, such as BETWEEN, look only at the INITIAL section of an input'
say 'record to decide whether or not to accept it (this contrasts with stages like LOCATE'
say 'and PICK, which can inspect any inputRange of a record).'
say
say 'ZONE simulates the operation of such stages on a requested inputRange.'
say
say 'ZONE requires two arguments: a string specifying an inputRange, and a .STAGE instance:'
say 'typically a filter stage such as BETWEEN or INSIDE (which, incidentally, works the same'
say 'way as BETWEEN, except that the first and the last records of each record group will be'
say 'suppressed).'
say
say 'ZONE will invoke the specified stage on the given inputRange for each of its input records;'
say 'records containing data accepted by the stage are sent to ZONE''s primary output stream,'
say 'while records for which the stage rejects the data are sent to ZONE''s secondary output'
say 'stream, provided it is connected.'
say
say 'here, we use ZONE to select groups of records, where a group starts with a record that'
say 'has a fourth word beginning with the letter a, and ends with a record having a fourth'
say 'word that begins with "hors":'

call demonstrate '.arrayStage[array] | .zone[''w4'', .between[''/a/ /hors/'']] | .term',,
  .false                                    -- no further calls to DEMONSTRATE will be made

say
say
say
say
say 'this is the end of the demonstration, thank you for your patience. happy piping!'
say
say
say
say '(to use pipelines in your ooRexx programs, include a "::REQUIRES ''pipe''" directive.)'
say

parse source source
if \source~caselessEndsWith('.rexp') then do      -- avoid a premature termination,
  .output~charOut('Press ENTER key to exit...')   -- and allow people to read the last page
  pull
  end

exit

----------------------------------------------------------------------------------------------------------

init:                                             -- set header and trailer line for pipeline output

header = copies('-',10) 'pipeline output:' copies('-',52)
trailer = copies('-',10) 'end of pipeline output' copies('-',46)
return

----------------------------------------------------------------------------------------------------------

prepare:                                          -- run preparatory Rexx instructions

use strict arg list                               -- a list of instructions
say
do while list \= ''
  parse var list statement ';' list               -- get an instruction
  interpret statement                             -- execute it
  say '(statement executed:' statement~strip')'   -- and display it
  end
say
return

----------------------------------------------------------------------------------------------------------

demonstrate:                                      -- demonstrate a sample pipeline

use strict arg definition, more = .true,,         -- pipeline definition, MORE flag,
  wait = .05, msg = ''                            -- WAIT time, optional result message

queue '('definition')'                            -- queue the pipeline set definition

(.stack|,                                         -- get definition from the stack
  .split['/+/']|,                                 -- show each pipeline on a separate line
  .spec['1-* 1 /+,/ n']|,                         -- put back the +, and append a comma
  .change['-3;-1 /)+,/)~run/']|,                  -- append ~RUN to the last line
  .spill['83 string /|/ keep']|,                  -- spill longer lines after a pipe character
  .change['-1 /|/|,/']|,                          -- add continuation comma
  .literal|,                                      -- send a null string ahead
  .term)~run                                      -- and output the definition to the terminal
call sysSleep .05                                 -- wait for this to complete

interpret 'pipeline =' definition                 -- create the pipeline

say; say header                                   -- display header
pipeline~run                                      -- then run the pipeline set
call sysSleep wait                                -- let it complete
say trailer                                       -- show trailer

if msg \== '' then do                             -- a result message is to be displayed
  say
  interpret msg                                   -- some result
  end

say; if more then call pleaseEnter                -- more pipeline examples follow
return

-------------------------------------------------------------------------------------------------------

pleaseEnter:

say '==> enter a null string to continue the sample, or anything else to quit'
pull string
if cls then call syscls                           -- clear screen if requested
say
if string == '' then return
exit

-------------------------------------------------------------------------------------------------------

::requires 'pipe'