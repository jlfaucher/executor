<link rel='stylesheet' href='https://jlfaucher.github.io/css/rexx-vim-light-zellner.css'>
<link rel='stylesheet' href='https://jlfaucher.github.io/css/markdown.css'>

Experimental ooRexx
===================

Miscellaneous notes:

- [Overview of changes][overview_changes]
- [Sandbox diary][sandbox_diary]
- [Sandbox notes][sandbox_notes]
- [Instructions to build Executor][build_executor]

Internal documentation:

- [Class index][internal_documentation_classes] 
- [File list][internal_documentation_files] 
- [Internal notes][internal_notes]

Artifacts from 2012:

- [DocMusings/transformxml][sourceforge_incubator_DocMusings_transformxml] provides a set of scripts to convert the ASCII railroads of the ooRexx documentation to [graphical syntax diagrams][doc].
- The experimental ooRexx interpreter implemented in [sandbox/jlf][sourceforge_sandbox_jlf] is described by this [pdf][slides] and can be downloaded [here][download].


Examples of extensions
----------------------

### Encoded strings, Unicode

Start working on a prototype for encoded strings.  
Main ideas explored with this prototype:
- The existing String class is kept unchanged, its methods are byte-oriented.
- The prototype adds a layer of services working at grapheme level, provided by the RexxText class.
- The RexxText class works on the bytes managed by the String class.
- String instances are immutable, the same for RexxText instances.
- No automatic conversion to Unicode by the interpreter.
- The strings crossing the I/O barriers are kept unchanged.
- Supported encodings : byte, UTF-8, UTF-16, UTF-32.

Prototype based on:
- [utf8proc][utf8proc]
- [uni-algo][uni_algo]

Notes about Unicode:
- [URLs with annotations][notes_unicode]
- [Thoughts on ooRexx and Unicode][thoughts_on_ooRexx_and_unicode]

Test cases:
- [Demo Unicode intro][demo_unicode_intro]
- [Demo Unicode checks][demo_unicode_checks]
- [Demo Unicode services][demo_unicode_services]
- [Demo Unicode String compatibility][demo_unicode_string_compatibility]
- [Demo Unicode String compatibility (no ~text)][demo_unicode_string_compatibility_auto_conv]      **🠄 NEW**
- [Examples from the sandbox diary and more][encoded_strings_diary_exemples]      **🠄 NEW**
- [Concatenation][encoded_strings_concatenation]
- [Transcoding][encoded_strings_transcoding]

### Named arguments

A positional argument list is a serie of optional expressions, separated by commas.

```rexx
    caller: put("one", 1)
    callee: use arg item, index -- order is important
```

<div id="rxfbc62d72eece" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-const rx-label">caller</span><span class="rx-spe">:</span><span class="rx-ws"> </span><span class="rx-const rx-ext-func">put</span><span class="rx-spe">(</span><span class="rx-str rx-oquo">"</span><span class="rx-str">one</span><span class="rx-str rx-cquo">"</span><span class="rx-spe">,</span><span class="rx-ws"> </span><span class="rx-int rx-ipart">1</span><span class="rx-spe">)</span></code>
<code lineno="2"><span class="rx-ws">    </span><span class="rx-const rx-label">callee</span><span class="rx-spe">:</span><span class="rx-ws"> </span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">item</span><span class="rx-spe">,</span><span class="rx-ws"> </span><span class="rx-var">index</span><span class="rx-ws"> </span><span class="rx-lncm">-- order is important</span>
</code></pre>
</div>

The position of each argument within the argument list identifies the corresponding
parameter in the parameter list of the routine/method being invoked.  
This is in contrast to named argument lists, where the correspondence between
argument and parameter is done using the parameter's name.

```rexx
    caller: put(index:1, item:"one")
    callee: use named arg item, index -- order is not important
```

<div id="rx8d7410376a2d" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-const rx-label">caller</span><span class="rx-spe">:</span><span class="rx-ws"> </span><span class="rx-const rx-ext-func">put</span><span class="rx-spe">(</span><span class="rx-const rx-argument-name">index</span><span class="rx-spe">:</span><span class="rx-int rx-ipart">1</span><span class="rx-spe">,</span><span class="rx-ws"> </span><span class="rx-const rx-argument-name">item</span><span class="rx-spe">:</span><span class="rx-str rx-oquo">"</span><span class="rx-str">one</span><span class="rx-str rx-cquo">"</span><span class="rx-spe">)</span></code>
<code lineno="2"><span class="rx-ws">    </span><span class="rx-const rx-label">callee</span><span class="rx-spe">:</span><span class="rx-ws"> </span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">named</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">item</span><span class="rx-spe">,</span><span class="rx-ws"> </span><span class="rx-var">index</span><span class="rx-ws"> </span><span class="rx-lncm">-- order is not important</span>
</code></pre>
</div>

Specification of named arguments: [spec][named_arguments_spec]  
Test cases of named arguments: [script][named_arguments_test_cases_script], [output][named_arguments_test_cases_output]

### Blocks (source literals)

A RexxBlock is a piece of source code surrounded by curly brackets.

#### Routine

```rexx
    {use arg name, greetings
     say "hello" name || greetings
    }~("John", ", how are you ?")       -- hello John, how are you ?
```

<div id="rxcfdb8312217b" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-spe">{</span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">name</span><span class="rx-spe">,</span><span class="rx-ws"> </span><span class="rx-var">greetings</span></code>
<code lineno="2"><span class="rx-ws">     </span><span class="rx-kw">say</span><span class="rx-ws"> </span><span class="rx-str rx-oquo">"</span><span class="rx-str">hello</span><span class="rx-str rx-cquo">"</span><span class="rx-op"> </span><span class="rx-var">name</span><span class="rx-ws"> </span><span class="rx-op">|</span><span class="rx-op">|</span><span class="rx-ws"> </span><span class="rx-var">greetings</span></code>
<code lineno="3"><span class="rx-ws">    </span><span class="rx-spe">}</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-str rx-oquo">"</span><span class="rx-str">John</span><span class="rx-str rx-cquo">"</span><span class="rx-spe">,</span><span class="rx-ws"> </span><span class="rx-str rx-oquo">"</span><span class="rx-str">, how are you ?</span><span class="rx-str rx-cquo">"</span><span class="rx-spe">)</span><span class="rx-ws">       </span><span class="rx-lncm">-- hello John, how are you ?</span>
</code></pre>
</div>

#### Coactivity

A coactivity remembers its internal state.  
It can be called several times, the execution is resumed after the last executed .yield[].

```rexx
    nextInteger = {::coactivity loop i=0; .yield[i]; end}
    say nextInteger~()                  -- 0
    say nextInteger~()                  -- 1
    nextInteger~makeArray(10)           -- [2,3,4,5,6,7,8,9,10,11]
    say nextInteger~()                  -- 12
    ...
```

<div id="rx66b90d408879" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-var">nextInteger</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-spe">{</span><span class="rx-dir">::</span><span class="rx-dkw">coactivity</span><span class="rx-ws"> </span><span class="rx-kw">loop</span><span class="rx-ws"> </span><span class="rx-var">i</span><span class="rx-asg">=</span><span class="rx-int rx-ipart">0</span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-env">.yield</span><span class="rx-spe">[</span><span class="rx-var">i</span><span class="rx-spe">]</span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">end</span><span class="rx-spe">}</span></code>
<code lineno="2"><span class="rx-ws">    </span><span class="rx-kw">say</span><span class="rx-ws"> </span><span class="rx-var">nextInteger</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-spe">)</span><span class="rx-ws">                  </span><span class="rx-lncm">-- 0</span></code>
<code lineno="3"><span class="rx-ws">    </span><span class="rx-kw">say</span><span class="rx-ws"> </span><span class="rx-var">nextInteger</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-spe">)</span><span class="rx-ws">                  </span><span class="rx-lncm">-- 1</span></code>
<code lineno="4"><span class="rx-ws">    </span><span class="rx-var">nextInteger</span><span class="rx-op">~</span><span class="rx-const rx-method">makeArray</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">10</span><span class="rx-spe">)</span><span class="rx-ws">           </span><span class="rx-lncm">-- [2,3,4,5,6,7,8,9,10,11]</span></code>
<code lineno="5"><span class="rx-ws">    </span><span class="rx-kw">say</span><span class="rx-ws"> </span><span class="rx-var">nextInteger</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-spe">)</span><span class="rx-ws">                  </span><span class="rx-lncm">-- 12</span></code>
<code lineno="6"><span class="rx-ws">    </span><span class="rx-env">...</span>
</code></pre>
</div>

