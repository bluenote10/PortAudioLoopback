import
  windows

const NULL: HANDLE = 0
const FALSE = 0

converter toWINUINT(i: int): WINUINT =
    cast[WINUINT](i)

const EDITID = 1000
const BTNID = 1001
const g_szClassName = "MyNimWindowClass"

proc wndProc(hwnd: HWND, msg: WINUINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
    case msg:
    of WM_CLOSE:
        echo "Close"
        discard DestroyWindow(hwnd)
    of WM_DESTROY:
        echo "Destroy"
        PostQuitMessage(0)
    of WM_CREATE:
        echo "CREATE"
        var hEdit: HWND

        hEdit = CreateWindowEx(WS_EX_CLIENTEDGE, "EDIT", "Hello",
            WS_CHILD or WS_VISIBLE,
            20, 130, 100, 24, hwnd, EDITID, GetModuleHandle(nil), nil)

        var hfDefault = GetStockObject(DEFAULT_GUI_FONT);
        discard SendMessage(hEdit,
            WM_SETFONT,
            hfDefault,
            MAKELPARAM(FALSE,0));

        var hButton: HWND

        hButton = CreateWindowEx(NULL,
                "BUTTON",
                "OK",
                WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                20,
                160,
                100,
                24,
                hWnd,
                BTNID,
                GetModuleHandle(nil),
                nil);

    else:
        discard
        #echo "Unhandled message ", msg
    return DefWindowProc(hwnd, msg, wParam, lParam)

proc main() =
    var
        wc: WNDCLASSEX
        hwnd: HWND
        msg: MSG

    let hInstance = GetModuleHandle(nil)

    wc.cbSize = sizeof(WNDCLASSEX)
    wc.style = CS_HREDRAW or CS_VREDRAW
    wc.lpfnWndProc = wndProc
    wc.cbClsExtra    = 0
    wc.cbWndExtra    = 0
    wc.hInstance     = hInstance
    wc.hIcon         = LoadIcon(NULL, IDI_APPLICATION)
    wc.hCursor       = LoadCursor(NULL, IDC_ARROW)
    wc.hbrBackground = COLOR_WINDOW+1
    wc.lpszMenuName  = nil
    wc.lpszClassName = g_szClassName
    wc.hIconSm       = LoadIcon(NULL, IDI_APPLICATION)

    if RegisterClassEx(addr(wc)) == 0:
        discard MessageBox(NULL, "Window Registration Failed!", "Error!", MB_ICONEXCLAMATION or MB_OK)
        return

    hwnd = CreateWindowEx(
        0,
        g_szClassName,
        "Nim Window",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 240, 240,
        NULL, NULL, hInstance, nil
        )

    if hwnd == NULL:
        var err = GetLastError()

        discard MessageBox(NULL, "Window Creation Failed " & $err, "Error!", MB_ICONEXCLAMATION or MB_OK)
        return



    discard ShowWindow(hwnd, SW_SHOW)
    discard UpdateWindow(hwnd)

    while GetMessage(addr(msg), NULL, 0, 0) > 0:
        discard TranslateMessage(addr(msg))
        discard DispatchMessage(addr(msg))

    quit(msg.wParam)


main()
