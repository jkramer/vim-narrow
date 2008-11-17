

let s:NarrowP = {}


fu! narrow#Narrow(rb, re)
	let n = bufnr("%")

	if has_key(s:NarrowP, n)
		echo "Buffer is already narrowed. Widen first, the select a new region."
	else
		let prr = getline(1, a:rb - 1)
		let por = getline(a:re + 1, "$")
		let s:NarrowP[n] = { "pre": prr, "post": por, "rb": a:rb, "re": a:re }

		exe "silent " . (a:re + 1) . ",$d"
		exe "silent 1," . (a:rb - 1) . "d"

		let s:NarrowP[n]["ch"] = changenr()

		au BufWriteCmd <buffer> call narrow#Save()

		echo "Narrowed. Be careful with undo/time travelling. " . changenr()
	endi
endf


fu! narrow#Widen()
	let n = bufnr("%")

	if has_key(s:NarrowP, n)
		let text = remove(s:NarrowP, n)

		let content = copy(text["pre"])
		let content = extend(content, copy(getline(1, "$")))
		let content = extend(content, copy(text["post"]))

		call setline(1, content)

		au! BufWriteCmd <buffer>

		echo "Widened. " . changenr()
	endi
endf


fu! narrow#Save()
	let n = bufnr("%")
	let name = bufname("%")

	if has_key(s:NarrowP, n)
		let text = s:NarrowP[n]

		let content = copy(text["pre"])
		let content = extend(content, copy(getline(1, "$")))
		let content = extend(content, copy(text["post"]))

		call writefile(content, name)
		echo "Saved something, not sure if it worked."
	endi
endf


fu! narrow#SaveUndo()
	let n = bufnr("%")

	if has_key(s:NarrowP, n)
		let pos = getpos(".")

		silent undo
		if changenr() < s:NarrowP[n]["ch"]
			silent redo
			echo "I said, be careful with undo! Widen first. " . changenr()
			call setpos(".", pos)
		en
	else
		undo
	en
endf


command! -bar -range Narrow  call narrow#Narrow(<line1>, <line2>)
command! -bar Widen  call narrow#Widen()

map u :call narrow#SaveUndo()<Cr>