#### Closure

A closure remembers the values of the variables defined in the outer environment of the block.  
Updating a variable from the closure will have no impact on the original context (closure by value).

```rexx
    v = 1
    closure = {expose v; say v; v += 10}    -- capture the value of v: 1
    v = 2
    closure~()                              -- display 1
    closure~()                              -- display 11
    closure~()                              -- display 21
    say v                                   -- v not impacted by the closure: 2
```

<div id="rx55e2747bf690" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-var">v</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-int rx-ipart">1</span></code>
<code lineno="2"><span class="rx-ws">    </span><span class="rx-var">closure</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-spe">{</span><span class="rx-kw">expose</span><span class="rx-ws"> </span><span class="rx-xvar">v</span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">say</span><span class="rx-ws"> </span><span class="rx-xvar">v</span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-xvar">v</span><span class="rx-ws"> </span><span class="rx-asg">+</span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-int rx-ipart">10</span><span class="rx-spe">}</span><span class="rx-ws">    </span><span class="rx-lncm">-- capture the value of v: 1</span></code>
<code lineno="3"><span class="rx-ws">    </span><span class="rx-xvar">v</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-int rx-ipart">2</span></code>
<code lineno="4"><span class="rx-ws">    </span><span class="rx-var">closure</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-spe">)</span><span class="rx-ws">                              </span><span class="rx-lncm">-- display 1</span></code>
<code lineno="5"><span class="rx-ws">    </span><span class="rx-var">closure</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-spe">)</span><span class="rx-ws">                              </span><span class="rx-lncm">-- display 11</span></code>
<code lineno="6"><span class="rx-ws">    </span><span class="rx-var">closure</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-spe">)</span><span class="rx-ws">                              </span><span class="rx-lncm">-- display 21</span></code>
<code lineno="7"><span class="rx-ws">    </span><span class="rx-kw">say</span><span class="rx-ws"> </span><span class="rx-xvar">v</span><span class="rx-ws">                                   </span><span class="rx-lncm">-- v not impacted by the closure: 2</span>
</code></pre>
</div>

### Blocks (examples)

#### Closures / Value capture

[Rosetta Code][rosetta_code_closures_value_capture]

```rexx
    a = .array~new
    do i=1 to 10
        a~append{expose i; return i*i}
    end
    do i=1 to 9
        say a[i]~()
    end
```

<div id="rxe9f118f26014" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-var">a</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-env">.array</span><span class="rx-op">~</span><span class="rx-const rx-method">new</span></code>
<code lineno="2"><span class="rx-ws">    </span><span class="rx-kw">do</span><span class="rx-ws"> </span><span class="rx-var">i</span><span class="rx-asg">=</span><span class="rx-int rx-ipart">1</span><span class="rx-ws"> </span><span class="rx-skw">to</span><span class="rx-ws"> </span><span class="rx-int rx-ipart">10</span></code>
<code lineno="3"><span class="rx-ws">        </span><span class="rx-var">a</span><span class="rx-op">~</span><span class="rx-const rx-method">append</span><span class="rx-spe">{</span><span class="rx-kw">expose</span><span class="rx-ws"> </span><span class="rx-xvar">i</span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-xvar">i</span><span class="rx-op">*</span><span class="rx-xvar">i</span><span class="rx-spe">}</span></code>
<code lineno="4"><span class="rx-ws">    </span><span class="rx-kw">end</span></code>
<code lineno="5"><span class="rx-ws">    </span><span class="rx-kw">do</span><span class="rx-ws"> </span><span class="rx-var">i</span><span class="rx-asg">=</span><span class="rx-int rx-ipart">1</span><span class="rx-ws"> </span><span class="rx-skw">to</span><span class="rx-ws"> </span><span class="rx-int rx-ipart">9</span></code>
<code lineno="6"><span class="rx-ws">        </span><span class="rx-kw">say</span><span class="rx-ws"> </span><span class="rx-var">a</span><span class="rx-spe">[</span><span class="rx-xvar">i</span><span class="rx-spe">]</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-spe">)</span></code>
<code lineno="7"><span class="rx-ws">    </span><span class="rx-kw">end</span>
</code></pre>
</div>

display:

    1
    4
    9
    16
    25
    36
    49
    64
    81

A more compact code... item is an implicit parameter.

```rexx
    1~10{ {expose item; return item * item} } ~ take(9) ~ each{ say item~() }
```

<div id="rx7ca28cd7bd03" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-int rx-ipart">1</span><span class="rx-op">~</span><span class="rx-const rx-method">10</span><span class="rx-spe">{</span><span class="rx-ws"> </span><span class="rx-spe">{</span><span class="rx-kw">expose</span><span class="rx-ws"> </span><span class="rx-xvar">item</span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-xvar">item</span><span class="rx-ws"> </span><span class="rx-op">*</span><span class="rx-ws"> </span><span class="rx-xvar">item</span><span class="rx-spe">}</span><span class="rx-ws"> </span><span class="rx-spe">}</span><span class="rx-ws"> </span><span class="rx-op">~</span><span class="rx-ws"> </span><span class="rx-const rx-method">take</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">9</span><span class="rx-spe">)</span><span class="rx-ws"> </span><span class="rx-op">~</span><span class="rx-ws"> </span><span class="rx-const rx-method">each</span><span class="rx-spe">{</span><span class="rx-ws"> </span><span class="rx-kw">say</span><span class="rx-ws"> </span><span class="rx-xvar">item</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-spe">)</span><span class="rx-ws"> </span><span class="rx-spe">}</span>
</code></pre>
</div>

#### Accumulator factory

[Rosetta Code][rosetta_code_accumulator_factory]

```rexx
    accumulator = {
        use arg sum
        return  {
            expose sum
            use arg n
            sum += n
            return sum
        }
    }

    x = accumulator~(1) -- an accumulator (closure), sum initialized to 1
    x~(5)               -- add 5 to sum
    y = accumulator~(3) -- another accumulator (closure), no effect on x
    say x~(2.3)         -- add 2.3 to sum and print the current sum : 8.3
```

<div id="rxa25b270f146d" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-var">accumulator</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-spe">{</span></code>
<code lineno="2"><span class="rx-ws">        </span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">sum</span></code>
<code lineno="3"><span class="rx-ws">        </span><span class="rx-kw">return</span><span class="rx-ws">  </span><span class="rx-spe">{</span></code>
<code lineno="4"><span class="rx-ws">            </span><span class="rx-kw">expose</span><span class="rx-ws"> </span><span class="rx-xvar">sum</span></code>
<code lineno="5"><span class="rx-ws">            </span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">n</span></code>
<code lineno="6"><span class="rx-ws">            </span><span class="rx-xvar">sum</span><span class="rx-ws"> </span><span class="rx-asg">+</span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-var">n</span></code>
<code lineno="7"><span class="rx-ws">            </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-xvar">sum</span></code>
<code lineno="8"><span class="rx-ws">        </span><span class="rx-spe">}</span></code>
<code lineno="9"><span class="rx-ws">    </span><span class="rx-spe">}</span></code>
<code lineno="10"></code>
<code lineno="11"><span class="rx-ws">    </span><span class="rx-var">x</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-var">accumulator</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">1</span><span class="rx-spe">)</span><span class="rx-ws"> </span><span class="rx-lncm">-- an accumulator (closure), sum initialized to 1</span></code>
<code lineno="12"><span class="rx-ws">    </span><span class="rx-var">x</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">5</span><span class="rx-spe">)</span><span class="rx-ws">               </span><span class="rx-lncm">-- add 5 to sum</span></code>
<code lineno="13"><span class="rx-ws">    </span><span class="rx-var">y</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-var">accumulator</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">3</span><span class="rx-spe">)</span><span class="rx-ws"> </span><span class="rx-lncm">-- another accumulator (closure), no effect on x</span></code>
<code lineno="14"><span class="rx-ws">    </span><span class="rx-kw">say</span><span class="rx-ws"> </span><span class="rx-var">x</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-deci rx-ipart">2</span><span class="rx-deci rx-dpoint">.</span><span class="rx-deci rx-fpart">3</span><span class="rx-spe">)</span><span class="rx-ws">         </span><span class="rx-lncm">-- add 2.3 to sum and print the current sum : 8.3</span>
</code></pre>
</div>

