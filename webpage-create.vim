" Source this file to load a function that will convert webpage.tex to html

function! s:tohtml() abort  " {{{
    let l:htmlroot = expand("%:p:h") . '/'
    execute "cd" l:htmlroot
    let l:htmlfile = l:htmlroot . "docs/" . expand("%:t:r") . ".html"
    let l:cssfile = l:htmlroot . "docs/" . expand("%:t:r") . ".css"
    let l:robotsfile = l:htmlroot . "docs/robots.txt"
    " Get updated `robots.txt` file
    call system('curl "https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/refs/heads/main/robots.txt" > ' . l:robotsfile)
    execute '!make4ht --config' l:htmlroot . 'webpage-create.cfg --output-dir' l:htmlroot . 'docs --utf8 --format html5+common_domfilters+latexmk_build %'
    " execute '!make4ht --output-dir' l:htmlroot . 'docs --utf8 --format html5+common_domfilters+latexmk_build %'
    execute '!rm -f' l:htmlroot . expand("%:t:r") . ".html"
    execute '!rm -f' l:htmlroot . expand("%:t:r") . ".css"

    execute "edit" l:htmlfile
    silent %substitute/\S\zs\s\+/ /ge

    " Fix TOC
    %substitute/<button/\r<button/ge
    1
    while search("SeCtIoN", "W")
        let l:lineNumber = line('.')
        let l:theLine = getline('.')
        let l:id = matchstr(l:theLine, ')[''"]>\zs[^<]*')
        call search('<div class=[''"]sectionDiv[''"] id=[''"]' . l:id . '[''"]>', 'W')
        let l:theLine = getline(search('<\/a>', 'W'))
        if match(l:theLine, '<butname>') > -1
            " If button name is provided, use that (and delete it from the line)
            let l:sectionName = matchstr(l:theLine, '<butname>\zs[^<]*')
            silent substitute/<butname>[^<]*<\/butname>//
        else  " Otherwise, use heading name
            let l:sectionName = matchstr(l:theLine, '<\/a>\zs[^<]*')
        endif
        execute l:lineNumber
        execute "silent substitute/>" . l:id . "</>" . l:sectionName . "<"
        execute "silent substitute/SeCtIoN/" . l:id
        execute "silent substitute/secNav/secNav secButton" . l:id
    endwhile

    " Put jpgs of books into webpage
    1
    let l:savereg = @a
    call search('Books<\/p><\/h3>')
    let l:bookend = search('<\/dl>', 'n')  " Find end of book section
    while search('<dt class=[''"]thebibliography[''"] id=[''"]X\d\+-[^''"]*[''"]', 'We') && line('.') < l:bookend  " Search for <dt> tag before end
        " copy the book's bibtex id, whcih is used for the .jpg filename
        let l:line = getline('.')
        let l:filename = matchstr(l:line, 'id=[''"]X\d\+-\zs[^''"]*') . '.jpg'
        call search('<dd\_.\{-}>', 'e')  " Find after the <dd> tag
        " Append the image in a div if the image exists
        if findfile(l:filename, './docs') != ""
            call append(line('.'), '<div class=''bookcontainer''><div class=''imgfloat''><div class=''imgborder''><img src=''' . l:filename . ''' style=''width:100%''></div></div>')
            call search('<details')  " Put end of div before abstract
            normal! i</div>
        endif
        call search('<\/details>', 'e')  " Add horizontal rule after abstract
        normal! a<hr style='clear: both;'>
    endwhile
    let @a = l:savereg

    " Get complete list of categories and put <div> around list items
    let l:categoryList = []
    1
    call search('Articles<\/p><\/h3>')
    while(search('<span class=[''"]categories[''"]>', 'W'))
        let [l:startLine, l:startPos] = searchpos('<span class=[''"]categories[''"]>', 'e')
        let [l:endLine, l:endPos] = searchpos('<\/span>')
        " Categories can span multiple lines. Assume at most l:endLine = l:startLine + 1
        if l:startLine == l:endLine
            let l:keywords = getline(l:startLine)[l:startPos:l:endPos - 2]
        else
            let l:keywords = getline(l:startLine)[l:startPos:]
            let l:keywords .= getline(l:endLine)[:l:endPos - 2]
        endif
        " let l:keywords = search('<span class=[''"]categories[''"]>\zs\_.\{-}\ze<\/span>')
        let l:keywordsList = split(l:keywords, ',')
        call map(l:keywordsList, 'trim(v:val)')  " Remove spaces around items
        call map(l:keywordsList, 'substitute(v:val, "\\s\\+", " ", "g")')  " Remove spaces within items
        call extend(l:categoryList, l:keywordsList)
        call map(l:keywordsList, 'substitute(v:val, "[^A-z]", "", "g")')
        " Put <div> around the list item -- above `<dt...>` and below `</dd>`
        call search('<dt', 'b')
        normal! i
        call append(line('.') - 1, '<div class=''show filterBib ' . join(l:keywordsList) . '''>')
        call search('<\/dd>', 'e')
        normal! a
        call append(line('.') - 1, '</div>')
    endwhile
    "Clean up categoryList
    call map(l:categoryList, 'trim(v:val)')  " Remove spaces from all items
    call sort(l:categoryList)
    call uniq(l:categoryList)
    " Create navigation/filter bar
    let l:buttonClasses = "bibNav w3-button w3-round-large w3-border w3-border-teal w3-padding-small w3-hover-teal w3-small"
    " l:buttonSpacer is needed to provide vertical spacing between lines of buttons
    let l:buttonSpacer = '      <span style=''font-size:1.5em;''>&hairsp;</span>'
    let l:bibNavBarList = ['<div id=''bibFilterContainer''>', '  <button class=''w3-teal showall ' . l:buttonClasses . ''' onclick=''filterBibliography("showall")''>Show all</button>', l:buttonSpacer]
    for l:category in l:categoryList
        let l:shortCategory = substitute(l:category, '[^A-z]', '', 'g')
        call add(l:bibNavBarList, '  <button class=''' . l:shortCategory . ' ' . l:buttonClasses . ''' onclick=''filterBibliography("' . l:shortCategory . '")''> ' . l:category . '</button>')
        call add(l:bibNavBarList, l:buttonSpacer)
    endfor
    call add(l:bibNavBarList, '</div>')
    call search('Articles<\/p><\/h3>', 'w')
    call search('<dl class=[''"]thebibliography[''"]>')
    " Add categories
    call append(line('.') - 1, l:bibNavBarList)
    " Convert HTML-coded double quotes
    %substitute/&#39;/"/ge

    " Remove space after opening quote (which happens for articles that have
    " linked titles)
    %substitute/“ /“/ge

    " " If using `marginyear=true`, put year into description field
    " 1
    " while(search('reversemarginpar', 'W'))  " This finds marginyears
    "     normal dat                          " Delete around than <span>
    "     call search('.<\/dt>', 'bW')        " Search for previous description tag
    "     normal P
    "     +
    " endwhile

    " OLD STUFF
    " " Delete unneeded tags
    " silent %substitute/<a id=\_s*[^>]*><\/a>//ge
    " silent %substitute/<!--l. \d\+-->//ge

    " " Fix color attributes by adding a '#' where it doesn't exist
    " silent %substitute/color:\([^#]\)/color:#\1/ge

    " " Remove empty paragraphs
    " global/^\s*<p><\/p>\s*$/d

    " " Remove <p> ... </p> within <li> tags
    " 1
    " while search("<li>", "We")
    "     " Add more bottom padding to list item
    "     normal! i style="padding-bottom:2ex;"

    "     " Find the next <, and delete the surrounding tag. This works only
    "     " when the <p> is the next tag after the <li>.
    "     normal f<dst
    " endwhile

    update

    " Open .html file
    execute "!open -g" fnameescape(expand("%:r")) . ".html"

    " Return to LaTeX file
    edit #
endfunction " }}}

command! ToHtml :call <SID>tohtml()
