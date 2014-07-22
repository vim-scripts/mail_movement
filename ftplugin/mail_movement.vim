" mail_movement.vim: Movement over email quotes with ]] etc.
"
" DEPENDENCIES:
"   - CountJump/Motion.vim autoload script
"   - CountJump/TextObject.vim autoload script
"
" Copyright: (C) 2010-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.55.010	22-Jul-2014	Extract functions into separate autoload script.
"                               Introduce configuration variables to be able to
"                               reconfigure the mappings.
"   1.54.009	21-Sep-2011	Avoid use of s:function() by using autoload
"				function name.
"   1.53.008	13-Jun-2011	FIX: Directly ring the bell to avoid problems
"				when running under :silent!.
"   1.52.007	20-Dec-2010	Adapted to CountJump#Region#JumpToNextRegion()
"				again returning jump position in version 1.40.
"   1.51.006	19-Dec-2010	ENH: ][ mapping in operator-pending and visual
"				mode now also operates over / select the last
"				line of the quote. This is what the user
"				expects.
"				Adapted to changed interface of
"				CountJump#Region#JumpToNextRegion(): Additional
"				a:isToEndOfLine argument, and does not return
"				position any more.
"				Adapted to changed interface of
"				CountJump#JumpFunc(): Need to ring the bell
"				myself, no need for returning position any more.
"   1.51.005	18-Dec-2010	Renamed CountJump#Region#Jump() to
"				CountJump#JumpFunc().
"   1.51.004	18-Dec-2010	Adapted to extended interface of
"				CountJump#Region#SearchForNextRegion() in
"				CountJump 1.30.
"   1.50.003	08-Aug-2010	ENH: Added support for MS Outlook-style quoting
"				with email separator and mail headers. Whether
"				regions of prefixed lines or lines preceded by
"				separator + headers are used is determined by
"				context.
"   1.00.002	03-Aug-2010	Published.
"	001	19-Jul-2010	file creation from diff_movement.vim

" Avoid installing when in unsupported Vim version.
if v:version < 700
    finish
endif
let s:save_cpo = &cpo
set cpo&vim

if v:version < 702 | runtime autoload/ft/mail/movement.vim | endif  " The Funcref doesn't trigger the autoload in older Vim versions.

"- configuration ---------------------------------------------------------------

" List of patterns for email separator lines. These are anchored at the
" beginning of the line (implicit /^/, do not add) and must include the end of
" the separator line by concluding the pattern with /\n/.
if ! exists('g:mail_SeparatorPatterns')
    let g:mail_SeparatorPatterns = [ '-\+Original Message-\+\n', '_\+\n' ]
endif

if ! exists('g:mail_movement_BeginMapping')
    let g:mail_movement_BeginMapping = ''
endif
if ! exists('g:mail_movement_EndMapping')
    let g:mail_movement_EndMapping = ''
endif
if ! exists('g:mail_movement_NestedMapping')
    let g:mail_movement_NestedMapping = '+'
endif
if ! exists('g:mail_movement_QuoteTextObject')
    let g:mail_movement_QuoteTextObject = 'q'
endif

"- mappings --------------------------------------------------------------------

call CountJump#Motion#MakeBracketMotionWithJumpFunctions('<buffer>', g:mail_movement_BeginMapping, g:mail_movement_EndMapping,
\   function('ft#mail#movement#JumpToBeginForward'),
\   function('ft#mail#movement#JumpToBeginBackward'),
\   '',
\   function('ft#mail#movement#JumpToEndBackward'),
\   0
\)
call CountJump#Motion#MakeBracketMotionWithJumpFunctions('<buffer>', g:mail_movement_BeginMapping, g:mail_movement_EndMapping,
\   '',
\   '',
\   function('ft#mail#movement#JumpToEndForward'),
\   '',
\   1
\)


call CountJump#Motion#MakeBracketMotionWithJumpFunctions('<buffer>', g:mail_movement_NestedMapping, '',
\   function('ft#mail#movement#JumpToNestedForward'),
\   function('ft#mail#movement#JumpToNestedBackward'),
\   0,
\   0,
\   0
\)


call CountJump#TextObject#MakeWithJumpFunctions('<buffer>', g:mail_movement_QuoteTextObject, 'aI', 'V',
\   function('ft#mail#movement#JumpToQuoteBegin'),
\   function('ft#mail#movement#JumpToQuoteEnd'),
\)

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