#### Function composition

[Rosetta Code][rosetta_code_function_composition]

```rexx
    compose = {
        use arg f, g
        return {
            expose f g
            use arg x
            return f~(g~(x))
        }
    }

    double = { return 2 * arg(1) }
    negative = { return -arg(1) }
    say compose~(negative, double)~(5)  -- -10

    binary2decimal = compose~("x2d", "b2x")
    say binary2decimal~(11111111)  -- 255
```

<div id="rx185c4390a0af" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-var">compose</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-spe">{</span></code>
<code lineno="2"><span class="rx-ws">        </span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">f</span><span class="rx-spe">,</span><span class="rx-ws"> </span><span class="rx-var">g</span></code>
<code lineno="3"><span class="rx-ws">        </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-spe">{</span></code>
<code lineno="4"><span class="rx-ws">            </span><span class="rx-kw">expose</span><span class="rx-ws"> </span><span class="rx-xvar">f</span><span class="rx-ws"> </span><span class="rx-xvar">g</span></code>
<code lineno="5"><span class="rx-ws">            </span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">x</span></code>
<code lineno="6"><span class="rx-ws">            </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-xvar">f</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-xvar">g</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-var">x</span><span class="rx-spe">)</span><span class="rx-spe">)</span></code>
<code lineno="7"><span class="rx-ws">        </span><span class="rx-spe">}</span></code>
<code lineno="8"><span class="rx-ws">    </span><span class="rx-spe">}</span></code>
<code lineno="9"></code>
<code lineno="10"><span class="rx-ws">    </span><span class="rx-var">double</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-spe">{</span><span class="rx-ws"> </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-int rx-ipart">2</span><span class="rx-ws"> </span><span class="rx-op">*</span><span class="rx-ws"> </span><span class="rx-const rx-bif-func">arg</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">1</span><span class="rx-spe">)</span><span class="rx-ws"> </span><span class="rx-spe">}</span></code>
<code lineno="11"><span class="rx-ws">    </span><span class="rx-var">negative</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-spe">{</span><span class="rx-ws"> </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-op">-</span><span class="rx-const rx-bif-func">arg</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">1</span><span class="rx-spe">)</span><span class="rx-ws"> </span><span class="rx-spe">}</span></code>
<code lineno="12"><span class="rx-ws">    </span><span class="rx-kw">say</span><span class="rx-ws"> </span><span class="rx-var">compose</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-var">negative</span><span class="rx-spe">,</span><span class="rx-ws"> </span><span class="rx-var">double</span><span class="rx-spe">)</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">5</span><span class="rx-spe">)</span><span class="rx-ws">  </span><span class="rx-lncm">-- -10</span></code>
<code lineno="13"></code>
<code lineno="14"><span class="rx-ws">    </span><span class="rx-var">binary2decimal</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-var">compose</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-str rx-oquo">"</span><span class="rx-str">x2d</span><span class="rx-str rx-cquo">"</span><span class="rx-spe">,</span><span class="rx-ws"> </span><span class="rx-str rx-oquo">"</span><span class="rx-str">b2x</span><span class="rx-str rx-cquo">"</span><span class="rx-spe">)</span></code>
<code lineno="15"><span class="rx-ws">    </span><span class="rx-kw">say</span><span class="rx-ws"> </span><span class="rx-var">binary2decimal</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">11111111</span><span class="rx-spe">)</span><span class="rx-ws">  </span><span class="rx-lncm">-- 255</span>
</code></pre>
</div>

#### Y combinator

[Rosetta Code][rosetta_code_y_combinator]

The [Y combinator][wikipedia_fixed_point_combinator] allows recursion to be defined as a set of rewrite rules.  
It takes a single argument, which is a function that isn't recursive.  
It returns a version of the function which is recursive.

See [Mike Vanier article][mike_vanier_article].

call-by-value Y combinator (applicable to ooRexx, explicit delayed evaluation done by the lambda (v) wrapper):

```LISP
    Y = λf.(λx.f (λv.((x x) v))) (λx.f (λv.((x x) v)))
    (define Y
      (lambda (f)
        ( (lambda (x) (f (lambda (v) ((x x) v))))
          (lambda (x) (f (lambda (v) ((x x) v)))))))
```

Equivalent form:

```LISP
    (define Y
      (lambda (f)
        ( (lambda (a) (a a))
          (lambda (x) (f (lambda (v) ((x x) v)))))))
```

The call-by-value is implemented as a method on the class RoutineDoer
(no function passed as argument, self is directly the function).

```rexx
    ::class RoutineDoer
    ::method Y
    f = self
    return {use arg a ; return a~(a)} ~ {
        expose f ; use arg x
        return f ~ { expose x ; use arg v ; return x~(x)~(v) }
    }
```

<div id="rx5110b14808fc" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-dir">::</span><span class="rx-dkw">class</span><span class="rx-ws"> </span><span class="rx-const rx-class">RoutineDoer</span></code>
<code lineno="2"><span class="rx-ws">    </span><span class="rx-dir">::</span><span class="rx-dkw">method</span><span class="rx-ws"> </span><span class="rx-const rx-method">Y</span></code>
<code lineno="3"><span class="rx-ws">    </span><span class="rx-var">f</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-var">self</span></code>
<code lineno="4"><span class="rx-ws">    </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-spe">{</span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">a</span><span class="rx-ws"> </span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-var">a</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-var">a</span><span class="rx-spe">)</span><span class="rx-spe">}</span><span class="rx-ws"> </span><span class="rx-op">~</span><span class="rx-ws"> </span><span class="rx-spe">{</span></code>
<code lineno="5"><span class="rx-ws">        </span><span class="rx-kw">expose</span><span class="rx-ws"> </span><span class="rx-xvar">f</span><span class="rx-ws"> </span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">x</span></code>
<code lineno="6"><span class="rx-ws">        </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-xvar">f</span><span class="rx-ws"> </span><span class="rx-op">~</span><span class="rx-ws"> </span><span class="rx-spe">{</span><span class="rx-ws"> </span><span class="rx-kw">expose</span><span class="rx-ws"> </span><span class="rx-xvar">x</span><span class="rx-ws"> </span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">v</span><span class="rx-ws"> </span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-xvar">x</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-xvar">x</span><span class="rx-spe">)</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-var">v</span><span class="rx-spe">)</span><span class="rx-ws"> </span><span class="rx-spe">}</span></code>
<code lineno="7"><span class="rx-ws">    </span><span class="rx-spe">}</span>
</code></pre>
</div>

Application of the Y combinator to factorial:

```rexx
    fact = { use arg f
             return  { expose f ; use arg n ; if n == 0 then return 1 ; else return n * f~(n-1) }
           }~Y
    say fact~(10) -- 3628800
```

