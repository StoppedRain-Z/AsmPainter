.386
.model flat, stdcall
option casemap :none
 
include windows.inc
include user32.inc
includelib user32.lib
include kernel32.inc
includelib kernel32.lib
include Gdi32.inc
includelib Gdi32.lib
 
 
CLOCK_SIZE equ 150
ICO_MAIN equ 121              
IDC_MAIN equ 123
IDC_MOVE equ 122
IDB_BACK1 equ 120
IDB_CIRCLE1 equ 118     ;;注意Circle1的ID值必须是加一后等于MASK1的ID值，不然不会成功。
IDB_MASK1 equ 119
IDB_BACK2 equ 117
IDB_CIRCLE2 equ 115      ;注意Circle2的ID值必须是加一后等于MASK2的ID值，不然不会成功。
IDB_MASK2 equ 116              
ID_TIMER equ 1
IDM_BACK1 equ 100
IDM_BACK2 equ 101
IDM_CIRCLE1 equ 102
IDM_CIRCLE2 equ 103
IDM_EXIT equ 104
 
 
.data?
 
 
hInstance dd ?
hWinMain dd ?
hCursorMove dd ?;Cursor when move
hCursorMain dd ?;Cursor when normal
hMenu dd ?
 
 
hBmpBack dd ?
hDcBack dd ?
hBmpClock dd ?
hDcClock dd ?
 
 
dwNowBack dd ?
dwNowCircle dd ?
 
 
.const
 
 
szClassName db'Clock',0
dwPara180 dw 180
dwRadius dw CLOCK_SIZE/2
szMenuBack1 db'使用格子背景(&A)',0
szMenuBack2 db'使用花布背景(&B)',0
szMenuCircle1 db'使用淡蓝色边框(&C)',0
szMenuCircle2 db'使用粉红色边框(&D)',0
szMenuExit db '退出(&X)...',0
                .code
 
 
