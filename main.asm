.386
.model flat,stdcall
option casemap:none

include windows.inc
include user32.inc
includelib user32.lib
include kernel32.inc
includelib kernel32.lib
include gdi32.inc
includelib gdi32.lib
include comctl32.inc
includelib comctl32.lib
include comdlg32.inc
includelib comdlg32.lib
include msvcrt.inc
includelib msvcrt.lib

IDA_MENU	equ			101

IDM_MENU                equ			102
IDR_TOOLBAR1		equ			105
IDB_BITMAP7          equ          108
IDM_OPEN				equ			40001
IDM_SAVE				equ			40002
IDM_PENCIL			equ			40003
IDM_ERASER			equ			40004
IDM_COLOR			equ			40009
IDM_LINE					equ			40006
IDM_RENDLINE		equ			40008
ID_OPEN_FILE			equ			40005
ID_SAVE_FILE			equ			40007
ID_PENCIL				equ			40010
ID_ERASER				equ			40011
ID_COLOR				equ			40012
ID_RENDLINE			equ			40013
ID_TOOLBAR			equ			1
PENCIL						equ			2
ERASER					equ			3
LINE							equ			4
RENDLINE				equ			7

.data
MouseClick				db			FALSE
pen_what					dd			PENCIL
paint_what				dd			LINE
fgColor					dd			0
acrCustClr				dd			16 dup(0)
openFileN							OPENFILENAME <>
FilterString              byte         "BitMap(*.bmp)",0,"*.bmp",0
OtherBmp         byte         ".bmp",0
stToolbar					equ			this byte
TBBUTTON				<0,IDM_OPEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON				<1,IDM_SAVE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON				<2,IDM_PENCIL,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON				<3,IDM_ERASER,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON				<4,IDM_COLOR,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON				<5,IDM_RENDLINE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
NUM_BUTTONS		equ			6



.data?
hInstance					dd			?
hWinMain				dd			? 
hWinToolbar			dd			?
hMenu						dd			?
hAccelerator			dd			?
buffer						dd			?
hitpoint					POINT		<>
movpoint					POINT		<>
fileNameBuffer		byte			1000 DUP(?)


.const
szClassName			db		'MyClass',0
szCaptionMain		db		'MyPainter',0
WndWidth				equ		800
WndHeight				equ		600




.code

_MySaveFile proc USES edx ebx hWnd:HWND
    local hdc:HDC
    local hdcBmp:HDC
    local hBmpBuffer:HBITMAP
    local bmfHeader:BITMAPFILEHEADER   
    local BitFore:BITMAPINFOHEADER   
    local bmpScreen:BITMAP
    local DWSize:dword
    local hDIB:HANDLE
    local lpbitmap:PTR byte
    local hFile:HANDLE  
    local DIBSize:dword
    local WrittenBytes:dword
    local len:dword

    mov  openFileN.lStructSize,SIZEOF openFileN
    mov  openFileN.hwndOwner,NULL 
    push hInstance 
    pop  openFileN.hInstance 
    mov  openFileN.lpstrFilter,OFFSET FilterString 
    mov  openFileN.lpstrFile,OFFSET fileNameBuffer 
    mov  openFileN.nMaxFile,SIZEOF fileNameBuffer 
    mov  openFileN.Flags,OFN_PATHMUSTEXIST
    invoke GetSaveFileName,ADDR openFileN
    .IF (!eax)
        ret
    .ENDIF

    invoke crt_strlen, offset fileNameBuffer
    mov len, eax
    mov ebx, offset fileNameBuffer
    add ebx, len
    sub  ebx, 4
    invoke crt_strcmp, ebx, offset OtherBmp
    .if eax != 0
    add ebx, 4
    invoke crt_strcpy, ebx, offset OtherBmp
    .endif

    invoke GetDC,hWnd
    mov hdc,eax
    invoke CreateCompatibleDC,hdc
    mov hdcBmp,eax
    invoke SetStretchBltMode,hdc,HALFTONE
    invoke CreateCompatibleBitmap,hdc,WndWidth,WndHeight
    mov hBmpBuffer,eax
    invoke SelectObject,hdcBmp,hBmpBuffer
    invoke BitBlt,hdcBmp,0,0,WndWidth,WndHeight,buffer,0,0,SRCCOPY
    invoke GetObject,hBmpBuffer,SIZEOF BITMAP,addr bmpScreen
    push sizeof BITMAPINFOHEADER
    pop BitFore.biSize
    push bmpScreen.bmWidth
    pop BitFore.biWidth
    push bmpScreen.bmHeight
    pop BitFore.biHeight
    mov BitFore.biPlanes,1
    mov BitFore.biBitCount,32
    mov BitFore.biCompression,BI_RGB
    mov BitFore.biSizeImage,0
    mov BitFore.biXPelsPerMeter,0
    mov BitFore.biYPelsPerMeter,0
    mov BitFore.biClrUsed,0
    mov BitFore.biClrImportant,0

    movzx eax,BitFore.biBitCount
    mul bmpScreen.bmWidth
    add eax,31
    mov ebx,32
    cdq
    div ebx
    mov edx,4
    mul edx
    mul bmpScreen.bmHeight
    mov DWSize,eax
    invoke GlobalAlloc,GHND,DWSize
    mov hDIB,eax
    invoke GlobalLock,hDIB
    mov lpbitmap,eax

    invoke GetDIBits,hdc,hBmpBuffer,0,bmpScreen.bmHeight,lpbitmap,addr BitFore,DIB_RGB_COLORS
    invoke CreateFile,addr fileNameBuffer,GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
    mov hFile,eax
    mov eax,DWSize 
    add eax,sizeof BITMAPFILEHEADER
    add eax,sizeof BITMAPINFOHEADER
    mov DIBSize,eax

    mov eax,sizeof BITMAPFILEHEADER
    add eax,sizeof BITMAPINFOHEADER
    mov bmfHeader.bfOffBits,eax
    push DIBSize
    pop bmfHeader.bfSize
    mov bmfHeader.bfType,4D42h

    invoke WriteFile,hFile,addr bmfHeader,sizeof BITMAPFILEHEADER,addr WrittenBytes,NULL
    invoke WriteFile,hFile,addr BitFore,sizeof BITMAPINFOHEADER,addr WrittenBytes,NULL
    invoke WriteFile,hFile,lpbitmap,DWSize,addr WrittenBytes,NULL

    invoke GlobalUnlock,hDIB
    invoke GlobalFree,hDIB
    invoke CloseHandle,hFile

    invoke DeleteDC,hdcBmp
    invoke DeleteObject,hBmpBuffer
    invoke ReleaseDC,hWnd,hdc
    ret