<div id="rx40d9c2cd4ff2" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-var">fact</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-spe">{</span><span class="rx-ws"> </span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">f</span></code>
<code lineno="2"><span class="rx-ws">             </span><span class="rx-kw">return</span><span class="rx-ws">  </span><span class="rx-spe">{</span><span class="rx-ws"> </span><span class="rx-kw">expose</span><span class="rx-ws"> </span><span class="rx-xvar">f</span><span class="rx-ws"> </span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">n</span><span class="rx-ws"> </span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">if</span><span class="rx-ws"> </span><span class="rx-var">n</span><span class="rx-ws"> </span><span class="rx-op">=</span><span class="rx-op">=</span><span class="rx-ws"> </span><span class="rx-int rx-ipart">0</span><span class="rx-ws"> </span><span class="rx-kw">then</span><span class="rx-ws"> </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-int rx-ipart">1</span><span class="rx-ws"> </span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">else</span><span class="rx-ws"> </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-var">n</span><span class="rx-ws"> </span><span class="rx-op">*</span><span class="rx-ws"> </span><span class="rx-xvar">f</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-var">n</span><span class="rx-op">-</span><span class="rx-int rx-ipart">1</span><span class="rx-spe">)</span><span class="rx-ws"> </span><span class="rx-spe">}</span></code>
<code lineno="3"><span class="rx-ws">           </span><span class="rx-spe">}</span><span class="rx-op">~</span><span class="rx-const rx-method">Y</span></code>
<code lineno="4"><span class="rx-ws">    </span><span class="rx-kw">say</span><span class="rx-ws"> </span><span class="rx-var">fact</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">10</span><span class="rx-spe">)</span><span class="rx-ws"> </span><span class="rx-lncm">-- 3628800</span>
</code></pre>
</div>

#### Y combinator with memoization

[Memoization][wikipedia_memoization] is an optimization technique used primarily to speed up computer programs by storing the results of expensive function calls and returning the cached result when the same inputs occur again.

```rexx
    ::class RoutineDoer
    ::method YM
    f = self
    table = .Table~new
    return {use arg a ; return a~(a)} ~ {
        expose f table ; use arg x
        return f ~ { expose x table
                     use arg v
                     r = table[v]
                     if r <> .nil then return r
                     r = x~(x)~(v)
                     table[v] = r
                     return r
                   }
    }
```

<div id="rx25c482aa6dc6" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-dir">::</span><span class="rx-dkw">class</span><span class="rx-ws"> </span><span class="rx-const rx-class">RoutineDoer</span></code>
<code lineno="2"><span class="rx-ws">    </span><span class="rx-dir">::</span><span class="rx-dkw">method</span><span class="rx-ws"> </span><span class="rx-const rx-method">YM</span></code>
<code lineno="3"><span class="rx-ws">    </span><span class="rx-var">f</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-var">self</span></code>
<code lineno="4"><span class="rx-ws">    </span><span class="rx-var">table</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-env">.Table</span><span class="rx-op">~</span><span class="rx-const rx-method">new</span></code>
<code lineno="5"><span class="rx-ws">    </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-spe">{</span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">a</span><span class="rx-ws"> </span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-var">a</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-var">a</span><span class="rx-spe">)</span><span class="rx-spe">}</span><span class="rx-ws"> </span><span class="rx-op">~</span><span class="rx-ws"> </span><span class="rx-spe">{</span></code>
<code lineno="6"><span class="rx-ws">        </span><span class="rx-kw">expose</span><span class="rx-ws"> </span><span class="rx-xvar">f</span><span class="rx-ws"> </span><span class="rx-xvar">table</span><span class="rx-ws"> </span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">x</span></code>
<code lineno="7"><span class="rx-ws">        </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-xvar">f</span><span class="rx-ws"> </span><span class="rx-op">~</span><span class="rx-ws"> </span><span class="rx-spe">{</span><span class="rx-ws"> </span><span class="rx-kw">expose</span><span class="rx-ws"> </span><span class="rx-xvar">x</span><span class="rx-ws"> </span><span class="rx-xvar">table</span></code>
<code lineno="8"><span class="rx-ws">                     </span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">v</span></code>
<code lineno="9"><span class="rx-ws">                     </span><span class="rx-var">r</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-xvar">table</span><span class="rx-spe">[</span><span class="rx-var">v</span><span class="rx-spe">]</span></code>
<code lineno="10"><span class="rx-ws">                     </span><span class="rx-kw">if</span><span class="rx-ws"> </span><span class="rx-var">r</span><span class="rx-ws"> </span><span class="rx-op">&lt;</span><span class="rx-op">&gt;</span><span class="rx-ws"> </span><span class="rx-env">.nil</span><span class="rx-ws"> </span><span class="rx-kw">then</span><span class="rx-ws"> </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-var">r</span></code>
<code lineno="11"><span class="rx-ws">                     </span><span class="rx-var">r</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-xvar">x</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-xvar">x</span><span class="rx-spe">)</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-var">v</span><span class="rx-spe">)</span></code>
<code lineno="12"><span class="rx-ws">                     </span><span class="rx-xvar">table</span><span class="rx-spe">[</span><span class="rx-var">v</span><span class="rx-spe">]</span><span class="rx-ws"> </span><span class="rx-op">=</span><span class="rx-ws"> </span><span class="rx-var">r</span></code>
<code lineno="13"><span class="rx-ws">                     </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-var">r</span></code>
<code lineno="14"><span class="rx-ws">                   </span><span class="rx-spe">}</span></code>
<code lineno="15"><span class="rx-ws">    </span><span class="rx-spe">}</span>
</code></pre>
</div>

Application to fibonacci:

```rexx
    fibm = { use arg fib
             return {expose fib; use arg n
                     if n==0 then return 0
                     if n==1 then return 1
                     if n<0 then return fib~(n+2) - fib~(n+1)
                     return fib~(n-2) + fib~(n-1)
                    }
           }~YM
    say fibm~(25) -- 75025
```

<div id="rx409a485e8aff" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-var">fibm</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-spe">{</span><span class="rx-ws"> </span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">fib</span></code>
<code lineno="2"><span class="rx-ws">             </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-spe">{</span><span class="rx-kw">expose</span><span class="rx-ws"> </span><span class="rx-xvar">fib</span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">use</span><span class="rx-ws"> </span><span class="rx-skw">arg</span><span class="rx-ws"> </span><span class="rx-var">n</span></code>
<code lineno="3"><span class="rx-ws">                     </span><span class="rx-kw">if</span><span class="rx-ws"> </span><span class="rx-var">n</span><span class="rx-op">=</span><span class="rx-op">=</span><span class="rx-int rx-ipart">0</span><span class="rx-ws"> </span><span class="rx-kw">then</span><span class="rx-ws"> </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-int rx-ipart">0</span></code>
<code lineno="4"><span class="rx-ws">                     </span><span class="rx-kw">if</span><span class="rx-ws"> </span><span class="rx-var">n</span><span class="rx-op">=</span><span class="rx-op">=</span><span class="rx-int rx-ipart">1</span><span class="rx-ws"> </span><span class="rx-kw">then</span><span class="rx-ws"> </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-int rx-ipart">1</span></code>
<code lineno="5"><span class="rx-ws">                     </span><span class="rx-kw">if</span><span class="rx-ws"> </span><span class="rx-var">n</span><span class="rx-op">&lt;</span><span class="rx-int rx-ipart">0</span><span class="rx-ws"> </span><span class="rx-kw">then</span><span class="rx-ws"> </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-xvar">fib</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-var">n</span><span class="rx-op">+</span><span class="rx-int rx-ipart">2</span><span class="rx-spe">)</span><span class="rx-ws"> </span><span class="rx-op">-</span><span class="rx-ws"> </span><span class="rx-xvar">fib</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-var">n</span><span class="rx-op">+</span><span class="rx-int rx-ipart">1</span><span class="rx-spe">)</span></code>
<code lineno="6"><span class="rx-ws">                     </span><span class="rx-kw">return</span><span class="rx-ws"> </span><span class="rx-xvar">fib</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-var">n</span><span class="rx-op">-</span><span class="rx-int rx-ipart">2</span><span class="rx-spe">)</span><span class="rx-ws"> </span><span class="rx-op">+</span><span class="rx-ws"> </span><span class="rx-xvar">fib</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-var">n</span><span class="rx-op">-</span><span class="rx-int rx-ipart">1</span><span class="rx-spe">)</span></code>
<code lineno="7"><span class="rx-ws">                    </span><span class="rx-spe">}</span></code>
<code lineno="8"><span class="rx-ws">           </span><span class="rx-spe">}</span><span class="rx-op">~</span><span class="rx-const rx-method">YM</span></code>
<code lineno="9"><span class="rx-ws">    </span><span class="rx-kw">say</span><span class="rx-ws"> </span><span class="rx-var">fibm</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">25</span><span class="rx-spe">)</span><span class="rx-ws"> </span><span class="rx-lncm">-- 75025</span>
</code></pre>
</div>