_CalcX proc _dwDegree,_dwRadius
LOCAL @dwReturn
 
 
fild dwRadius
fild _dwDegree
fldpi
fmul ;角度*Pi
fild dwPara180
fdivp st(1),st;角度*Pi/180
fsin ;Sin(角度*Pi/180)
fild _dwRadius
fmul ;半径*Sin(角度*Pi/180)
fadd ;X+半径*Sin(角度*Pi/180)
fistp @dwReturn
mov eax,@dwReturn
ret
 
 
_CalcX endp
_CalcY proc _dwDegree,_dwRadius
LOCAL @dwReturn
 
 
fild dwRadius
fild _dwDegree
fldpi
fmul
fild dwPara180
fdivp st(1),st
fcos
fild _dwRadius
fmul
fsubp st(1),st
fistp @dwReturn
mov eax,@dwReturn
ret
 
 
_CalcY endp
 
 
_DrawLine proc _hDC,_dwDegree,_dwRadius
LOCAL @dwX1,@dwY1,@dwX2,@dwY2
 
 
invoke _CalcX,_dwDegree,_dwRadius
mov @dwX1,eax
invoke _CalcY,_dwDegree,_dwRadius
mov @dwY1,eax
add _dwDegree,180
invoke _CalcX,_dwDegree,10
mov @dwX2,eax
invoke _CalcY,_dwDegree,10
mov @dwY2,eax
invoke MoveToEx,_hDC,@dwX1,@dwY1,NULL
invoke LineTo,_hDC,@dwX2,@dwY2
ret
 
 
_DrawLine endp
_CreateClockPic proc
LOCAL @stTime:SYSTEMTIME
 
 
pushad
invoke BitBlt,hDcClock,0,0,CLOCK_SIZE,CLOCK_SIZE,hDcBack,0,0,SRCCOPY
invoke GetLocalTime,addr @stTime
invoke CreatePen,PS_SOLID,1,0
invoke SelectObject,hDcClock,eax
invoke DeleteObject,eax
movzx eax,@stTime.wSecond
mov ecx,360/60
mul ecx;秒针度数 = 秒 * 360/60
invoke _DrawLine,hDcClock,eax,60
invoke CreatePen,PS_SOLID,2,0
invoke SelectObject,hDcClock,eax
invoke DeleteObject,eax
movzx eax,@stTime.wMinute
mov ecx,360/60
mul ecx;分针度数 = 分 * 360/60
invoke _DrawLine,hDcClock,eax,55
invoke CreatePen,PS_SOLID,3,0
invoke SelectObject,hDcClock,eax
invoke DeleteObject,eax
movzx eax,@stTime.wHour
.if eax >= 12
sub eax,12
.endif
mov ecx,360/12
mul ecx
movzx ecx,@stTime.wMinute
shr ecx,1
add eax,ecx
invoke _DrawLine,hDcClock,eax,50
invoke GetStockObject,NULL_PEN
invoke SelectObject,hDcClock,eax
invoke DeleteObject,eax
popad
ret
 
 
_CreateClockPic endp
 
 
_CreateBackGround    proc
 
            LOCAL @hDc,@hDcCircle,@hDcMask
            LOCAL @hBmpBack,@hBmpCircle,@hBmpMask
       invoke    GetDC,hWinMain
       mov       @hDc,eax
       invoke    CreateCompatibleDC,@hDc
       mov       hDcBack,eax
       invoke    CreateCompatibleDC,@hDc
       mov       hDcClock,eax
       invoke    CreateCompatibleDC,@hDc
       mov       @hDcCircle,eax
       invoke    CreateCompatibleDC,@hDc
       mov       @hDcMask,eax
       invoke    CreateCompatibleBitmap,@hDc,CLOCK_SIZE,CLOCK_SIZE
       mov       hBmpBack,eax
       invoke    CreateCompatibleBitmap,@hDc,CLOCK_SIZE,CLOCK_SIZE
       mov       hBmpClock,eax
       invoke    ReleaseDC,hWinMain,@hDc
       invoke    LoadBitmap,hInstance,dwNowBack
       mov       @hBmpBack,eax
       invoke    LoadBitmap,hInstance,dwNowCircle
       mov       @hBmpCircle,eax
       mov       eax,dwNowCircle
       inc       eax
       invoke    LoadBitmap,hInstance,eax
       mov       @hBmpMask,eax
       invoke    SelectObject,hDcBack,hBmpBack
       invoke    SelectObject,hDcClock,hBmpClock
       invoke    SelectObject,@hDcCircle,@hBmpCircle
       invoke    SelectObject,@hDcMask,@hBmpMask
       invoke    CreatePatternBrush,@hBmpBack                  ;格子背景
       push      eax
       invoke    SelectObject,hDcBack,eax
       invoke    PatBlt,hDcBack,0,0,CLOCK_SIZE,CLOCK_SIZE,PATCOPY
       invoke    DeleteObject,eax
       invoke    BitBlt,hDcBack,0,0,CLOCK_SIZE,CLOCK_SIZE,@hDcMask,0,0,SRCAND         ;利用遮掩图片和ROP码画时钟边框（淡蓝色边框）
       invoke    BitBlt,hDcBack,0,0,CLOCK_SIZE,CLOCK_SIZE,@hDcCircle,0,0,SRCPAINT
       invoke    DeleteDC,@hDcCircle
       invoke    DeleteDC,@hDcMask
       invoke    DeleteObject,@hBmpBack
       invoke    DeleteObject,@hBmpCircle
       invoke    DeleteObject,@hBmpMask
       ret
                 
_CreateBackGround endp
 
 
_DeleteBackGround proc
                invoke DeleteDC,hDcBack
                invoke DeleteDC,hDcClock
                invoke DeleteObject,hBmpBack
                invoke DeleteObject,hBmpClock
                ret
_DeleteBackGround endp 
 
 
_Quit proc
 
 
invoke KillTimer,hWinMain,ID_TIMER
invoke DestroyWindow,hWinMain
invoke PostQuitMessage,NULL
invoke _DeleteBackGround
invoke DestroyMenu,hMenu
ret
 
 
_Quit endp
 
 
_Init proc
       invoke  CreatePopupMenu
               mov  hMenu,eax
       invoke  AppendMenu,hMenu,0,IDM_BACK1,offset szMenuBack1
       invoke  AppendMenu,hMenu,0,IDM_BACK2,offset szMenuBack2
       invoke  AppendMenu,hMenu,MF_SEPARATOR,0,NULL
       invoke  AppendMenu,hMenu,0,IDM_CIRCLE1,offset szMenuCircle1
       invoke  AppendMenu,hMenu,0,IDM_CIRCLE2,offset szMenuCircle2
       invoke  AppendMenu,hMenu,MF_SEPARATOR,0,NULL
       invoke  AppendMenu,hMenu,0,IDM_EXIT,offset szMenuExit
       invoke  CheckMenuRadioItem,hMenu,IDM_CIRCLE1,IDM_CIRCLE2,IDM_CIRCLE1,NULL
       invoke  CheckMenuRadioItem,hMenu,IDM_BACK1,IDM_BACK2,IDM_BACK1,NULL
       invoke  CreateEllipticRgn,0,0,CLOCK_SIZE+1,CLOCK_SIZE+1
       push    eax
       invoke  SetWindowRgn,hWinMain,eax,TRUE
       pop     eax
       invoke  DeleteObject,eax
       invoke  SetWindowPos,hWinMain,HWND_TOPMOST,0,0,0,0,SWP_NOMOVE or SWP_NOSIZE
       mov     dwNowBack,IDB_BACK1
       mov     dwNowCircle,IDB_CIRCLE1
       invoke  _CreateBackGround
       invoke  _CreateClockPic
       invoke  SetTimer,hWinMain,ID_TIMER,1000,NULL
       ret
