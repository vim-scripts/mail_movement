" ft/mail/movement.vim: Movement over email quotes with ]] etc.
"
" DEPENDENCIES:
"   - CountJump.vim autoload script
"   - CountJump/Region.vim autoload script
"
" Copyright: (C) 2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.55.001	22-Jul-2014	file creation from ftplugin/mail_movement.vim
let s:save_cpo = &cpo
set cpo&vim

if v:version < 702 | runtime autoload/CountJump/Region.vim | endif  " The Funcref doesn't trigger the autoload in older Vim versions.

function! s:GetMailSeparatorPattern()
    return '\%(' . join(g:mail_SeparatorPatterns, '\|') . '\)'
endfunction
function! s:MakeQuotePattern( quotePrefix, isInner )
    let l:quoteLevel = strlen(substitute(a:quotePrefix, '[^>]', '', 'g'))
    return '^\%( *>\)\{' . l:quoteLevel . '\}' . (a:isInner ? '\%( *$\| *[^ >]\)' : '')
endfunction


function! s:GetCurrentQuoteNestingPattern()
    let l:quotePrefix = matchstr(getline('.'), '^[ >]*>')
    return (empty(l:quotePrefix) ? '^ *\%(> *\)\+' : s:MakeQuotePattern(l:quotePrefix, 0))
endfunction
function! s:GetDifference( pos )
    let l:difference = (a:pos[0] == 0 ? 0x7FFFFFFF : (a:pos[0] - line('.')))
    return (l:difference < 0 ? -1 * l:difference : l:difference)
endfunction
function! ft#mail#movement#JumpToQuotedRegionOrSeparator( count, pattern, step, isAcrossRegion, isToEnd, ... )
    let l:isToEndOfLine = (a:0 ? a:1 : 0)
    " Jump to the next <count>'th quoted region or email separator line,
    " whichever is closer to the current position. "Closer" here exactly means
    " whichever type lies closer to the current position. This should only
    " matter if separated emails contain quotes; we then want a 2]] jump to the
    " beginning of the second separated email, not to the second quotes
    " contained in the first mail.
    "	X We're here.
    " 	-- message 1 --
    " 	blah
    " 	> quote 1
    " 	> quote 2
    " 	blah
    " 	-- message 2 --
    " 	2]] should jump here.
    " This is implemented by searching for the next region / separator (without
    " moving the cursor), and then choosing the one that exists and is closer to
    " the current position.
    let l:nextRegionPos = CountJump#Region#SearchForNextRegion(1, a:pattern, 1, a:step, a:isAcrossRegion)

    let l:separatorPattern = (a:isToEnd ?
    \	'^' . s:GetMailSeparatorPattern() . '\@!.*\n' . s:GetMailSeparatorPattern() . '\?From:\s\|\%$' :
    \	'^From:\s'
    \)
    let l:separatorSearchOptions = (a:step == -1 ? 'b' : '') . 'W'
    let l:nextSeparatorPos = searchpos(l:separatorPattern, l:separatorSearchOptions . 'n')

    let l:nextRegionDifference = s:GetDifference(l:nextRegionPos)
    let l:nextSeparatorDifference = s:GetDifference(l:nextSeparatorPos)

    if l:nextRegionDifference < l:nextSeparatorDifference && l:nextRegionPos != [0, 0]
	call CountJump#Region#JumpToNextRegion(a:count, a:pattern, 1, a:step, a:isAcrossRegion, l:isToEndOfLine)
    elseif l:nextSeparatorPos != [0, 0]
	call CountJump#CountSearch(a:count, [l:separatorPattern, l:separatorSearchOptions])
	if l:isToEndOfLine
	    normal! $
	endif
    else
	" Ring the bell to indicate that no further match exists.
	execute "normal! \<C-\>\<C-n>\<Esc>"
    endif
endfunction
function! ft#mail#movement#JumpToBeginForward( mode )
    call CountJump#JumpFunc(a:mode, function('ft#mail#movement#JumpToQuotedRegionOrSeparator'), s:GetCurrentQuoteNestingPattern(), 1, 0, 0)
endfunction
function! ft#mail#movement#JumpToBeginBackward( mode )
    call CountJump#JumpFunc(a:mode, function('ft#mail#movement#JumpToQuotedRegionOrSeparator'), s:GetCurrentQuoteNestingPattern(), -1, 1, 0)
endfunction
function! ft#mail#movement#JumpToEndForward( mode )
    let l:useToEndOfLine = (a:mode !=# 'n')
    call CountJump#JumpFunc(a:mode, function('ft#mail#movement#JumpToQuotedRegionOrSeparator'), s:GetCurrentQuoteNestingPattern(), 1, 1, 1, l:useToEndOfLine)
endfunction
function! ft#mail#movement#JumpToEndBackward( mode )
    call CountJump#JumpFunc(a:mode, function('ft#mail#movement#JumpToQuotedRegionOrSeparator'), s:GetCurrentQuoteNestingPattern(), -1, 0, 1)
endfunction


function! s:GetNestedQuotePattern()
    let l:quotePrefix = matchstr(getline('.'), '^[ >]*>')
    return (empty(l:quotePrefix) ? '^ *\%(> *\)\+' : s:MakeQuotePattern(l:quotePrefix, 0) . ' *>')
endfunction
function! ft#mail#movement#JumpToNestedForward( mode )
    call CountJump#JumpFunc(a:mode, function('CountJump#Region#JumpToNextRegion'), s:GetNestedQuotePattern(), 1, 1, 0, 0)
endfunction
function! ft#mail#movement#JumpToNestedBackward( mode )
    call CountJump#JumpFunc(a:mode, function('CountJump#Region#JumpToNextRegion'), s:GetNestedQuotePattern(), 1, -1, 1, 0)
endfunction


function! ft#mail#movement#JumpToQuoteBegin( count, isInner )
    let s:quotePrefix = matchstr(getline('.'), '^[ >]*>')
    if empty(s:quotePrefix)
	if a:isInner
	    let l:separatorPattern = '^' . s:GetMailSeparatorPattern() . '\?From:.*\n\%([A-Za-z0-9_-]\+:.*\n\)*'
	    let l:matchPos = CountJump#CountSearch(a:count, [l:separatorPattern, 'bcW'])
	    if l:matchPos != [0, 0]
		call CountJump#CountSearch(1, [l:separatorPattern, 'ceW'])
		normal! j
	    endif
	    return l:matchPos
	else
	    let l:separatorPattern = '\%(^' . s:GetMailSeparatorPattern() . '\@!.*\n\zs\|\%^\)' . s:GetMailSeparatorPattern() . '\?From:\s'
	    return CountJump#CountSearch(a:count, [l:separatorPattern, 'bcW'])
	endif
    endif

    return CountJump#Region#JumpToRegionEnd(a:count, s:MakeQuotePattern(s:quotePrefix, a:isInner), 1, -1, 0)
endfunction
function! ft#mail#movement#JumpToQuoteEnd( count, isInner )
    if empty(s:quotePrefix)
	let l:separatorPattern = '^' . s:GetMailSeparatorPattern() . '\@!.*\n' . s:GetMailSeparatorPattern() . '\?From:\s\|\%$'
	return CountJump#CountSearch(a:count, [l:separatorPattern, 'W'])
    else
	return CountJump#Region#JumpToRegionEnd(a:count, s:MakeQuotePattern(s:quotePrefix, a:isInner), 1, 1, 0)
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