_MySaveFile endp

_MyOpenFile proc hWnd:HWND
    local hdc:HDC
    local hdcBmp:HDC
    local hBmp:HBITMAP
    local tempDC:HDC
    local tempBmp:HBITMAP
  

    invoke GetDC,hWnd
    mov hdc,eax
    invoke CreateCompatibleDC,hdc
    mov tempDC,eax
    invoke CreateCompatibleDC,hdc
    mov hdcBmp,eax
    invoke CreateCompatibleBitmap,hdc,WndWidth,WndHeight
    mov tempBmp,eax
    invoke SelectObject,tempDC,tempBmp
    invoke BitBlt,tempDC,0,0,WndWidth,WndHeight,buffer,0,0,SRCCOPY

    mov  openFileN.lStructSize,sizeof openFileN
    mov  openFileN.hwndOwner,NULL 
    push hInstance 
    pop  openFileN.hInstance 
    mov  openFileN.lpstrFilter,OFFSET FilterString 
    mov  openFileN.lpstrFile,OFFSET fileNameBuffer 
    mov  openFileN.nMaxFile,sizeof fileNameBuffer 
    mov  openFileN.Flags,OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
    invoke GetOpenFileName,ADDR openFileN
    .IF (!eax)
        ret
    .ENDIF
    invoke LoadImage,hInstance,addr fileNameBuffer,IMAGE_BITMAP,0,0,LR_LOADFROMFILE 
    .IF (!eax)
        ret
    .ENDIF

    mov hBmp,HBITMAP PTR eax
    invoke SelectObject,hdcBmp,hBmp
    invoke BitBlt,tempDC,0,0,WndWidth,WndHeight,hdcBmp,0,0,SRCCOPY
    invoke BitBlt,buffer,0,0,WndWidth,WndHeight,tempDC,0,0,SRCCOPY
    
    invoke DeleteDC,hdcBmp
    invoke DeleteDC,tempDC
    invoke DeleteObject,tempBmp
    invoke ReleaseDC,hWnd,hdc

    invoke InvalidateRect,hWnd,0,FALSE
    invoke UpdateWindow,hWnd
    ret
_MyOpenFile endp