fibm~(25) is calculated almost instantly,  
whereas the not-memoizing version needs almost 30 sec.

Both Y and YM are subject to stack overflow.  
But YM can be used by steps, to calculate very big fibonacci numbers, thanks to the memoization:

```rexx
    numeric digits propagate 2090
    do i=1 to 100; say "fibm~("i*100")="fibm~(i*100); end
    -- fibm~(100)=354224848179261915075
    -- fibm~(200)=280571172992510140037611932413038677189525
    -- fibm~(300)=222232244629420445529739893461909967206666939096499764990979600
    ...
    -- fibm~(10000)=33644764876431783266621612005107543310302148460680063906564769974680081442166662368155595513633734025582065332680836159373734790483865268263040892463056431887354544369559827491606602099884183933864652731300088830269235673613135117579297437854413752130520504347701602264758318906527890855154366159582987279682987510631200575428783453215515103870818298969791613127856265033195487140214287532698187962046936097879900350962302291026368131493195275630227837628441540360584402572114334961180023091208287046088923962328835461505776583271252546093591128203925285393434620904245248929403901706233888991085841065183173360437470737908552631764325733993712871937587746897479926305837065742830161637408969178426378624212835258112820516370298089332099905707920064367426202389783111470054074998459250360633560933883831923386783056136435351892133279732908133732642652633989763922723407882928177953580570993691049175470808931841056146322338217465637321248226383092103297701648054726243842374862411453093812206564914032751086643394517512161526545361333111314042436854805106765843493523836959653428071768775328348234345557366719731392746273629108210679280784718035329131176778924659089938635459327894523777674406192240337638674004021330343297496902028328145933418826817683893072003634795623117103101291953169794607632737589253530772552375943788434504067715555779056450443016640119462580972216729758615026968443146952034614932291105970676243268515992834709891284706740862008587135016260312071903172086094081298321581077282076353186624611278245537208532365305775956430072517744315051539600905168603220349163222640885248852433158051534849622434848299380905070483482449327453732624567755879089187190803662058009594743150052402532709746995318770724376825907419939632265984147498193609285223945039707165443156421328157688908058783183404917434556270520223564846495196112460268313970975069382648706613264507665074611512677522748621598642530711298441182622661057163515069260029861704945425047491378115154139941550671256271197133252763631939606902895650288268608362241082050562430701794976171121233066073310059947366875
```

<div id="rxdd61b59f3b68" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-kw">numeric</span><span class="rx-ws"> </span><span class="rx-skw">digits</span><span class="rx-ws"> </span><span class="rx-var">propagate</span><span class="rx-op"> </span><span class="rx-int rx-ipart">2090</span></code>
<code lineno="2"><span class="rx-ws">    </span><span class="rx-kw">do</span><span class="rx-ws"> </span><span class="rx-var">i</span><span class="rx-asg">=</span><span class="rx-int rx-ipart">1</span><span class="rx-ws"> </span><span class="rx-skw">to</span><span class="rx-ws"> </span><span class="rx-int rx-ipart">100</span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">say</span><span class="rx-ws"> </span><span class="rx-str rx-oquo">"</span><span class="rx-str">fibm~(</span><span class="rx-str rx-cquo">"</span><span class="rx-var">i</span><span class="rx-op">*</span><span class="rx-int rx-ipart">100</span><span class="rx-str rx-oquo">"</span><span class="rx-str">)=</span><span class="rx-str rx-cquo">"</span><span class="rx-var">fibm</span><span class="rx-op">~</span><span class="rx-spe">(</span><span class="rx-var">i</span><span class="rx-op">*</span><span class="rx-int rx-ipart">100</span><span class="rx-spe">)</span><span class="rexx">;</span><span class="rx-ws"> </span><span class="rx-kw">end</span></code>
<code lineno="3"><span class="rx-ws">    </span><span class="rx-lncm">-- fibm~(100)=354224848179261915075</span></code>
<code lineno="4"><span class="rx-ws">    </span><span class="rx-lncm">-- fibm~(200)=280571172992510140037611932413038677189525</span></code>
<code lineno="5"><span class="rx-ws">    </span><span class="rx-lncm">-- fibm~(300)=222232244629420445529739893461909967206666939096499764990979600</span></code>
<code lineno="6"><span class="rx-ws">    </span><span class="rx-env">...</span></code>
<code lineno="7"><span class="rx-ws">    </span><span class="rx-lncm">-- fibm~(10000)=33644764876431783266621612005107543310302148460680063906564769974680081442166662368155595513633734025582065332680836159373734790483865268263040892463056431887354544369559827491606602099884183933864652731300088830269235673613135117579297437854413752130520504347701602264758318906527890855154366159582987279682987510631200575428783453215515103870818298969791613127856265033195487140214287532698187962046936097879900350962302291026368131493195275630227837628441540360584402572114334961180023091208287046088923962328835461505776583271252546093591128203925285393434620904245248929403901706233888991085841065183173360437470737908552631764325733993712871937587746897479926305837065742830161637408969178426378624212835258112820516370298089332099905707920064367426202389783111470054074998459250360633560933883831923386783056136435351892133279732908133732642652633989763922723407882928177953580570993691049175470808931841056146322338217465637321248226383092103297701648054726243842374862411453093812206564914032751086643394517512161526545361333111314042436854805106765843493523836959653428071768775328348234345557366719731392746273629108210679280784718035329131176778924659089938635459327894523777674406192240337638674004021330343297496902028328145933418826817683893072003634795623117103101291953169794607632737589253530772552375943788434504067715555779056450443016640119462580972216729758615026968443146952034614932291105970676243268515992834709891284706740862008587135016260312071903172086094081298321581077282076353186624611278245537208532365305775956430072517744315051539600905168603220349163222640885248852433158051534849622434848299380905070483482449327453732624567755879089187190803662058009594743150052402532709746995318770724376825907419939632265984147498193609285223945039707165443156421328157688908058783183404917434556270520223564846495196112460268313970975069382648706613264507665074611512677522748621598642530711298441182622661057163515069260029861704945425047491378115154139941550671256271197133252763631939606902895650288268608362241082050562430701794976171121233066073310059947366875</span>
</code></pre>
</div>

The first execution needs around 2.5 sec.  
The following executions need less than 0.01 sec.

### Array programming

#### Array initializer

Initializer (instance method ~of) which takes into account the dimensions of the array.  

If there is only one argument, and this argument has the method ~supplier then each item returned by the argument's supplier is an item.

```rexx
    .array~new(2,3)~of(1~6)
    1 2 3
    4 5 6
```

<div id="rx4e5dfa68ba37" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-env">.array</span><span class="rx-op">~</span><span class="rx-const rx-method">new</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">2</span><span class="rx-spe">,</span><span class="rx-int rx-ipart">3</span><span class="rx-spe">)</span><span class="rx-op">~</span><span class="rx-const rx-method">of</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">1</span><span class="rx-op">~</span><span class="rx-const rx-method">6</span><span class="rx-spe">)</span></code>
<code lineno="2"><span class="rx-ws">    </span><span class="rx-int rx-ipart">1</span><span class="rx-op"> </span><span class="rx-int rx-ipart">2</span><span class="rx-op"> </span><span class="rx-int rx-ipart">3</span></code>
<code lineno="3"><span class="rx-ws">    </span><span class="rx-int rx-ipart">4</span><span class="rx-op"> </span><span class="rx-int rx-ipart">5</span><span class="rx-op"> </span><span class="rx-int rx-fpart">6</span>
</code></pre>
</div>

