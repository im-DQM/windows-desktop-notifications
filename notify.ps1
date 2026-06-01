param(
    [string] $Title = "Claude Code",
    [string] $Message = "Notification",
    [string] $SoundFile = "",
    [switch] $Silent
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if (-not $Silent -and $SoundFile -ne "") {
    $sp = "C:\Windows\Media\" + $SoundFile
    if (Test-Path $sp) { (New-Object System.Media.SoundPlayer $sp).Play() }
}

Add-Type @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;

public class SilentNotifier : IDisposable
{
    private const int NIM_ADD = 0;
    private const int NIM_MODIFY = 1;
    private const int NIM_DELETE = 2;
    private const int NIF_MESSAGE = 1;
    private const int NIF_ICON = 2;
    private const int NIF_INFO = 0x10;
    private const int NIIF_NONE = 0;
    private const int NIIF_NOSOUND = 0x10;
    private const int WM_DESTROY = 0x0002;
    private const uint PM_REMOVE = 1;

    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    private static extern bool Shell_NotifyIcon(int dwMessage, ref NOTIFYICONDATA lpData);

    [DllImport("user32.dll")]
    private static extern IntPtr CreateWindowEx(int dwExStyle, string lpClassName,
        string lpWindowName, int dwStyle, int x, int y, int nWidth, int nHeight,
        IntPtr hWndParent, IntPtr hMenu, IntPtr hInstance, IntPtr lpParam);

    [DllImport("user32.dll")]
    private static extern bool DestroyWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool PeekMessage(out MSG lpMsg, IntPtr hWnd, uint wMsgFilterMin, uint wMsgFilterMax, uint wRemoveMsg);

    [DllImport("user32.dll")]
    private static extern bool TranslateMessage(ref MSG lpMsg);

    [DllImport("user32.dll")]
    private static extern IntPtr DispatchMessage(ref MSG lpMsg);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("user32.dll")]
    private static extern ushort RegisterClass(ref WNDCLASS lpWndClass);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    private struct NOTIFYICONDATA
    {
        public int cbSize;
        public IntPtr hWnd;
        public uint uID;
        public uint uFlags;
        public uint uCallbackMessage;
        public IntPtr hIcon;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string szTip;
        public uint dwState;
        public uint dwStateMask;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)] public string szInfo;
        public uint uTimeoutOrVersion;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 64)] public string szInfoTitle;
        public uint dwInfoFlags;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MSG { public IntPtr hwnd; public uint message; public IntPtr wParam; public IntPtr lParam; public uint time; public int pt_x; public int pt_y; }

    [StructLayout(LayoutKind.Sequential)]
    private struct WNDCLASS { public uint style; public IntPtr lpfnWndProc; public int cbClsExtra; public int cbWndExtra; public IntPtr hInstance; public IntPtr hIcon; public IntPtr hCursor; public IntPtr hbrBackground; public string lpszMenuName; public string lpszClassName; }

    private IntPtr hWnd;
    private NOTIFYICONDATA nid;
    private bool shown;

    private static IntPtr WndProc(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam)
    {
        return DefWindowProcW(hWnd, msg, wParam, lParam);
    }

    [DllImport("user32.dll")]
    private static extern IntPtr DefWindowProcW(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

    public void Show(string title, string message, int timeoutMs)
    {
        string cn = "SN_" + Guid.NewGuid().ToString("N");
        WNDCLASS wc; wc.style = 0; wc.cbClsExtra = 0; wc.cbWndExtra = 0;
        wc.lpfnWndProc = Marshal.GetFunctionPointerForDelegate((WndProcDelegate)WndProc);
        wc.hInstance = GetModuleHandle(null); wc.lpszClassName = cn;
        wc.hIcon = IntPtr.Zero; wc.hCursor = IntPtr.Zero; wc.hbrBackground = IntPtr.Zero; wc.lpszMenuName = null;
        RegisterClass(ref wc);
        hWnd = CreateWindowEx(0, cn, "", 0, 0, 0, 0, 0, IntPtr.Zero, IntPtr.Zero, wc.hInstance, IntPtr.Zero);

        using (Icon icon = SystemIcons.Information)
        {
            nid.cbSize = Marshal.SizeOf(typeof(NOTIFYICONDATA));
            nid.hWnd = hWnd; nid.uID = 1;
            nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_INFO;
            nid.uCallbackMessage = 0x8001;
            nid.hIcon = icon.Handle;
            nid.szTip = "";
            nid.szInfoTitle = title; nid.szInfo = message;
            nid.uTimeoutOrVersion = (uint)timeoutMs;
            nid.dwInfoFlags = NIIF_NONE | NIIF_NOSOUND;
            Shell_NotifyIcon(NIM_ADD, ref nid);
        }
        shown = true;
    }

    public void Pump(int timeoutMs)
    {
        int end = Environment.TickCount + timeoutMs + 500;
        MSG msg;
        while (Environment.TickCount < end)
        {
            if (PeekMessage(out msg, IntPtr.Zero, 0, 0, PM_REMOVE))
            {
                TranslateMessage(ref msg);
                DispatchMessage(ref msg);
            }
            else { System.Threading.Thread.Sleep(50); }
        }
    }

    private delegate IntPtr WndProcDelegate(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

    public void Dispose()
    {
        if (shown) { Shell_NotifyIcon(NIM_DELETE, ref nid); shown = false; }
        if (hWnd != IntPtr.Zero) { DestroyWindow(hWnd); hWnd = IntPtr.Zero; }
    }
}
"@ -ReferencedAssemblies "System.Windows.Forms","System.Drawing"

$n = New-Object SilentNotifier
try { $n.Show($Title, $Message, 5000); $n.Pump(5000) } finally { $n.Dispose() }