_MySelectColor proc hWnd:HWND
    local myColor:CHOOSECOLOR

    mov myColor.lStructSize,sizeof myColor
    mov eax,hWnd
    mov myColor.hwndOwner,eax
    mov eax,hInstance
    mov myColor.hInstance,eax
    mov myColor.rgbResult,0
    mov eax,offset acrCustClr
    mov myColor.lpCustColors,eax
    mov myColor.Flags,CC_FULLOPEN or CC_RGBINIT
    mov myColor.lCustData,0
    mov myColor.lpfnHook,0
    mov myColor.lpTemplateName,0
    invoke ChooseColor,addr myColor
    mov eax,myColor.rgbResult
    mov fgColor,eax
    ret
_MySelectColor endp

_ComparePos proc uses eax ebx,hPoint:POINT
	mov eax,hPoint.x
	mov ebx,1
	CMP eax,ebx
	JL L1
	mov eax,hPoint.y
	mov ebx,30
	CMP eax,ebx
	JL L1
	mov eax,785
	mov ebx,hPoint.x
	CMP eax,ebx
	JL L1
	mov eax,555
	mov ebx,hPoint.y
	CMP eax,ebx
	JL L1
L2:
	ret
L1:
	mov MouseClick,FALSE
	ret
_ComparePos endp

_CreateBuffer proc uses eax ecx,hWnd
	LOCAL hDc:HDC
	LOCAL hBitMap:HBITMAP
	LOCAL hPen:HPEN
	invoke GetDC,hWnd
	mov hDc,eax
	invoke CreateCompatibleDC,hDc
	mov buffer,eax
	invoke CreateCompatibleBitmap,hDc,WndWidth,WndHeight
	mov hBitMap,eax
	invoke SelectObject,buffer,hBitMap
	invoke GetStockObject,NULL_PEN
	mov hPen,eax
	invoke SelectObject,buffer,hPen
	invoke Rectangle,buffer,0,0,WndWidth,WndHeight
	invoke ReleaseDC,hWnd,hDc
	ret
_CreateBuffer endp

_CreateToolbar proc uses eax,hWnd:HWND,hIns:HINSTANCE
	LOCAL hbmp:HBITMAP
	invoke LoadBitmap,hIns,IDB_BITMAP7
	mov hbmp,eax
	invoke   CreateToolbarEx,hWnd,WS_VISIBLE or WS_CHILD or TBSTYLE_FLAT or TBSTYLE_TOOLTIPS or\
	CCS_ADJUSTABLE,ID_TOOLBAR,6,0,hbmp,offset stToolbar,\
	NUM_BUTTONS,16,16,16,16,sizeof TBBUTTON
	mov      hWinToolbar,eax
	ret
_CreateToolbar endp

_CreateMenu proc uses eax,hIns:HINSTANCE
	invoke LoadMenu,hIns,IDM_MENU
	mov hMenu,eax
	invoke LoadAccelerators,hIns,IDA_MENU
	mov hAccelerator,eax
	ret
_CreateMenu endp