_Init endp
 
 
_ProcWinMain    proc    uses ebx edi esi hWnd,uMsg,wParam,lParam
 
       LOCAL   @stPS:PAINTSTRUCT
       LOCAL   @hDC
       LOCAL   @stPos:POINT
       mov     eax,uMsg
       .if     eax ==  WM_TIMER
        invoke  _CreateClockPic
        invoke  InvalidateRect,hWnd,NULL,FALSE
       .elseif eax ==  WM_PAINT
        invoke  BeginPaint,hWnd,addr @stPS
        mov     @hDC,eax
        mov     eax,@stPS.rcPaint.right
        sub     eax,@stPS.rcPaint.left
        mov     ecx,@stPS.rcPaint.bottom
        sub     ecx,@stPS.rcPaint.top
        invoke  BitBlt,@hDC,@stPS.rcPaint.left,@stPS.rcPaint.top,eax,ecx,hDcClock,@stPS.rcPaint.left,\
                      @stPS.rcPaint.top,SRCCOPY
        invoke  EndPaint,hWnd,addr @stPS
       .elseif eax ==WM_CREATE
mov eax,hWnd
mov hWinMain,eax
invoke _Init
.elseif eax == WM_COMMAND
mov eax,wParam
.if ax ==IDM_BACK1
mov dwNowBack,IDB_BACK1
invoke CheckMenuRadioItem,hMenu,IDM_BACK1,IDM_BACK2,IDM_BACK1,NULL
.elseif ax == IDM_BACK2
mov dwNowBack,IDB_BACK2
invoke CheckMenuRadioItem,hMenu,IDM_BACK1,IDM_BACK2,IDM_BACK2,NULL
.elseif ax == IDM_CIRCLE1
mov dwNowCircle,IDB_CIRCLE1
invoke CheckMenuRadioItem,hMenu,IDM_CIRCLE1,IDM_CIRCLE2,IDM_CIRCLE1,NULL
.elseif ax == IDM_CIRCLE2
mov dwNowCircle,IDB_CIRCLE2
invoke CheckMenuRadioItem,hMenu,IDM_CIRCLE1,IDM_CIRCLE2,IDM_CIRCLE2,NULL
.elseif ax == IDM_EXIT
call _Quit
xor eax,eax
ret
.endif
invoke _DeleteBackGround
invoke _CreateBackGround
invoke _CreateClockPic
invoke InvalidateRect,hWnd,NULL,FALSE
.elseif eax == WM_CLOSE
call _Quit
.elseif eax == WM_RBUTTONDOWN
invoke GetCursorPos,addr @stPos
invoke TrackPopupMenu,hMenu,TPM_LEFTALIGN,@stPos.x,@stPos.y,NULL,hWnd,NULL
.elseif eax ==WM_LBUTTONDOWN
invoke SetCursor,hCursorMove
invoke UpdateWindow,hWnd
invoke ReleaseCapture
invoke SendMessage,hWnd,WM_NCLBUTTONDOWN,HTCAPTION,0
invoke SetCursor,hCursorMain
.else
invoke DefWindowProc,hWnd,uMsg,wParam,lParam
ret
.endif
xor eax,eax
ret
 
 
_ProcWinMain endp
_WinMain proc
LOCAL @stWndClass:WNDCLASSEX
LOCAL @stMsg:MSG
 
 
invoke GetModuleHandle,NULL
mov hInstance,eax
invoke LoadCursor,hInstance,IDC_MOVE
mov hCursorMove,eax
invoke LoadCursor,hInstance,IDC_MAIN
mov hCursorMain,eax
 
 
invoke RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
invoke LoadIcon,hInstance,ICO_MAIN
mov @stWndClass.hIcon,eax
mov @stWndClass.hIconSm,eax
push hCursorMain
pop @stWndClass.hCursor
push hInstance
pop @stWndClass.hInstance
mov @stWndClass.cbSize,sizeof WNDCLASSEX
mov @stWndClass.style,CS_HREDRAW or CS_VREDRAW
mov @stWndClass.lpfnWndProc,offset _ProcWinMain
mov @stWndClass.hbrBackground,COLOR_WINDOW + 1
mov @stWndClass.lpszClassName,offset szClassName
invoke RegisterClassEx,addr @stWndClass
invoke CreateWindowEx,NULL,\
offset szClassName,offset szClassName,\
WS_POPUP or WS_SYSMENU,\
100,100,CLOCK_SIZE,CLOCK_SIZE,\
NULL,NULL,hInstance,NULL
mov hWinMain,eax
invoke ShowWindow,hWinMain,SW_SHOWNORMAL
invoke UpdateWindow,hWinMain
 
 
.while TRUE
invoke GetMessage,addr @stMsg,NULL,0,0
.break .if eax == 0
invoke TranslateMessage,addr @stMsg
invoke DispatchMessage,addr @stMsg
.endw
ret
 
 
_WinMain endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
start:
call _WinMain
invoke ExitProcess,NULL
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
end start










