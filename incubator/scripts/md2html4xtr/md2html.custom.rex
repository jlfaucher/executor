/******************************************************************************/
/*                                                                            */
/* md2html.custom.rex -- SAMPLE customization layer for md2html               */
/* ============================================================               */
/*                                                                            */
/* This program is part of the Rexx Parser package                            */
/* [See https://rexx.epbcn.com/rexx-parser/]                                  */
/*                                                                            */
/* Copyright (c) 2024-2026 Josep Maria Blasco <josep.maria.blasco@epbcn.com>  */
/*                                                                            */
/* License: Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0)  */
/*                                                                            */
/* Version history:                                                           */
/*                                                                            */
/* Date     Version Details                                                   */
/* -------- ------- --------------------------------------------------------- */
/* 20241223    0.4a First version, based cgi/on rexx.epbcn.com.optional.cls   */
/*                                                                            */
/******************************************************************************/

pkgLocal = .Context~package~local

-- .Exception will be used by md2html.Exception below
pkgLocal~Exception = .Stem~new
.Exception[] = 0
.Exception["test_fenced_code_blocks.md"] = 1

-- .TranslateFilename will be used by md2html.TranslateFilename below
pkgLocal~TranslateFilename = .Stem~new
.TranslateFilename[] = .Nil             -- .Nil means no change
.TranslateFilename["readme.md"] = "index" -- Note: index has no extension

-- .FilenameSpecificStyle will be used by md2html.FilenameSpecificStyle below
pkgLocal~FilenameSpecificStyle = .Stem~new
.FilenameSpecificStyle[] = ""             -- .Nil means no change
.FilenameSpecificStyle["article.md"] = "article"
.FilenameSpecificStyle["slides.md" ] = "slides"

-- Output files will have this extension. See md2html.Extension
pkgLocal~Extension = "html"

-- The following set of routines is provided AS A SAMPLE ONLY.
-- You will have to customize them (and default.m2html) for your own needs.

--------------------------------------------------------------------------------
-- Page header -- Displays a top menu, a logo, and the page title             --
--------------------------------------------------------------------------------

::Routine md2html.Header Public

  return -- jlf

  Use Arg array, title

  Do line Over .resources~Header~makeString~changeStr("%title%",title)
    array~append( line )
  End

::Resource Header
      <nav class="navbar navbar-inverse x-header">
        <div class='navbar-header'>
          <button type='button' class='navbar-toggle' data-toggle='collapse' data-target='#menuREXX'>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="https://rexx.epbcn.com/" aria-label="REXX">
            <span class="micrologo"><b style="color:#ad564a">EP<span style="color:#f57a69">BCN / Rexx</span></b></span>
          </a>
        </div>
        <div class="collapse navbar-collapse" id="menuREXX">
          <ul class="nav navbar-nav navbar-right">
            <li><a href="https://rexx.epbcn.com/software/">SOFTWARE</a></li>
            <li><a href="https://rexx.epbcn.com/publications/">PUBLICATIONS</a></li>
            <li><a href="https://rexx.epbcn.com/symposium/">SYMPOSIA</a></li>
            <li><a href="https://rexx.epbcn.com/epbcn/">EPBCN</a></li>
            <li><a href="https://rexx.epbcn.com/josep-maria-blasco/">ABOUT ME</a></li>
          </ul>
        </div>
      </nav>
      <div class="row">
        <div>
          <h1>The Rexx-Parser</h1>
        </div>
      </div>
      <br>
::END

--------------------------------------------------------------------------------
-- Content header                                                             --                                    --
--------------------------------------------------------------------------------

::Routine md2html.ContentHeader Public

  Use Arg filename

  -- You might generate a breadcrumb from parts of the filename here

--------------------------------------------------------------------------------
-- Side bar                                                                   --
--------------------------------------------------------------------------------

::Routine md2html.SideBar Public

  Use Arg array

  Loop line Over .resources~SideBar
    array~append( line )
  End

