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
        /* Auto-Generate the Outline from Headings */
        const content = document.getElementById("content");
        const tocList = document.querySelector("#toc ul");
        const headings = content.querySelectorAll("h2, h3, h4");

        headings.forEach((heading, index) => {
          if (!heading.id) {
            heading.id = `section-${index}`;
          }

          const li = document.createElement("li");
          li.classList.add(`level-${heading.tagName.toLowerCase()}`);

          const a = document.createElement("a");
          // a.href = `#${heading.id}`;  // Does not work with Github workaround https://htmlpreview.github.io/?...
          a.setAttribute("href", "#" + heading.id);
          a.textContent = heading.textContent;

          li.appendChild(a);
          tocList.appendChild(li);
        });
    </script>

    <script>
        /* Highlight Active Section While Scrolling */
        const tocLinks = document.querySelectorAll("#toc a");

        const observer = new IntersectionObserver(
          entries => {
            entries.forEach(entry => {
              if (entry.isIntersecting) {
                tocLinks.forEach(link =>
                  link.classList.toggle(
                    "active",
                    link.getAttribute("href") === `#${entry.target.id}`
                  )
                );
              }
            });
          },
          {
            rootMargin: "-80px 0px -70% 0px"
          }
        );

        headings.forEach(h => observer.observe(h));
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

::END

--------------------------------------------------------------------------------
-- Page footer                                                                --
--------------------------------------------------------------------------------

::Routine md2html.Footer Public

  return -- jlf

  Use Arg array

  year = Date("S")[1,4]

  Loop line Over .resources~PageFooter~makeString~changeStr("%year%",year)
    array~append( line )
  End

::Resource PageFooter
      <hr class="before-footer">
      <div class="panel panel-default footer">
        <div class="panel-heading text-center">
          <small>Copyright &copy; 1992&ndash;%year%,
             <a href="https://www.epbcn.com/">EPBCN</a> &amp; <a href="https://rexx.epbcn.com/josep-maria-blasco/">Josep Maria Blasco</a>.
             This site is powered by <a href="https://sourceforge.net/projects/oorexx/">ooRexx</a> and
             <a href="https://rexx.epbcn.com/software/rexxhttp/">RexxHttp</a>.
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