If there is only one argument, and this argument is a doer, then the doer is called for each cell to initialize.

```rexx
    .array~new(2,3)~of{10*item}
    10 20 30
    40 50 60
```

<div id="rx4fc72d27b40f" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-env">.array</span><span class="rx-op">~</span><span class="rx-const rx-method">new</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">2</span><span class="rx-spe">,</span><span class="rx-int rx-ipart">3</span><span class="rx-spe">)</span><span class="rx-op">~</span><span class="rx-const rx-method">of</span><span class="rx-spe">{</span><span class="rx-int rx-ipart">10</span><span class="rx-op">*</span><span class="rx-var">item</span><span class="rx-spe">}</span></code>
<code lineno="2"><span class="rx-ws">    </span><span class="rx-int rx-ipart">10</span><span class="rx-op"> </span><span class="rx-int rx-ipart">20</span><span class="rx-op"> </span><span class="rx-int rx-ipart">30</span></code>
<code lineno="3"><span class="rx-ws">    </span><span class="rx-int rx-ipart">40</span><span class="rx-op"> </span><span class="rx-int rx-ipart">50</span><span class="rx-op"> </span><span class="rx-int rx-fpart">60</span>
</code></pre>
</div>

Otherwise each argument is an item as-is.

```rexx
    .array~new(2,3)~of(1,2,3,4,5,6)
    1 2 3
    4 5 6
```

<div id="rxdb81b8512121" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-env">.array</span><span class="rx-op">~</span><span class="rx-const rx-method">new</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">2</span><span class="rx-spe">,</span><span class="rx-int rx-ipart">3</span><span class="rx-spe">)</span><span class="rx-op">~</span><span class="rx-const rx-method">of</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">1</span><span class="rx-spe">,</span><span class="rx-int rx-ipart">2</span><span class="rx-spe">,</span><span class="rx-int rx-ipart">3</span><span class="rx-spe">,</span><span class="rx-int rx-ipart">4</span><span class="rx-spe">,</span><span class="rx-int rx-ipart">5</span><span class="rx-spe">,</span><span class="rx-int rx-fpart">6</span><span class="rx-spe">)</span></code>
<code lineno="2"><span class="rx-ws">    </span><span class="rx-int rx-ipart">1</span><span class="rx-op"> </span><span class="rx-int rx-ipart">2</span><span class="rx-op"> </span><span class="rx-int rx-ipart">3</span></code>
<code lineno="3"><span class="rx-ws">    </span><span class="rx-int rx-ipart">4</span><span class="rx-op"> </span><span class="rx-int rx-ipart">5</span><span class="rx-op"> </span><span class="rx-int rx-fpart">6</span>
</code></pre>
</div>

If some arguments are omitted, then the corresponding item in the initialized array remains non-assigned.

```rexx
    .array~new(2,3)~of(1,,3,,5,6)
    1 . 3
    . 5 6
```

<div id="rx55f656c05c58" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-env">.array</span><span class="rx-op">~</span><span class="rx-const rx-method">new</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">2</span><span class="rx-spe">,</span><span class="rx-int rx-ipart">3</span><span class="rx-spe">)</span><span class="rx-op">~</span><span class="rx-const rx-method">of</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">1</span><span class="rx-spe">,</span><span class="rx-spe">,</span><span class="rx-int rx-ipart">3</span><span class="rx-spe">,</span><span class="rx-spe">,</span><span class="rx-int rx-ipart">5</span><span class="rx-spe">,</span><span class="rx-int rx-fpart">6</span><span class="rx-spe">)</span></code>
<code lineno="2"><span class="rx-ws">    </span><span class="rx-int rx-ipart">1</span><span class="rx-op"> </span><span class="rx-lit">.</span><span class="rx-op"> </span><span class="rx-int rx-ipart">3</span></code>
<code lineno="3"><span class="rx-ws">    </span><span class="rx-lit">.</span><span class="rx-op"> </span><span class="rx-int rx-ipart">5</span><span class="rx-op"> </span><span class="rx-int rx-fpart">6</span>
</code></pre>
</div>

Rules inspired by [APL][apl_glimpse_heaven]:  
If there are too many items, the extra items are ignored.  
If there are fewer items than implied by the dimensions, the list of items is reused as
many times as necessary to fill the array.

```rexx
    .array~new(2,3)~of(1,2)
    1 2 1
    2 1 2
```

<div id="rx0d8966f93487" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-env">.array</span><span class="rx-op">~</span><span class="rx-const rx-method">new</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">2</span><span class="rx-spe">,</span><span class="rx-int rx-ipart">3</span><span class="rx-spe">)</span><span class="rx-op">~</span><span class="rx-const rx-method">of</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">1</span><span class="rx-spe">,</span><span class="rx-int rx-ipart">2</span><span class="rx-spe">)</span></code>
<code lineno="2"><span class="rx-ws">    </span><span class="rx-int rx-ipart">1</span><span class="rx-op"> </span><span class="rx-int rx-ipart">2</span><span class="rx-op"> </span><span class="rx-int rx-ipart">1</span></code>
<code lineno="3"><span class="rx-ws">    </span><span class="rx-int rx-ipart">2</span><span class="rx-op"> </span><span class="rx-int rx-ipart">1</span><span class="rx-op"> </span><span class="rx-int rx-ipart">2</span>
</code></pre>
</div>

#### Symmetric implementations of binary operators

Thanks to the support of alternative messages for binary operators, it's now possible to provide symmetric implementations of binary operators.  

```rexx
    arg1 ~ "+"( arg2 )
```

<div id="rxfd517ade1c0c" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-var">arg1</span><span class="rx-ws"> </span><span class="rx-op">~</span><span class="rx-ws"> </span><span class="rx-const rx-method rx-oquo">"</span><span class="rx-const rx-method">+</span><span class="rx-const rx-method rx-cquo">"</span><span class="rx-spe">(</span><span class="rx-ws"> </span><span class="rx-var">arg2</span><span class="rx-ws"> </span><span class="rx-spe">)</span>
</code></pre>
</div>

If arg1 doesn't know how to process the message "+" (either because the message itself is not understood, or because the type of arg2 is not supported) then the interpreter sends this alternative message:

```rexx
    arg2 ~ "+OP:RIGHT"( arg1 )
```

<div id="rxa5eba9e6a2cf" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-var">arg2</span><span class="rx-ws"> </span><span class="rx-op">~</span><span class="rx-ws"> </span><span class="rx-const rx-method rx-oquo">"</span><span class="rx-const rx-method">+OP:RIGHT</span><span class="rx-const rx-method rx-cquo">"</span><span class="rx-spe">(</span><span class="rx-ws"> </span><span class="rx-var">arg1</span><span class="rx-ws"> </span><span class="rx-spe">)</span>
</code></pre>
</div>

If arg2 doesn't know how to process the message "+OP:RIGHT" (either because the message itself is not understood, or because the type of arg1 is not supported) then the interpreter raises an exception for the traditional message "+", not for the alternative message. That way, legacy programs are not impacted by this extension of behaviour.  
There is no performance penalty because the interpreter sends the alternative message only when the traditional implementation fails. So the optimized implementations of String | NumberString | Integer operators continue to be fully optimized.

Examples:

```rexx
    a = .array~of(10,20,30)
    100 a=                  -- ['100 10','100 20','100 30'] instead of '100 an Array'
    a 100=                  -- ['10 100','20 100','30 100']
    100 || a =              -- [10010,10020,10030]          instead of '100an Array'
    a || 100 =              -- [10100,20100,30100]
    100 - a =               -- [90, 80, 70]
    (100+200i) * a =        -- [1000+2000i, 2000+4000i, 3000+6000i]
```