//toolBar

.386
.model flat, stdcall
option casemap :none
                
include         windows.inc
include         user32.inc
includelib      user32.lib
include         kernel32.inc
includelib      kernel32.lib
include         comctl32.inc
includelib      comctl32.lib
 
 
IDI_ICON1       equ      101;图标
IDR_MENU1       equ      102 ;菜单
IDM_NEW         equ      40000
IDM_OPEN        equ      40001
IDM_SAVE        equ      40002
IDM_PAGESETUP   equ      40003
IDM_PRINT       equ      40004
IDM_COPY        equ      40005
IDM_CUT         equ      40006
IDM_PASTE       equ      40007
IDM_FIND        equ      40008
IDM_REPLACE     equ      40009
IDM_HELP        equ      40010
IDM_EXIT        equ      40011
ID_TOOLBAR      equ      1
ID_EDIT         equ      2
 
 
                .data?
hInstance       dd       ?
hWinMain        dd       ?
hMenu           dd       ?
hWinToolbar     dd       ?
hWinEdit        dd       ?
 
 
                .const
szClass         db       'EDIT',0
szClassName     db       'ToolbarExample',0
szCaptionMain   db       '工具栏示例',0
szCaption       db       '命令消息',0
szFormat        db       '收到 WM_COMMAND 消息，命令ID：%d',0
stToolbar       equ      this byte
TBBUTTON        <STD_FILENEW,IDM_NEW,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <STD_FILEOPEN,IDM_OPEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <STD_FILESAVE,IDM_SAVE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0,-1>
TBBUTTON        <STD_PRINTPRE,IDM_PAGESETUP,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <STD_PRINT,IDM_PRINT,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0,-1>
TBBUTTON        <STD_COPY,IDM_COPY,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <STD_CUT,IDM_CUT,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <STD_PASTE,IDM_PASTE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0,-1>
TBBUTTON        <STD_FIND,IDM_FIND,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <STD_REPLACE,IDM_REPLACE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0,-1>
TBBUTTON        <STD_HELP,IDM_HELP,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0,-1>
NUM_BUTTONS     equ      16
 
 
                .code
_Resize         proc
 
       LOCAL    @stRect:RECT,@stRect1:RECT
       invoke   SendMessage,hWinToolbar,TB_AUTOSIZE,0,0
       invoke   GetClientRect,hWinMain,addr @stRect
       invoke   GetWindowRect,hWinToolbar,addr @stRect1
       mov      eax,@stRect1.bottom
       sub      eax,@stRect1.top
       mov      ecx,@stRect.bottom
       sub      ecx,eax
       invoke   MoveWindow,hWinEdit,0,eax,@stRect.right,ecx,TRUE       
       ret
 
 
