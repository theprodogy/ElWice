import QtQml

QtObject {
    readonly property var sep: ({sep: true})

    readonly property var table: [
        [/brave/, "browser", "Brave", "https://support.brave.com"],
        [/helium/, "browser", "Helium", ""],
        [/chromium/, "browser", "Chromium", ""],
        [/chrome/, "browser", "Chrome", "https://support.google.com/chrome"],
        [/msedge/, "browser", "Edge", "https://support.microsoft.com/microsoft-edge"],
        [/firefox/, "browser", "Firefox", "https://support.mozilla.org"],
        [/vivaldi/, "browser", "Vivaldi", "https://help.vivaldi.com"],
        [/^opera/, "browser", "Opera", "https://help.opera.com"],
        [/^(code|vscode)([^a-z]|$)|^visual ?studio ?code/, "code", "Visual Studio Code", ""],
        [/discord/, "discord", "Discord", ""],
        [/spotify/, "spotify", "Spotify", ""],
        [/^(explorer|microsoft\.windows\.explorer)$/, "explorer", "File Explorer", ""],
        [/wezterm/, "wezterm", "WezTerm", ""],
        [/notepad/, "notepad", "Notepad", ""],
        [/windowsterminal/, "generic", "Terminal", ""],
        [/cursor/, "generic", "Cursor", ""],
        [/obsidian/, "generic", "Obsidian", ""],
        [/steam/, "generic", "Steam", ""]
    ]

    function i(name, keys) {
        return {name: name, keys: keys}
    }

    function a(name, action) {
        return {name: name, action: action}
    }

    function u(name, url) {
        return {name: name, url: url}
    }

    function x(name, exec) {
        return {name: name, exec: exec}
    }

    function m(title, items) {
        return {title: title, items: items}
    }

    function resolve(toplevel) {
        if (!toplevel)
            return {name: "Finder", menus: finder()}
        const id = String(toplevel.appId ?? "").toLowerCase().replace(/^.*[\\/]/, "").replace(/\.exe$/, "")
        const hit = table.find(e => e[0].test(id))
        if (hit)
            return {name: hit[2], menus: menusFor(hit[1], hit[2], hit[3])}
        const name = id !== "" ? id.charAt(0).toUpperCase() + id.slice(1) : (toplevel.title || "Finder")
        return {name: name, menus: menusFor("generic", name, "")}
    }

    function menusFor(kind, name, help) {
        if (kind === "browser") return browser(name, help)
        if (kind === "code") return code()
        if (kind === "discord") return discord()
        if (kind === "spotify") return spotify()
        if (kind === "explorer") return explorer()
        if (kind === "wezterm") return wezterm()
        if (kind === "notepad") return notepad()
        return generic(name)
    }

    function windowMenu(extra) {
        return m("Window", [a("Minimize", "minimize"), a("Zoom", "zoom")].concat(extra))
    }

    function zoomItems() {
        return [i("Actual Size", "Ctrl+0"), i("Zoom In", "Ctrl+="), i("Zoom Out", "Ctrl+-")]
    }

    function searchUrl(name) {
        return "https://duckduckgo.com/?q=" + encodeURIComponent(name + " help")
    }

    function clipboard() {
        return [i("Cut", "Ctrl+X"), i("Copy", "Ctrl+C"), i("Paste", "Ctrl+V")]
    }

    function finder() {
        return [
            m("File", [x("New Finder Window", ["explorer.exe"]), sep, a("Close Window", "close")]),
            m("Edit", [i("Undo", "Ctrl+Z"), i("Redo", "Ctrl+Y"), sep].concat(clipboard(), [i("Select All", "Ctrl+A")])),
            m("View", [i("Refresh", "F5")]),
            m("Go", [
                x("Desktop", ["explorer.exe", "shell:Desktop"]),
                x("Documents", ["explorer.exe", "shell:Personal"]),
                x("Downloads", ["explorer.exe", "shell:Downloads"]),
                x("Applications", ["explorer.exe", "shell:AppsFolder"])
            ]),
            m("Window", [a("Minimize", "minimize"), a("Zoom", "zoom")]),
            m("Help", [u("Windows Help", "https://support.microsoft.com/windows")])
        ]
    }

    function generic(name) {
        return [
            m("File", [
                i("New", "Ctrl+N"), i("Open…", "Ctrl+O"), sep, i("Save", "Ctrl+S"), i("Print…", "Ctrl+P"),
                sep, i("Close Window", "Alt+F4")
            ]),
            m("Edit", [i("Undo", "Ctrl+Z"), i("Redo", "Ctrl+Y"), sep].concat(clipboard(), [i("Select All", "Ctrl+A"), sep, i("Find…", "Ctrl+F")])),
            m("View", zoomItems().concat([sep, i("Enter Full Screen", "F11")])),
            windowMenu([sep, i("Close Window", "Alt+F4")]),
            m("Help", [u(name + " Help", searchUrl(name))])
        ]
    }

    function browser(name, help) {
        return [
            m("File", [
                i("New Tab", "Ctrl+T"), i("New Window", "Ctrl+N"), i("New Private Window", "Ctrl+Shift+N"),
                i("Reopen Closed Tab", "Ctrl+Shift+T"), sep, i("Open File…", "Ctrl+O"), i("Open Location…", "Ctrl+L"),
                sep, i("Close Tab", "Ctrl+W"), i("Close Window", "Ctrl+Shift+W"), sep,
                i("Save Page As…", "Ctrl+S"), i("Print…", "Ctrl+P")
            ]),
            m("Edit", [i("Undo", "Ctrl+Z"), i("Redo", "Ctrl+Shift+Z"), sep].concat(clipboard(), [
                i("Paste and Match Style", "Ctrl+Shift+V"), i("Select All", "Ctrl+A"), sep,
                i("Find…", "Ctrl+F"), i("Find Next", "Ctrl+G"), i("Find Previous", "Ctrl+Shift+G")
            ])),
            m("View", [
                i("Always Show Bookmarks Bar", "Ctrl+Shift+B"), sep, i("Stop", "Esc"), i("Reload This Page", "Ctrl+R"),
                i("Hard Reload", "Ctrl+Shift+R"), sep, i("Enter Full Screen", "F11")
            ].concat(zoomItems(), [sep, i("View Source", "Ctrl+U"), i("Developer Tools", "F12")])),
            m("History", [
                i("Home", "Alt+Home"), i("Back", "Alt+Left"), i("Forward", "Alt+Right"), sep,
                i("Reopen Closed Tab", "Ctrl+Shift+T"), i("Show Full History", "Ctrl+H"),
                i("Clear Browsing Data…", "Ctrl+Shift+Delete")
            ]),
            m("Bookmarks", [
                i("Bookmark This Tab…", "Ctrl+D"), i("Bookmark All Tabs…", "Ctrl+Shift+D"), sep,
                i("Bookmark Manager", "Ctrl+Shift+O")
            ]),
            windowMenu([
                sep, i("Select Next Tab", "Ctrl+Tab"), i("Select Previous Tab", "Ctrl+Shift+Tab"), sep,
                i("Downloads", "Ctrl+J"), i("Task Manager", "Shift+Esc")
            ]),
            m("Help", [u(name + " Help", help !== "" ? help : searchUrl(name))])
        ]
    }

    function code() {
        return [
            m("File", [
                i("New Text File", "Ctrl+N"), i("New Window", "Ctrl+Shift+N"), sep, i("Open File…", "Ctrl+O"),
                i("Open Recent…", "Ctrl+R"), sep, i("Save", "Ctrl+S"), i("Save As…", "Ctrl+Shift+S"), sep,
                i("Settings", "Ctrl+,"), sep, i("Close Editor", "Ctrl+W"), i("Close Window", "Ctrl+Shift+W")
            ]),
            m("Edit", [i("Undo", "Ctrl+Z"), i("Redo", "Ctrl+Y"), sep].concat(clipboard(), [
                sep, i("Find", "Ctrl+F"), i("Replace", "Ctrl+H"), i("Find in Files", "Ctrl+Shift+F"),
                i("Replace in Files", "Ctrl+Shift+H"), sep, i("Toggle Line Comment", "Ctrl+/"),
                i("Toggle Block Comment", "Shift+Alt+A"), i("Format Document", "Shift+Alt+F")
            ])),
            m("Selection", [
                i("Select All", "Ctrl+A"), i("Expand Selection", "Shift+Alt+Right"),
                i("Shrink Selection", "Shift+Alt+Left"), sep, i("Copy Line Up", "Shift+Alt+Up"),
                i("Copy Line Down", "Shift+Alt+Down"), i("Move Line Up", "Alt+Up"), i("Move Line Down", "Alt+Down"),
                sep, i("Add Next Occurrence", "Ctrl+D"), i("Select All Occurrences", "Ctrl+Shift+L")
            ]),
            m("View", [
                i("Command Palette…", "Ctrl+Shift+P"), sep, i("Explorer", "Ctrl+Shift+E"), i("Search", "Ctrl+Shift+F"),
                i("Source Control", "Ctrl+Shift+G"), i("Run and Debug", "Ctrl+Shift+D"), i("Extensions", "Ctrl+Shift+X"),
                sep, i("Problems", "Ctrl+Shift+M"), i("Output", "Ctrl+Shift+U"), i("Debug Console", "Ctrl+Shift+Y"),
                i("Terminal", "Ctrl+`"), sep, i("Toggle Primary Side Bar", "Ctrl+B"), i("Toggle Panel", "Ctrl+J"),
                i("Word Wrap", "Alt+Z"), i("Toggle Full Screen", "F11"), sep
            ].concat(zoomItems())),
            m("Go", [
                i("Back", "Alt+Left"), i("Forward", "Alt+Right"), sep, i("Go to File…", "Ctrl+P"),
                i("Go to Symbol in Workspace…", "Ctrl+T"), i("Go to Symbol in Editor…", "Ctrl+Shift+O"),
                i("Go to Line/Column…", "Ctrl+G"), sep, i("Go to Definition", "F12"), i("Peek Definition", "Alt+F12"),
                sep, i("Next Problem", "F8"), i("Previous Problem", "Shift+F8")
            ]),
            m("Run", [
                i("Start Debugging", "F5"), i("Run Without Debugging", "Ctrl+F5"), i("Stop Debugging", "Shift+F5"),
                i("Restart Debugging", "Ctrl+Shift+F5"), sep, i("Step Over", "F10"), i("Step Into", "F11"),
                i("Step Out", "Shift+F11"), sep, i("Toggle Breakpoint", "F9")
            ]),
            m("Terminal", [
                i("New Terminal", "Ctrl+Shift+`"), i("Toggle Terminal", "Ctrl+`"), sep, i("Run Build Task…", "Ctrl+Shift+B")
            ]),
            windowMenu([sep, i("Previous Editor", "Ctrl+PageUp"), i("Next Editor", "Ctrl+PageDown")]),
            m("Help", [
                u("Documentation", "https://code.visualstudio.com/docs"), u("Release Notes", "https://code.visualstudio.com/updates"),
                u("Report Issue", "https://github.com/microsoft/vscode/issues/new/choose"), sep,
                i("Toggle Developer Tools", "Ctrl+Shift+I")
            ])
        ]
    }

    function discord() {
        return [
            m("File", [i("User Settings", "Ctrl+,"), i("Quick Switcher", "Ctrl+K"), sep, i("Close Window", "Alt+F4")]),
            m("Edit", [i("Undo", "Ctrl+Z"), i("Redo", "Ctrl+Shift+Z"), sep].concat(clipboard(), [
                i("Select All", "Ctrl+A"), sep, i("Search", "Ctrl+F")
            ])),
            m("View", [i("Reload", "Ctrl+R"), i("Enter Full Screen", "F11"), sep].concat(zoomItems())),
            m("Go", [
                i("Back", "Ctrl+["), i("Forward", "Ctrl+]"), sep, i("Previous Channel", "Alt+Up"),
                i("Next Channel", "Alt+Down"), i("Previous Unread Channel", "Alt+Shift+Up"),
                i("Next Unread Channel", "Alt+Shift+Down"), sep, i("Previous Server", "Ctrl+Alt+Up"),
                i("Next Server", "Ctrl+Alt+Down")
            ]),
            windowMenu([sep, i("Toggle Mute", "Ctrl+Shift+M"), i("Toggle Deafen", "Ctrl+Shift+D")]),
            m("Help", [i("Keyboard Shortcuts", "Ctrl+/"), u("Discord Help Center", "https://support.discord.com")])
        ]
    }

    function spotify() {
        return [
            m("File", [i("New Playlist", "Ctrl+N"), i("New Playlist Folder", "Ctrl+Shift+N"), sep, i("Close Window", "Alt+F4"), i("Quit Spotify", "Ctrl+Shift+W")]),
            m("Edit", [i("Undo", "Ctrl+Z"), i("Redo", "Ctrl+Shift+Z"), sep].concat(clipboard(), [
                i("Select All", "Ctrl+A"), sep, i("Search", "Ctrl+L"), i("Preferences…", "Ctrl+P")
            ])),
            m("Playback", [
                i("Play/Pause", "Space"), i("Next", "Ctrl+Right"), i("Previous", "Ctrl+Left"), sep,
                i("Skip Forward", "Shift+Right"), i("Skip Back", "Shift+Left"), sep, i("Volume Up", "Ctrl+Up"),
                i("Volume Down", "Ctrl+Down"), sep, i("Shuffle", "Ctrl+S"), i("Repeat", "Ctrl+R"), sep,
                i("Like", "Alt+Shift+B")
            ]),
            m("View", [i("Back", "Alt+Left"), i("Forward", "Alt+Right"), sep, i("Enter Full Screen", "F11"), sep].concat(zoomItems())),
            windowMenu([]),
            m("Help", [u("Spotify Support", "https://support.spotify.com"), u("Spotify Community", "https://community.spotify.com")])
        ]
    }

    function explorer() {
        return [
            m("File", [
                i("New Tab", "Ctrl+T"), i("New Window", "Ctrl+N"), i("New Folder", "Ctrl+Shift+N"), sep,
                i("Rename", "F2"), i("Delete", "Delete"), i("Properties", "Alt+Enter"), sep, i("Close Tab", "Ctrl+W")
            ]),
            m("Edit", [i("Undo", "Ctrl+Z"), i("Redo", "Ctrl+Y"), sep].concat(clipboard(), [
                i("Copy Path", "Ctrl+Shift+C"), i("Select All", "Ctrl+A"), sep, i("Find", "Ctrl+F")
            ])),
            m("View", [
                i("Extra Large Icons", "Ctrl+Shift+1"), i("Large Icons", "Ctrl+Shift+2"), i("Medium Icons", "Ctrl+Shift+3"),
                i("Small Icons", "Ctrl+Shift+4"), i("List", "Ctrl+Shift+5"), i("Details", "Ctrl+Shift+6"), sep,
                i("Preview Pane", "Alt+P"), i("Details Pane", "Alt+Shift+P"), sep, i("Refresh", "F5"), i("Enter Full Screen", "F11")
            ]),
            m("Go", [
                i("Back", "Alt+Left"), i("Forward", "Alt+Right"), i("Enclosing Folder", "Alt+Up"),
                i("Address Bar", "Ctrl+L"), sep, x("Desktop", ["explorer.exe", "shell:Desktop"]),
                x("Documents", ["explorer.exe", "shell:Personal"]), x("Downloads", ["explorer.exe", "shell:Downloads"])
            ]),
            windowMenu([sep, i("Next Tab", "Ctrl+Tab"), i("Previous Tab", "Ctrl+Shift+Tab"), sep, i("Close Window", "Alt+F4")]),
            m("Help", [u("Windows Help", "https://support.microsoft.com/windows")])
        ]
    }

    function wezterm() {
        return [
            m("Shell", [
                i("New Tab", "Ctrl+Shift+T"), i("New Window", "Ctrl+Shift+N"), sep, i("Close Tab", "Ctrl+Shift+W"),
                i("Close Window", "Alt+F4")
            ]),
            m("Edit", [
                i("Copy", "Ctrl+Shift+C"), i("Paste", "Ctrl+Shift+V"), sep, i("Search", "Ctrl+Shift+F"),
                i("Quick Select", "Ctrl+Shift+Space"), i("Copy Mode", "Ctrl+Shift+X"), sep,
                i("Clear Scrollback", "Ctrl+Shift+K"), i("Command Palette", "Ctrl+Shift+P")
            ]),
            m("View", [
                i("Enter Full Screen", "Alt+Enter"), sep, i("Scroll Up", "Shift+PageUp"), i("Scroll Down", "Shift+PageDown"),
                sep, i("Reset Font Size", "Ctrl+0"), i("Increase Font Size", "Ctrl+="), i("Decrease Font Size", "Ctrl+-"),
                sep, i("Debug Overlay", "Ctrl+Shift+L")
            ]),
            windowMenu([sep, i("Next Tab", "Ctrl+Tab"), i("Previous Tab", "Ctrl+Shift+Tab")]),
            m("Help", [u("WezTerm Documentation", "https://wezterm.org"), u("Default Key Bindings", "https://wezterm.org/config/default-keys.html")])
        ]
    }

    function notepad() {
        return [
            m("File", [
                i("New Tab", "Ctrl+N"), i("New Window", "Ctrl+Shift+N"), i("Open…", "Ctrl+O"), sep, i("Save", "Ctrl+S"),
                i("Save As…", "Ctrl+Shift+S"), i("Save All", "Ctrl+Alt+S"), sep, i("Print…", "Ctrl+P"), sep,
                i("Close Tab", "Ctrl+W"), i("Exit", "Alt+F4")
            ]),
            m("Edit", [i("Undo", "Ctrl+Z"), i("Redo", "Ctrl+Y"), sep].concat(clipboard(), [
                i("Delete", "Delete"), i("Select All", "Ctrl+A"), sep, i("Find…", "Ctrl+F"), i("Find Next", "F3"),
                i("Find Previous", "Shift+F3"), i("Replace…", "Ctrl+H"), i("Go To…", "Ctrl+G"), sep, i("Time/Date", "F5")
            ])),
            m("View", zoomItems().concat([sep, i("Enter Full Screen", "F11")])),
            windowMenu([sep, i("Next Tab", "Ctrl+Tab"), i("Previous Tab", "Ctrl+Shift+Tab")]),
            m("Help", [u("Windows Help", "https://support.microsoft.com/windows")])
        ]
    }
}
