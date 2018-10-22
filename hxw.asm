.386
.model flat,stdcall
option casemap:none

;include文件夹

include windows.inc
include user32.inc
includelib user32.lib
include kernel32.inc
includelib kernel32.lib
include gdi32.inc
includelib gdi32.lib
include comctl32.inc
includelib comctl32.lib


;数据段
.data?
hInstance dd ?
hWinMain dd ?  ;主窗口
hCursorMove dd ? ;Cursor when move
hCursorMain dd ? ;Cursor when normal


.const
szClassName db 'MyClass',0
szCaptionMain db 'MyPainter',0
szText db 'hello World',0

;代码段
.code

_ProcWinMain proc uses ebx edi esi,hWnd,uMsg,wParam,lParam
		local @stPs:PAINTSTRUCT
		local @stRect:RECT
		local @hDc
		mov eax,uMsg
		.if eax == WM_CLOSE				;关闭窗口
			invoke DestroyWindow,hWinMain
			invoke PostQuitMessage,NULL
		.elseif eax == WM_CREATE
			mov ebx,hWnd

		.elseif eax == WM_PAINT
			mov ebx,hWnd
			.if ebx == hWinMain
				invoke BeginPaint,hWnd,addr @stPs
				mov @hDc,eax
				invoke GetClientRect,hWnd,addr @stRect
				invoke DrawText,@hDc,addr szText,-1,addr @stRect,DT_SINGLELINE or DT_CENTER or DT_VCENTER
				invoke EndPaint,hWnd,addr @stPs
			.endif
		.else 
			invoke DefWindowProc,hWnd,uMsg,wParam,lParam
			ret
		.endif
		xor eax,eax
		ret
_ProcWinMain endp

_WinMain proc
		local @stWndClass:WNDCLASSEX
		local @stMsg:MSG

		invoke GetModuleHandle,NULL  ;获取调用模块句柄
		mov hInstance,eax
		invoke RtlZeroMemory,addr @stWndClass,sizeof @stWndClass;填0

		;注册窗口类
		invoke LoadCursor,0,IDC_ARROW
		mov @stWndClass.hCursor,eax
		push hInstance
		pop @stWndClass.hInstance
		mov @stWndClass.cbSize,sizeof WNDCLASSEX
		mov @stWndClass.style,CS_HREDRAW or CS_VREDRAW
		mov @stWndClass.lpfnWndProc,offset  _ProcWinMain
		mov @stWndClass.hbrBackground,COLOR_WINDOW+1
		mov @stWndClass.lpszClassName,offset szClassName
		invoke RegisterClassEx,addr @stWndClass

		;建立并显示窗口
		invoke CreateWindowEx,WS_EX_CLIENTEDGE,offset szClassName,offset szCaptionMain,WS_OVERLAPPEDWINDOW,100,100,200,300,NULL,NULL,hInstance,NULL
		mov hWinMain,eax
		invoke ShowWindow,hWinMain,SW_SHOWNORMAL
		invoke UpdateWindow,hWinMain

		;消息循环
		.while TRUE
			invoke GetMessage,addr @stMsg,NULL,0,0
			.break .if eax == 0
			invoke TranslateMessage,addr @stMsg
			invoke DispatchMessage,addr @stMsg
		.endw

		ret
_WinMain endp

start:
	call _WinMain
	invoke ExitProcess,NULL
end start
