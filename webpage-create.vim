" Source this file to load a function that will convert webpage.tex to html

function! s:tohtml() abort  " {{{
    let l:htmlroot = expand("%:p:h") . '/'
    execute "cd" l:htmlroot
    let l:htmlfile = l:htmlroot . "docs/" . expand("%:t:r") . ".html"
    execute '!make4ht --config' l:htmlroot . 'webpage-create.cfg --output-dir' l:htmlroot . 'docs --utf8 --format html5+common_domfilters+latexmk_build %'
    execute '!rm -f' l:htmlroot . expand("%:t:r") . ".html"
    execute '!rm -f' l:htmlroot . expand("%:t:r") . ".css"
    execute "edit" l:htmlfile
    silent %substitute/\s\+/ /ge

    " Fix TOC
    %substitute/<button/\r<button/ge
    1
    while search("SeCtIoN", "W")
        let l:theline = line('.')
        let l:line = getline('.')
        let l:id = matchstr(l:line, ')">\zs[^<]*')
        call search('<div id="' . l:id . '" class="sectionDiv">', 'W')
        let l:line = getline(search('<\/a>', 'W'))
        let l:sectionName = matchstr(l:line, '<\/a>\zs[^<]*')
        execute l:theline
        execute "silent substitute/>" . l:id . "</>" . l:sectionName . "<"
        execute "silent substitute/SeCtIoN/" . l:id
    endwhile

    " Delete my name in bibliography entries
    silent %substitute/Bennett\_sW\.\_sHelm,//e

    " Reverse ordered lists
    silent %substitute/<ol /<ol reversed /ge

    update

    " Open .html file
    " execute "!open" fnameescape(expand("%:r")) . ".html"

    return

    " Delete unneeded tags
    silent %substitute/<a id=\_s*[^>]*><\/a>//ge
    silent %substitute/<!--l. \d\+-->//ge

    " Remove all classes and ids
    silent %substitute/ class="[^"]*"//ge
    silent %substitute/ id="[^"]*"//ge

    " Fix color attributes by adding a '#' where it doesn't exist
    silent %substitute/color:\([^#]\)/color:#\1/ge

    " Remove empty paragraphs
    global/^\s*<p><\/p>\s*$/d

    " Remove <p> ... </p> within <li> tags
    1
    while search("<li>", "We")
        " Add more bottom padding to list item
        normal! i style="padding-bottom:2ex;"

        " Find the next <, and delete the surrounding tag. This works only
        " when the <p> is the next tag after the <li>.
        normal f<dst
    endwhile

    update

    " Open .html file
    execute "!open" fnameescape(expand("%:r")) . ".html"

    " " Remove header and footer
    " if search("\/body>", "w")
    "     .,$ delete_
    " endif
    " if search("<body>", "w")
    "     1,. delete_
    " endif
    " update

    " Return to LaTeX file
    edit #
endfunction " }}}

command! ToHtml :call <SID>tohtml()