_ProcWinMain proc uses ebx edi esi,hWnd,uMsg,wParam,lParam
		LOCAL stPs:PAINTSTRUCT
		LOCAL hDc:HDC
		LOCAL hPen:HPEN
		LOCAL myhDc:HDC
		LOCAL temphDc:HDC
		LOCAL tempBit:HBITMAP
		mov eax,uMsg
		.if eax == WM_CLOSE
			;invoke DestroyWindow,hWinMain
			invoke PostQuitMessage,NULL
		.elseif eax == WM_CREATE
			invoke _CreateToolbar,hWnd,hInstance
			;invoke _CreateMenu,hInstance
			invoke _CreateBuffer,hWnd
		.elseif eax == WM_PAINT
			mov ebx,hWnd
			.if ebx == hWinMain
				invoke BeginPaint,hWnd,addr stPs
				mov hDc,eax
				invoke BitBlt,hDc,0,0,WndWidth,WndHeight,buffer,0,0,SRCCOPY
				invoke EndPaint,hWnd,addr stPs
			.endif
		.elseif eax == WM_LBUTTONDOWN
			mov eax,lParam
			and eax,0FFFFh
			mov hitpoint.x,eax
			mov eax,lParam
			shr eax,16
			mov hitpoint.y,eax
			mov MouseClick,TRUE
		.elseif eax == WM_MOUSEMOVE
			mov eax,lParam
			and eax,0FFFFh
			mov movpoint.x,eax
			mov eax,lParam
			shr eax,16
			mov movpoint.y,eax
			invoke _ComparePos,movpoint
			.if MouseClick == TRUE
				invoke GetDC,hWnd
				mov myhDc,eax
				invoke CreateCompatibleDC,myhDc
				mov temphDc,eax
				invoke CreateCompatibleBitmap,myhDc,WndWidth,WndHeight
				mov tempBit,eax
				invoke SelectObject,temphDc,tempBit
				invoke BitBlt,temphDc,0,0,WndWidth,WndHeight,buffer,0,0,SRCCOPY
				.if pen_what == PENCIL
					invoke CreatePen,PS_SOLID,1,fgColor
					mov hPen,eax
				.else
					invoke CreatePen,PS_SOLID,30,0ffffffh
					mov hPen,eax
				.endif
				invoke SelectObject,temphDc,hPen
				.if paint_what == LINE
					invoke MoveToEx,temphDc,hitpoint.x,hitpoint.y,NULL
					invoke LineTo,temphDc,movpoint.x,movpoint.y
								
					push movpoint.x
					push movpoint.y
					pop hitpoint.y
					pop hitpoint.x
				.elseif paint_what == RENDLINE
					invoke MoveToEx,temphDc,hitpoint.x,hitpoint.y,NULL
					invoke LineTo,temphDc,movpoint.x,movpoint.y
				.endif
				invoke BitBlt,buffer,0,0,WndWidth,WndHeight,temphDc,0,0,SRCCOPY
				
				invoke DeleteObject,hPen
				invoke DeleteObject,tempBit
				invoke DeleteDC,temphDc
				invoke ReleaseDC,hWnd,myhDc

				invoke InvalidateRect,hWnd,0,FALSE
				invoke UpdateWindow,hWnd

			.endif
		.elseif eax == WM_LBUTTONUP
			.if MouseClick == TRUE			
				mov MouseClick,FALSE
			.endif
		.elseif eax == WM_COMMAND
			mov eax,wParam
			.if ax == IDM_SAVE || ax == ID_SAVE_FILE
				invoke _MySaveFile,hWnd
			.elseif ax == IDM_OPEN || ax == ID_OPEN_FILE
				invoke _MyOpenFile,hWnd
			.elseif ax == IDM_PENCIL || ax ==ID_PENCIL
				mov pen_what,PENCIL
				mov paint_what,LINE
			.elseif ax == IDM_ERASER ||  ax == ID_ERASER
				mov pen_what,ERASER
				mov paint_what,LINE
			.elseif ax == IDM_COLOR || ax == ID_COLOR
				invoke _MySelectColor,hWnd
			.elseif ax == IDM_RENDLINE || ax == ID_RENDLINE
				mov pen_what,PENCIL
				mov paint_what,RENDLINE
			.endif
		.else 
 			invoke DefWindowProc,hWnd,uMsg,wParam,lParam
			ret
		.endif
		xor eax,eax
		ret
_ProcWinMain endp

_WinMain proc
		LOCAL stWndClass:WNDCLASSEX
		LOCAL stMsg:MSG
		;LOCAL hAccelerator:HACCEL

		invoke GetModuleHandle,NULL
		mov hInstance,eax
		invoke RtlZeroMemory,addr stWndClass,sizeof stWndClass

		invoke LoadCursor,0,IDC_ARROW
		mov stWndClass.hCursor,eax
		push hInstance
		pop stWndClass.hInstance
		mov stWndClass.cbSize,sizeof WNDCLASSEX
		mov stWndClass.style,CS_HREDRAW or CS_VREDRAW
		mov stWndClass.lpfnWndProc,offset  _ProcWinMain
		mov stWndClass.hbrBackground,COLOR_WINDOW+1
		mov stWndClass.lpszClassName,offset szClassName
		mov stWndClass.lpszMenuName,IDM_MENU
		invoke RegisterClassEx,addr stWndClass


		invoke CreateWindowEx,WS_EX_CLIENTEDGE,offset szClassName,offset szCaptionMain,WS_OVERLAPPEDWINDOW and not WS_MAXIMIZEBOX and not WS_THICKFRAME,0,0,WndWidth,WndHeight,NULL,NULL,hInstance,NULL
		mov hWinMain,eax
		;invoke _CreateToolbar,hWinMain,hInstance
		;invoke LoadAccelerators,hInstance,IDR_ACCELERATOR
		;mov hAccelerator,eax
		invoke ShowWindow,hWinMain,SW_SHOWNORMAL
		invoke UpdateWindow,hWinMain

		invoke LoadAccelerators,hInstance,IDA_MENU
		mov hAccelerator,eax
		.while TRUE
			invoke GetMessage,addr stMsg,NULL,0,0
			.break .if eax == 0
			invoke TranslateAccelerator,hWinMain,hAccelerator,addr stMsg
			.if eax == 0
				invoke TranslateMessage,addr stMsg
				invoke DispatchMessage,addr stMsg
			.endif
		.endw

		ret
_WinMain endp

start:
	call _WinMain
	invoke ExitProcess,NULL
end start
