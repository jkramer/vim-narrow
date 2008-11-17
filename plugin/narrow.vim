" ****************************************************************************
" File:             narrow.vim
" Author:           Jonas Kramer
" Version:          0.1
" Last Modified:    2008-11-17
" Copyright:        Copyright (C) 2008 by Jonas Kramer. Published under the
"                   terms of the Artistic License 2.0.
" ****************************************************************************
" Installation: Copy this script into your plugin folder.
" Usage: Call the command :Narrow with a range to zoom into the range area.
" Call :Widen to zoom out again.
" WARNING! Be careful when doing undo operations in a narrowed buffer. If you
" undo the :Narrow action, :Widen will fail miserable and you'll probably have
" the hidden parts doubled in your buffer. The 'u' key is remapped to a save
" undo function, but you can still mess this plugin up with :earlier, g- etc.
" Also make sure that you don't mess with the buffers autocmd BufWriteCmd
" hook, as it is set to a function that allows saving of the whole buffer
" instead of only the narrowed region in narrowed mode. Otherwise, when saving
" in a narrowed buffer, only the region you zoomed into would be saved.
" ****************************************************************************

if exists('g:loaded_narrow')
  finish
endif

let s:save_cpoptions = &cpoptions
set cpoptions&vim




fu! narrow#Narrow(rb, re)
	if exists('b:narrow_info')
		echo "Buffer is already narrowed. Widen first, then select a new region."
	else
		" Save modified state.
		let modified = &l:modified

		let prr = getline(1, a:rb - 1)
		let por = getline(a:re + 1, "$")
		let b:narrow_info = { "pre": prr, "post": por, "rb": a:rb, "re": a:re }

		exe "silent " . (a:re + 1) . ",$d"
		exe "silent 1," . (a:rb - 1) . "d"

		let b:narrow_info.ch = changenr()

                augroup plugin-narrow
                  au BufWriteCmd <buffer> call narrow#Save()
                augroup END

		" If buffer wasn't modify, unset modified flag.
		if !modified
			set nomodified
		en

		echo "Narrowed. Be careful with undo/time travelling."
	endi
endf


fu! narrow#Widen()
	if exists('b:narrow_info')
		" Save modified state.
		let modified = &l:modified

		" Save position.
		let pos = getpos(".")

		let content = copy(b:narrow_info.pre)

		let pos[1] = pos[1] + len(content)

		let content = extend(content, copy(getline(1, "$")))
		let content = extend(content, copy(b:narrow_info.post))

		call setline(1, content)

                augroup plugin-narrow
                  au! BufWriteCmd <buffer>
                augroup END

		" If buffer wasn't modify, unset modified flag.
		if !modified
			setlocal nomodified
		en

		call setpos('.', pos)
                unlet b:narrow_info

		echo "Widened."
	endi
endf


fu! narrow#Save()
	let name = bufname("%")

        if exists('b:narrow_info')
		let content = copy(b:narrow_info.pre)
		let content = extend(content, copy(getline(1, "$")))
		let content = extend(content, copy(b:narrow_info.post))

		call writefile(content, name)
		set nomodified
		echo "Saved something, not sure if it worked."
	endi
endf


fu! s:undo_wrapper()
        if exists('b:narrow_info')
		let pos = getpos(".")

		silent undo
		if changenr() < b:narrow_info.ch
			silent redo
			echo "I said, be careful with undo! Widen first."
			call setpos(".", pos)
		en
	else
		undo
	en
endf


command! -bar -range Narrow call narrow#Narrow(<line1>, <line2>)
command! -bar Widen call narrow#Widen()

silent! nnoremap <silent> u  :<C-u>call <SID>undo_wrapper()<CR>




let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions

let g:loaded_narrow = 1

" __END__