::Resource SideBar

    <aside class="outline">
      <nav id="toc">
        <strong>Outline</strong>
        <ul></ul>
      </nav>
    </aside>

    <script>
        // TOC with collapse / expand
        (function () {
          const content = document.getElementById("content");
          const tocRoot = document.querySelector("#toc ul");
          const headings = content.querySelectorAll("h1, h2, h3, h4");

          // Stack to build hierarchy
          const stack = [{ level: 0, ul: tocRoot }];

          headings.forEach((heading, index) => {
            const level = parseInt(heading.tagName.substring(1), 10);

            if (!heading.id) {
              heading.id = `section-${index}`;
            }

            // ---- TOC item ----
            const li = document.createElement("li");
            li.className = `level-${heading.tagName.toLowerCase()}`;

            const a = document.createElement("a");
            a.setAttribute("href", "#" + heading.id);

            // Caret (always present, may be empty)
            const caret = document.createElement("span");
            caret.className = "toc-caret";

            // Text
            const text = document.createElement("span");
            text.className = "toc-text";
            text.textContent = heading.textContent;

            a.appendChild(caret);
            a.appendChild(text);
            li.appendChild(a);

            // ---- Find correct parent ----
            while (stack[stack.length - 1].level >= level) {
              stack.pop();
            }

            stack[stack.length - 1].ul.appendChild(li);

            // ---- Child container (always created) ----
            const childUl = document.createElement("ul");
            childUl.className = "toc-children";
            li.appendChild(childUl);

            stack.push({ level, ul: childUl });
          });

          // ---- Enable caret-only toggling ----
          document.querySelectorAll("#toc li").forEach(li => {
            const childUl = li.querySelector(":scope > ul");
            const caret = li.querySelector(":scope > a > .toc-caret");

            if (childUl && childUl.children.length > 0) {
              li.classList.add("has-children", "expanded"); // expanded by default

              caret.addEventListener("click", function (e) {
                e.preventDefault();
                e.stopPropagation();
                li.classList.toggle("collapsed");
                li.classList.toggle("expanded");
              });
            }
          });
        })();
    </script>

    <script>
        // Highlight Active Section While Scrolling
        (function () {
          const toc = document.getElementById("toc");
          const tocLinks = toc.querySelectorAll("a");
          const tocItems = toc.querySelectorAll("li");
          const headings = Array.from(
            document.querySelectorAll("#content h1, #content h2, #content h3, #content h4")
          );

          function updateActiveToc() {
            let current = null;

            for (const h of headings) {
              if (h.getBoundingClientRect().top <= 80) {
                current = h;
              } else {
                break;
              }
            }

            /* RESET STATE */
            tocLinks.forEach(a => a.classList.remove("active"));
            tocItems.forEach(li => li.classList.remove("active-parent"));

            if (current) {
              const link = toc.querySelector(`a[href="#${current.id}"]`);
              if (link) {
                link.classList.add("active");
                markParentsActive(link);
                ensureTocItemVisible(link);
              }
            }
          }

          function markParentsActive(link) {
            let li = link.closest("li");

            while (li) {
              li.classList.add("active-parent");
              li = li.parentElement.closest("li");
            }
          }

          function ensureTocItemVisible(link) {
            const toc = document.getElementById("toc");
            const rect = link.getBoundingClientRect();
            const tocRect = toc.getBoundingClientRect();

            if (rect.top < tocRect.top || rect.bottom > tocRect.bottom) {
              link.scrollIntoView({
                block: "nearest",
                inline: "nearest"
              });
            }
          }

          window.addEventListener("scroll", updateActiveToc, { passive: true });
          updateActiveToc();
        })();
    </script>

    <script>
        /* Drag-to-Resize */
        (function () {
          const handle = document.querySelector(".resize-handle");
          const toc = document.querySelector(".toc-pane");

          let startX, startWidth;

          handle.addEventListener("mousedown", function (e) {
            startX = e.clientX;
            startWidth = toc.offsetWidth;

            document.addEventListener("mousemove", onMouseMove);
            document.addEventListener("mouseup", onMouseUp);
            e.preventDefault();
          });

          function onMouseMove(e) {
            const delta = startX - e.clientX;
            const newWidth = Math.min(
              420,
              Math.max(180, startWidth + delta)
            );

            toc.style.flexBasis = newWidth + "px";
          }

          function onMouseUp() {
            document.removeEventListener("mousemove", onMouseMove);
            document.removeEventListener("mouseup", onMouseUp);
          }
        })();
    </script>

    <script>
        // Workaround to have the TOC working with https://htmlpreview.github.io/?...
        // Watch the DOM and remove <base> whenever it appears.
        (function () {
          function removeBase() {
            const base = document.querySelector("base");
            if (base) {
              base.remove();
            }
          }

          // Run immediately
          removeBase();

          // Watch for late injection
          const observer = new MutationObserver(removeBase);
          observer.observe(document.head || document.documentElement, {
            childList: true,
            subtree: true
          });
        })();
    </script>

::END

--------------------------------------------------------------------------------
-- Page footer                                                                --
--------------------------------------------------------------------------------

::Routine md2html.Footer Public

  Use Arg array

  Loop line Over .resources~PageFooter
    array~append( line )
  End

::Resource PageFooter
      <style>
        small a { font-size: 100%; }
      </style>
      <hr class="before-footer">
      <div class="panel panel-default footer">
        <div class="panel-heading text-center">
          <small>
             This page was generated by
             <a href="https://rexx.epbcn.com/rexx-parser/doc/utilities/md2html/">md2html</a>
             using
             <a href="https://github.com/jlfaucher/executor/tree/master/incubator/scripts/md2html4xtr">custom files</a>.
          </small>
        </div>
      </div>
::END

--------------------------------------------------------------------------------
-- Exceptions (files that should not be processed)                            --
--------------------------------------------------------------------------------

::Routine md2html.Exception Public

  Return .Exception[Arg(1)]

--------------------------------------------------------------------------------
-- Extension the output HTML files will have                                  --
--------------------------------------------------------------------------------

::Routine md2html.Extension Public

  Return .Extension

--------------------------------------------------------------------------------
-- Returns the translated filename                                            --
--------------------------------------------------------------------------------

::Routine md2html.TranslateFilename Public

  Return .TranslateFilename[Arg(1)]     -- .Nil when no change

--------------------------------------------------------------------------------
-- Returns the translated filename                                            --
--------------------------------------------------------------------------------

::Routine md2html.FilenameSpecificStyle Public

  Return .FilenameSpecificStyle[Arg(1)] -- A boolean