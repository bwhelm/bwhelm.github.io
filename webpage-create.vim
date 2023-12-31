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
        call search('<div id="' . l:id . '" class="sectionDiv w3-container">', 'W')
        let l:line = getline(search('<\/a>', 'W'))
        let l:sectionName = matchstr(l:line, '<\/a>\zs[^<]*')
        execute l:theline
        execute "silent substitute/>" . l:id . "</>" . l:sectionName . "<"
        execute "silent substitute/SeCtIoN/" . l:id
        execute "silent substitute/secNav/secNav secButton" . l:id
    endwhile

    " Delete my name in bibliography entries FIXME: What to do with Enzo?
    silent %substitute/Bennett\_sW\.\_sHelm,//e
    silent %substitute/Helm,\_sBennett\_sW\.\_s*//e
    " silent %substitute/Helm,\_sBennett\_sW\.\_s(\([^)]*\))/\1/e
    silent %substitute/>— />/e

    " Change description lists to ordered lists
    silent %substitute/<dl/<ol reversed/e
    silent %substitute/<\/dl/<\/ol/e
    silent %substitute/<\/\?dt[^>]*>//e
    silent %substitute/<dd/<li/e
    silent %substitute/<\/dd/<\/li/e

    " Get complete list of categories and put <div> around list items
    let l:categoryList = []
    1
    call search('Articles<\/h3>')
    while(search('<span class="categories">', 'W'))
        let [l:startLine, l:startPos] = searchpos('<span class="categories">', 'e')
        let [l:endLine, l:endPos] = searchpos('<\/span>')
        " Categories can span multiple lines. Assume at most l:endLine = l:startLine + 1
        if l:startLine == l:endLine
            let l:keywords = getline(l:startLine)[l:startPos:l:endPos - 2]
        else
            let l:keywords = getline(l:startLine)[l:startPos:]
            let l:keywords .= getline(l:endLine)[:l:endPos - 2]
        endif
        " let l:keywords = search('<span class="categories">\zs\_.\{-}\ze<\/span>')
        let l:keywordsList = split(l:keywords, ',')
        call map(l:keywordsList, 'trim(v:val)')
        call extend(l:categoryList, l:keywordsList)
        call map(l:keywordsList, 'substitute(v:val, "[^A-z]", "", "g")')
        " Put <div> around the list item
        call search('<li', 'b')
        call append(line('.') - 1, '<div class="show filterBib ' . join(l:keywordsList) . '">')
        call search('</li>', '')
        call append(line('.'), '</div>')
    endwhile
    "Clean up categoryList
    call map(l:categoryList, 'trim(v:val)')  " Remove spaces from all items
    call sort(l:categoryList)
    call uniq(l:categoryList)
    " Create navigation/filter bar
    let l:buttonClasses = "bibNav w3-button w3-round-large w3-border w3-border-blue w3-padding-small w3-hover-blue w3-small"
    " l:buttonSpacer is needed to provide vertical spacing between lines of buttons
    let l:buttonSpacer = '      <span style="font-size:1.5em;">&hairsp;</span>'
    let l:bibNavBarList = ['<div id="bibFilterContainer">', '  <button class="w3-blue showall ' . l:buttonClasses . '" onclick="filterBibliography(''showall'')">Show all</button>', l:buttonSpacer]
    for l:category in l:categoryList
        let l:shortCategory = substitute(l:category, '[^A-z]', '', 'g')
        call add(l:bibNavBarList, '  <button class="' . l:shortCategory . ' ' . l:buttonClasses . '" onclick="filterBibliography(''' . l:shortCategory . ''')"> ' . l:category . '</button>')
        call add(l:bibNavBarList, l:buttonSpacer)
    endfor
    call add(l:bibNavBarList, '</div>')
    call search('Articles<\/h3>', 'w')
    call search('<ol reversed class="thebibliography">')
    " FIXME: Uncomment the line below for CATEGORIES
    call append(line('.') - 1, l:bibNavBarList)

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