_Resize endp 
 
 
_ProcWinMain    proc     uses ebx edi esi hWnd ,uMsg,wParam,lParam
 
       LOCAL    @szBuffer[128]:byte
       mov      eax,uMsg
       .if      eax  ==  WM_CLOSE
                invoke   PostMessage,hWnd,WM_COMMAND,IDM_EXIT,0
       .elseif  eax  ==  WM_CREATE
        mov      eax,hWnd
        mov      hWinMain,eax
        invoke   CreateWindowEx,WS_EX_CLIENTEDGE,addr szClass,NULL,WS_CHILD or WS_VISIBLE or ES_MULTILINE or\
                 ES_WANTRETURN or WS_VSCROLL or ES_AUTOHSCROLL,0,0,0,0,hWnd,ID_EDIT,hInstance,NULL
        mov      hWinEdit,eax
        invoke   CreateToolbarEx,hWinMain,WS_VISIBLE or WS_CHILD or TBSTYLE_FLAT or TBSTYLE_TOOLTIPS or\
                 CCS_ADJUSTABLE,ID_TOOLBAR,0,HINST_COMMCTRL,IDB_STD_SMALL_COLOR,offset stToolbar,\
                 NUM_BUTTONS,0,0,0,0,sizeof TBBUTTON
        mov      hWinToolbar,eax
        call     _Resize                  ;注意此处作者用的是Call而并非是invoke 
       .elseif  eax  ==  WM_COMMAND
                mov      eax,wParam
                .if      ax  ==  IDM_EXIT
                 invoke  DestroyWindow,hWinMain
                 invoke  PostQuitMessage,NULL
                .elseif  ax  !=  ID_EDIT
                 invoke  wsprintf,addr @szBuffer,addr szFormat,wParam  
                 invoke  MessageBox,hWnd,addr @szBuffer,addr szCaption,MB_OK or MB_ICONINFORMATION
                .endif
       .elseif  eax  ==  WM_SIZE
                call     _Resize
       .elseif  eax  ==  WM_NOTIFY
        mov      ebx,lParam
        .if      [ebx + NMHDR.code] == TTN_NEEDTEXT
         assume   ebx:ptr TOOLTIPTEXT
         mov      eax,[ebx].hdr.idFrom
         mov      [ebx].lpszText,eax
         push     hInstance
         pop      [ebx].hInst
         assume  ebx:nothing
        .elseif  ([ebx + NMHDR.code] == TBN_QUERYINSERT) || ([ebx + NMHDR.code] == TBN_QUERYDELETE)
         mov      eax,TRUE
         ret
        .elseif  [ebx + NMHDR.code] ==  TBN_GETBUTTONINFO
         assume   ebx:ptr TBNOTIFY
         mov      eax,[ebx].iItem
         .if      eax < NUM_BUTTONS
            mov     ecx,sizeof TBBUTTON
            mul     ecx
            add     eax,offset stToolbar
            invoke  RtlMoveMemory,addr [ebx].tbButton,eax,sizeof TBBUTTON
            invoke  LoadString,hInstance,[ebx].tbButton.idCommand,addr @szBuffer,sizeof @szBuffer
            lea     eax,@szBuffer
            mov     [ebx].pszText,eax
            invoke  lstrlen,addr @szBuffer
            mov     [ebx].cchText,eax
            assume  ebx:nothing
            mov     eax,TRUE
            ret
         .endif
        .endif
       .else   
        invoke    DefWindowProc,hWnd,uMsg,wParam,lParam
                 ret
       .endif
       xor     eax,eax
       ret
_ProcWinMain    endp
_WinMain proc
local @stWndClass:WNDCLASSEX
local @stMsg:MSG
 
 
invoke InitCommonControls
invoke GetModuleHandle,NULL
mov hInstance,eax
invoke LoadMenu,hInstance,IDR_MENU1
mov hMenu,eax
invoke RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
invoke LoadIcon,hInstance,IDI_ICON1 
mov @stWndClass.hIcon,eax
mov @stWndClass.hIconSm,eax
invoke LoadCursor,0,IDC_ARROW
mov @stWndClass.hCursor,eax
push hInstance
pop @stWndClass.hInstance
mov @stWndClass.cbSize,sizeof WNDCLASSEX
mov @stWndClass.style,CS_HREDRAW or CS_VREDRAW
mov @stWndClass.lpfnWndProc,offset _ProcWinMain
mov @stWndClass.hbrBackground,COLOR_BTNFACE+1
mov @stWndClass.lpszClassName,offset szClassName
invoke RegisterClassEx,addr @stWndClass
invoke CreateWindowEx,NULL,\
offset szClassName,offset szCaptionMain,\
WS_OVERLAPPEDWINDOW,\
CW_USEDEFAULT,CW_USEDEFAULT,700,500,\
NULL,hMenu,hInstance,NULL
mov hWinMain,eax
invoke ShowWindow,hWinMain,SW_SHOWNORMAL
invoke UpdateWindow,hWinMain
 
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
end        start
 