<div id="rx3f797325ae1d" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-var">a</span><span class="rx-ws"> </span><span class="rx-asg">=</span><span class="rx-ws"> </span><span class="rx-env">.array</span><span class="rx-op">~</span><span class="rx-const rx-method">of</span><span class="rx-spe">(</span><span class="rx-int rx-ipart">10</span><span class="rx-spe">,</span><span class="rx-int rx-ipart">20</span><span class="rx-spe">,</span><span class="rx-int rx-ipart">30</span><span class="rx-spe">)</span></code>
<code lineno="2"><span class="rx-ws">    </span><span class="rx-int rx-ipart">100</span><span class="rx-op"> </span><span class="rx-var">a</span><span class="rexx">=</span><span class="rx-ws">                  </span><span class="rx-lncm">-- ['100 10','100 20','100 30'] instead of '100 an Array'</span></code>
<code lineno="3"><span class="rx-ws">    </span><span class="rx-var">a</span><span class="rx-op"> </span><span class="rx-int rx-ipart">100</span><span class="rexx">=</span><span class="rx-ws">                  </span><span class="rx-lncm">-- ['10 100','20 100','30 100']</span></code>
<code lineno="4"><span class="rx-ws">    </span><span class="rx-int rx-ipart">100</span><span class="rx-ws"> </span><span class="rx-op">|</span><span class="rx-op">|</span><span class="rx-ws"> </span><span class="rx-var">a</span><span class="rx-ws"> </span><span class="rexx">=</span><span class="rx-ws">              </span><span class="rx-lncm">-- [10010,10020,10030]          instead of '100an Array'</span></code>
<code lineno="5"><span class="rx-ws">    </span><span class="rx-var">a</span><span class="rx-ws"> </span><span class="rx-op">|</span><span class="rx-op">|</span><span class="rx-ws"> </span><span class="rx-int rx-ipart">100</span><span class="rx-ws"> </span><span class="rexx">=</span><span class="rx-ws">              </span><span class="rx-lncm">-- [10100,20100,30100]</span></code>
<code lineno="6"><span class="rx-ws">    </span><span class="rx-int rx-ipart">100</span><span class="rx-ws"> </span><span class="rx-op">-</span><span class="rx-ws"> </span><span class="rx-var">a</span><span class="rx-ws"> </span><span class="rexx">=</span><span class="rx-ws">               </span><span class="rx-lncm">-- [90, 80, 70]</span></code>
<code lineno="7"><span class="rx-ws">    </span><span class="rx-spe">(</span><span class="rx-int rx-ipart">100</span><span class="rx-op">+</span><span class="rx-int rx-ipart">200</span><span class="rx-var">i</span><span class="rx-spe">)</span><span class="rx-ws"> </span><span class="rx-op">*</span><span class="rx-ws"> </span><span class="rx-var">a</span><span class="rx-ws"> </span><span class="rexx">=</span><span class="rx-ws">        </span><span class="rx-lncm">-- [1000+2000i, 2000+4000i, 3000+6000i]</span>
</code></pre>
</div>

### Pipelines

A chain of connected [pipeStages][pipes_documentation] is a pipe.  
Any object can be a source of pipe:

- When the object does not support the method ~supplier then it's injected as-is.  
  The index is 1.
- A collection can be a source of pipe: each item of the collection is injected in the pipe.  
  The indexes are those of the collection.
- A coactivty can be a source of pipe: each yielded item is injected in the pipe (lazily).  
  The indexes are those returned by the coactivity supplier.

Example:  
Count the number of files in the directory passed as argument, and in each subdirectory.  
The recursivity is limited to 1 level, [breadth-first search][wikipedia_breadth_first_search].  
The count per directory is done by partitioning the instances of .File flowing through the pipeline by their parent.  

```rexx
    "d:\"~pipe(.fileTree "recursive.1.breadthFirst" | .lineCount {item~parent} | .console {item~right(6)} "index")
```

<div id="rx8a54449554b7" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-str rx-oquo">"</span><span class="rx-str">d:\</span><span class="rx-str rx-cquo">"</span><span class="rx-op">~</span><span class="rx-const rx-method">pipe</span><span class="rx-spe">(</span><span class="rx-env">.fileTree</span><span class="rx-op"> </span><span class="rx-str rx-oquo">"</span><span class="rx-str">recursive.1.breadthFirst</span><span class="rx-str rx-cquo">"</span><span class="rx-ws"> </span><span class="rx-op">|</span><span class="rx-ws"> </span><span class="rx-env">.lineCount</span><span class="rx-op"> </span><span class="rx-spe">{</span><span class="rx-var">item</span><span class="rx-op">~</span><span class="rx-const rx-method">parent</span><span class="rx-spe">}</span><span class="rx-ws"> </span><span class="rx-op">|</span><span class="rx-ws"> </span><span class="rx-env">.console</span><span class="rx-op"> </span><span class="rx-spe">{</span><span class="rx-var">item</span><span class="rx-op">~</span><span class="rx-const rx-method">right</span><span class="rx-spe">(</span><span class="rx-int rx-fpart">6</span><span class="rx-spe">)</span><span class="rx-spe">}</span><span class="rx-op"> </span><span class="rx-str rx-oquo">"</span><span class="rx-str">index</span><span class="rx-str rx-cquo">"</span><span class="rx-spe">)</span>
</code></pre>
</div>

output:

        70 'd:'
         1 'd:\$RECYCLE.BIN'
       146 'd:\bin'
        16 'd:\Cygwin'
         6 'd:\gnutools'
    ...

Example:  
Public classes by package.

```rexx
    .context~package~pipe(,
        .importedPackages "recursive" "once" "after" "mem.package" |,
        .inject {item~publicClasses} "iterateAfter" |,
        .sort {item~id} {dataflow["package"]~item~name} |,
        .console {.file~new(dataflow["package"]~item~name)~name} ":" "item",
        )
```

