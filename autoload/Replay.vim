" Replay.vim - Replay your editing Session
" -------------------------------------------------------------
" Version: 0.3
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Fri, 27 Aug 2010 14:18:31 +0200
"
" Script: http://www.vim.org/scripts/script.php?script_id=
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"              The VIM LICENSE applies to NrrwRgn.vim 
"              (see |copyright|) except use "Replay.vim" 
"              instead of "Vim".
"              No warranty, express or implied.
"    *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3216 4 :AutoInstall: Replay.vim
"
fun! <sid>WarningMsg(msg)"{{{1
        echohl WarningMsg
        let msg = "ReplayPlugin: " . a:msg
        if exists(":unsilent") == 2
                unsilent echomsg msg
        else
                echomsg msg
        endif
        echohl Normal
        let v:errmsg = msg
endfun

fun! <sid>Init() "{{{1
    if !exists("b:replay_data")
        let b:replay_data={}
		let b:replay_data.Default={}
		let b:replay_data.Default.start=0
		let b:replay_data.Default.start_time=localtime()
    endif
    " Customization
    let s:replay_speed  = (exists("g:replay_speed")   ? g:replay_speed    : 200)
endfun 

fun! Replay#Replay(tag) "{{{1
    call <sid>Init()
	if empty(a:tag)
		let tag='Default'
	else
		let tag=a:tag
	endif
	if !exists("b:replay_data.".tag)
		call <sid>WarningMsg("Tag " . tag . " does not exist!")
		return
	endif
	let curpos=winsaveview()
    let undo_change=get(b:replay_data, tag)
    let stop_change=<sid>LastChange()

    if undo_change.start==0
        undo 1
        norm! g-
    else
        if exists("undo_change.stop")
            let stop_change=undo_change.stop
        endif
        exe "undo " undo_change.start
    endif
    let t=changenr()
    while t < stop_change
        silent norm! g+
		norm! zz
		redraw!
        exe "sleep " .s:replay_speed . 'm'
		let t=changenr()
    endw
	call winrestview(curpos)
endfun

fun! <sid>LastChange() "{{{1
	redir => a | silent! undolist |redir end
	let b=split(a, "\n")[-1]
	return split(b)[0]
endfun

fun! Replay#TagState(tag, bang) "{{{1
	call <sid>Init()
    let tag=(empty(a:tag) ? 'Default' : a:tag)
    if exists("b:replay_data.".tag) && !a:bang
        call <sid>WarningMsg("Tag " . tag . " already exists!")
        return
    else
		let b:replay_data[tag] = {}
        let b:replay_data[tag].start = changenr()
        let b:replay_data[tag].start_time = localtime()
    endif
endfun

fun! Replay#TagStopState(tag) "{{{1
	call <sid>Init()
    "let tag=(empty(a:tag) ? 'Default' : a:tag)
	let tag=(empty(a:tag) ? <sid>LastStartedRecording() : a:tag)
    if !exists("b:replay_data.".tag) "&& tag != 'Default'
        call <sid>WarningMsg("Tag " . tag . " not found!")
        return
    else
		let change=changenr()
		if tag == 'Default'
			let b:replay_data[tag] = {}
		endif
		" If stop is before start, swap both changes
		if !exists("b:replay_data[tag].start")
			let b:replay_data[tag].start = 0
			let b:replay_data[tag].stop = change
			let b:replay_data[tag].stop_time = localtime()
		elseif b:replay_data[tag].start > change
			let b:replay_data[tag].stop = b:replay_data[tag].start
			let b:replay_data[tag].start = change
			let b:replay_data[tag].stop_time = localtime()
		else
			let b:replay_data[tag].stop = change
			let b:replay_data[tag].stop_time = localtime()
		endif
    endif
	call <sid>WarningMsg("Stopped Recording of: " . tag . " tag")
endfun

fun! <sid>MaxTagLength() "{{{1
    let list=keys(b:replay_data)
    call map(list, 'len(v:val)')
    return max(list)
endfun

fun! Replay#ListStates() "{{{1
    call <sid>Init()
    echohl Title
    let len=<sid>MaxTagLength()
	if len==0
		let len=3
	endif
    echo printf("%*.*s\t%s\t\t%s\t\t%s\t%s\n",len,len,"Tag", "Starttime", "Start", "Stoptime", "Stop")
    echohl Normal
	echo printf("%s", '===================================================================================')
    for key in keys(b:replay_data)
        echo printf("%*.*s\t%s\t%s\t%s\t%s", len,len, key,
					\(exists("b:replay_data[key].start_time") ? strftime("%d.%m.%Y %H:%M:%S", b:replay_data[key].start_time) : repeat('-',19)),
					\(exists("b:replay_data[key].start")      ? b:replay_data[key].start                                     : ' '),
					\(exists("b:replay_data[key].stop_time")  ? strftime("%d.%m.%Y %H:%M:%S", b:replay_data[key].stop_time)  : repeat('-',19)),
					\(exists("b:replay_data[key].stop")       ? b:replay_data[key].stop                                      : ' '))
    endfor
endfun

fun! Replay#CompleteTags(A,L,P) "{{{1
	 cal <sid>Init()
	 return join(sort(keys(b:replay_data)),"\n")
endfun

fun! <sid>LastStartedRecording() "{{{1
	let a=copy(b:replay_data)
	call filter(a, '!exists("v:val.stop")')
	let key=''
	let time=0
	for item in keys(a)
		if a[item].start_time > time
		   let time=a[item].start_time
		   let key = item
		endif
	endfor
	return key
endfun
" Modeline "{{{1
" vim: ts=4 sts=4 fdm=marker com+=l\:\" fdl=0