<div id="rxb1f66053bd4d" class="highlight-rexx-vim-light-zellner">
<style>
</style>
<pre><code lineNo="1"><span class="rx-ws">    </span><span class="rx-env">.context</span><span class="rx-op">~</span><span class="rx-const rx-method">package</span><span class="rx-op">~</span><span class="rx-const rx-method">pipe</span><span class="rx-spe">(</span><span class="rx-cont">,</span></code>
<code lineno="2"><span class="rx-ws">        </span><span class="rx-env">.importedPackages</span><span class="rx-op"> </span><span class="rx-str rx-oquo">"</span><span class="rx-str">recursive</span><span class="rx-str rx-cquo">"</span><span class="rx-op"> </span><span class="rx-str rx-oquo">"</span><span class="rx-str">once</span><span class="rx-str rx-cquo">"</span><span class="rx-op"> </span><span class="rx-str rx-oquo">"</span><span class="rx-str">after</span><span class="rx-str rx-cquo">"</span><span class="rx-op"> </span><span class="rx-str rx-oquo">"</span><span class="rx-str">mem.package</span><span class="rx-str rx-cquo">"</span><span class="rx-ws"> </span><span class="rx-op">|</span><span class="rx-cont">,</span></code>
<code lineno="3"><span class="rx-ws">        </span><span class="rx-env">.inject</span><span class="rx-op"> </span><span class="rx-spe">{</span><span class="rx-var">item</span><span class="rx-op">~</span><span class="rx-const rx-method">publicClasses</span><span class="rx-spe">}</span><span class="rx-op"> </span><span class="rx-str rx-oquo">"</span><span class="rx-str">iterateAfter</span><span class="rx-str rx-cquo">"</span><span class="rx-ws"> </span><span class="rx-op">|</span><span class="rx-cont">,</span></code>
<code lineno="4"><span class="rx-ws">        </span><span class="rx-env">.sort</span><span class="rx-op"> </span><span class="rx-spe">{</span><span class="rx-var">item</span><span class="rx-op">~</span><span class="rx-const rx-method">id</span><span class="rx-spe">}</span><span class="rx-op"> </span><span class="rx-spe">{</span><span class="rx-var">dataflow</span><span class="rx-spe">[</span><span class="rx-str rx-oquo">"</span><span class="rx-str">package</span><span class="rx-str rx-cquo">"</span><span class="rx-spe">]</span><span class="rx-op">~</span><span class="rx-const rx-method">item</span><span class="rx-op">~</span><span class="rx-const rx-method">name</span><span class="rx-spe">}</span><span class="rx-ws"> </span><span class="rx-op">|</span><span class="rx-cont">,</span></code>
<code lineno="5"><span class="rx-ws">        </span><span class="rx-env">.console</span><span class="rx-op"> </span><span class="rx-spe">{</span><span class="rx-env">.file</span><span class="rx-op">~</span><span class="rx-const rx-method">new</span><span class="rx-spe">(</span><span class="rx-var">dataflow</span><span class="rx-spe">[</span><span class="rx-str rx-oquo">"</span><span class="rx-str">package</span><span class="rx-str rx-cquo">"</span><span class="rx-spe">]</span><span class="rx-op">~</span><span class="rx-const rx-method">item</span><span class="rx-op">~</span><span class="rx-const rx-method">name</span><span class="rx-spe">)</span><span class="rx-op">~</span><span class="rx-const rx-method">name</span><span class="rx-spe">}</span><span class="rx-op"> </span><span class="rx-str rx-oquo">"</span><span class="rx-str">:</span><span class="rx-str rx-cquo">"</span><span class="rx-op"> </span><span class="rx-str rx-oquo">"</span><span class="rx-str">item</span><span class="rx-str rx-cquo">"</span><span class="rx-cont">,</span></code>
<code lineno="6"><span class="rx-ws">        </span><span class="rx-spe">)</span>
</code></pre>
</div>

output, when run from ooRexxShell:

    mime.cls : (The MIMEMULTIPART class)
    mime.cls : (The MIMEPART class)
    rxftp.cls : (The rxftp class)
    rxregexp.cls : (The RegularExpression class)
    ...

Demos with asciinema
--------------------

Several demos are available [here][demos_with_asciinema].

Laisse béton
------------

I was at ease, I was laid-back, leaning at the keyboard.  
The guy went into the office and looked at me, like:  
  
*You got extensions, [Rexx Cub][rexx_cub],  
Quit showing off.  
I bet that's monkey patching,  
[Shame on you][shame_on_you]!  
Follow me to the waste lot,  
I'll teach you a funny game  
With big blows of variable scope.*  
  
I told him *[Laisse béton][laisse_beton].*  
    
He gave me a clout  
I gave him a whack  
He gave me a punch  
I gave up my extensions.


[apl_glimpse_heaven]: https://archive.vector.org.uk/art10011550 "APL - a Glimpse of Heaven"
[build_executor]: https://github.com/jlfaucher/builder/blob/master/build-executor.txt
[demo_unicode_checks]: https://jlfaucher.github.io/executor.master/demos/executor-demo-text-internal_checks-output.html
[demo_unicode_intro]: https://jlfaucher.github.io/executor.master/demos/executor-demo-text-output.html
[demo_unicode_services]: https://jlfaucher.github.io/executor.master/demos/executor-demo-text-unicode-output.html
[demo_unicode_string_compatibility]: https://jlfaucher.github.io/executor.master/demos/executor-demo-text-compatibility-output.html
[demo_unicode_string_compatibility_auto_conv]: https://jlfaucher.github.io/executor.master/demos/executor-demo-text-compatibility-auto-conv-output.html
[demos_with_asciinema]: https://jlfaucher.github.io/executor.master/demos/index.html
[doc]: https://jlfaucher.github.io/oorexx/docs/trunk/index.html "Graphical syntax diagrams"
[download]: https://jlfaucher.github.io/oorexx/sandbox/index.html "Download"
[encoded_strings_concatenation]: https://jlfaucher.github.io/executor.master/tests/encoding/main_concatenation.output.html
[encoded_strings_diary_exemples]: https://jlfaucher.github.io/executor.master/tests/encoding/diary_examples.output.html
[encoded_strings_transcoding]: https://jlfaucher.github.io/executor.master/tests/encoding/main_conversion.output.html
[internal_documentation_classes]: https://jlfaucher.github.io/executor.master/doxygen/html/classes.html
[internal_documentation_files]: https://jlfaucher.github.io/executor.master/doxygen/html/files.html
[internal_notes]: https://github.com/jlfaucher/executor/tree/master/sandbox/jlf/internals/notes "Internal notes"
[laisse_beton]:https://www.youtube.com/watch?v=9eU7wv4eOo8 "Laisse béton"
[mike_vanier_article]: https://mvanier.livejournal.com/2897.html "Mike Vanier : Y combinator"
[named_arguments_spec]: https://github.com/jlfaucher/executor/tree/master/sandbox/jlf/docs/NamedArguments/NamedArguments-Spec.md "Specification of named arguments"
[named_arguments_test_cases_output]: https://github.com/jlfaucher/executor/tree/master/sandbox/jlf/tests/extension/named_arguments-test.output.reference.txt "Test cases of named arguments (output)"
[named_arguments_test_cases_script]: https://github.com/jlfaucher/executor/tree/master/sandbox/jlf/tests/extension/named_arguments-test.rex "Test cases of named arguments (script)"
[notes_unicode]: https://jlfaucher.github.io/executor.master/unicode/_notes-unicode.html
[overview_changes]: https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/_changes.md "Overview of changes"
[pipes_documentation]: https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/packages/pipeline/pipe_readme.txt
[rexx_cub]: https://jlfaucher.github.io/executor.master/docs/RexxCub/RexxCub.html "Rexx Cub"
[rosetta_code_accumulator_factory]: https://rosettacode.org/wiki/Accumulator_factory "Rosetta code : Accumulator factory"
[rosetta_code_closures_value_capture]: https://rosettacode.org/wiki/Closures/Value_capture "Rosetta code : Closures/Value capture"
[rosetta_code_function_composition]: https://rosettacode.org/wiki/Function_composition "Rosetta code : Function composition"
[rosetta_code_y_combinator]: https://rosettacode.org/wiki/Y_combinator "Rosetta code : Y combinator"
[sandbox_diary]: https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/_diary.txt "Sandbox diary"
[sandbox_notes]: https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/_notes.txt "Sandbox notes"
[shame_on_you]: https://jlfaucher.github.io/executor.master/docs/RexxCub/Shame_on_you.html "Shame on you"
[slides]: https://www.dropbox.com/s/d42l8sdodne81eb/slides-sandbox-jlf.pdf?dl=0 "slides-sandbox-jlf.pdf"
[sourceforge_incubator_DocMusings_transformxml]: https://sourceforge.net/p/oorexx/code-0/HEAD/tree/incubator/DocMusings/transformxml/ "SourceForge incubator/DocMusings/transformxml"
[sourceforge_sandbox_jlf]: https://sourceforge.net/p/oorexx/code-0/HEAD/tree/sandbox/jlf "SourceForge sandbox/jlf"
[thoughts_on_ooRexx_and_unicode]: https://docs.google.com/viewer?url=https://jlfaucher.github.io/executor.master/unicode/Thoughts%20on%20ooRexx%20and%20Unicode.pdf
[uni_algo]: https://github.com/uni-algo/uni-algo
[utf8proc]: https://juliastrings.github.io/utf8proc/
[wikipedia_breadth_first_search]: https://en.wikipedia.org/wiki/Breadth-first_search
[wikipedia_fixed_point_combinator]: https://en.wikipedia.org/wiki/Fixed-point_combinator#Y_combinator "Wikipedia fixed point combinator"
[wikipedia_memoization]: https://en.wikipedia.org/wiki/Memoization
