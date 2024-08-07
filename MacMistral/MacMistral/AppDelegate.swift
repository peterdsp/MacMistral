//
//  AppDelegate.swift
//  MacMistral
//
//  Created by Petros Dhespollari on 16/3/24.
//

import Cocoa
import HotKey
import SwiftUI
import WebKit

struct AboutView: View {
    var body: some View {
        VStack {
            Text("MacMistral")
                .font(.title)
                .padding(.bottom)
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .padding(.bottom)
            } else {
                Text("Error: App icon not found")
                    .foregroundColor(.red)
            }
            Text("Developed by Petros Dhespollari")
                .font(.subheadline)
            Text("Version 1.1")
                .font(.subheadline)
                .padding(.top)
            Button("Visit Developer's Website") {
                if let url = URL(string: "https://peterdsp.dev") {
                    NSWorkspace.shared.open(url)
                }
            }
            .padding(.top)
        }
        .padding()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    var selectedAIChatTitle: String = "Mistral AI Chat"
    private let aiChatOptions: [String: String] = [
        "Mistral": "https://chat.mistral.ai/chat/",
        "Claude": "https://claude.ai/chats",
        "ChatGPT": "https://chat.openai.com/#",
        "Gemini": "https://gemini.google.com/app"
    ]
    
    internal var windowSizeOptions: [String: CGSize] = [
        "Small": CGSize(width: 400, height: 300),
        "Medium": CGSize(width: 500, height: 600),
        "Large": CGSize(width: 700, height: 800)
    ]
    
    var chatOptions: [String: String] {
        return aiChatOptions
    }
    
    public var popover: NSPopover!
    private var menu: NSMenu!
    
    let hotKey = HotKey(key: .c, modifiers: [.shift, .command]) // Global hotkey
    
    var hotCKey: HotKey?
    var hotVKey: HotKey?
    var hotZKey: HotKey?
    var hotXKey: HotKey?
    var hotAKey: HotKey?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        NSApp.setActivationPolicy(.accessory)
        
        if let button = statusItem.button {
            let icon = NSImage(named: "MenuBarIcon")!.resized(to: CGSize(width: 14, height: 14))
            icon.isTemplate = true
            button.image = icon
            button.action = #selector(handleMenuIconAction(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Check if there is a saved AI chat title, set default to "Mistral" if not
        if let savedAIChatTitle = UserDefaults.standard.string(forKey: "selectedAIChatTitle") {
            selectedAIChatTitle = savedAIChatTitle
        } else {
            selectedAIChatTitle = "Mistral"
            UserDefaults.standard.set(selectedAIChatTitle, forKey: "selectedAIChatTitle")
        }

        constructPopover()
        constructMenu()

        hotKey.keyUpHandler = { // Global hotkey handler
            self.togglePopover()
        }
    }
    
    @objc func handleMenuIconAction(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            removeMenu()
            togglePopover()
        }
    }
    
    func menuDidClose(_ menu: NSMenu) {
        removeMenu()
    }
    
    @objc func didTapOne() {
        let aboutView = AboutView()
        let aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        let aboutWindowController = AboutWindowController(window: aboutWindow)
        aboutWindow.contentView = NSHostingView(rootView: aboutView)
        aboutWindow.center()
        aboutWindow.makeKeyAndOrderFront(nil)
        aboutWindowController.showWindow(nil)
    }
    
    @objc func didTapTwo() {
        WebViewHelper.clean()
    }
    
    @objc func changeAIChat(sender: NSMenuItem) {
        if let urlString = sender.representedObject as? String {
            selectedAIChatTitle = sender.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let initialAddress = aiChatOptions[selectedAIChatTitle] ?? "https://chat.mistral.ai/chat/"
            let newHostingController = NSHostingController(rootView: MainUI(initialAddress: initialAddress))
            let newPopupContentViewController = MacMistralPopup()
            newPopupContentViewController.hostingController = newHostingController
            popover.contentViewController = newPopupContentViewController
            popover.contentSize = newHostingController.view.fittingSize
            
            updateMenuItemsState()
            UserDefaults.standard.set(selectedAIChatTitle, forKey: "selectedAIChatTitle")
        }
    }
    
    @objc func changeWindowSize(sender: NSMenuItem) {
        if let newSize = windowSizeOptions[sender.title] {
            popover.contentSize = newSize
            updateWindowSizeMenuItemsState()
        }
    }
    
    func updateMenuItemsState() {
        if let changeChatAIMenuItem = menu.item(withTitle: "Change AI Chat"),
           let changeChatAISubmenu = changeChatAIMenuItem.submenu
        {
            for item in changeChatAISubmenu.items {
                item.state = (item.title == selectedAIChatTitle) ? .on : .off
            }
        }
    }
    
    func updateWindowSizeMenuItemsState() {
        if let windowSizeMenuItem = menu.item(withTitle: "Change Window Size"),
           let windowSizeSubmenu = windowSizeMenuItem.submenu
        {
            for item in windowSizeSubmenu.items {
                item.state = (popover.contentSize == windowSizeOptions[item.title]) ? .on : .off
            }
        }
    }
    
    func constructMenu() {
        menu = NSMenu()
        let aboutMenuItem = NSMenuItem(title: "About", action: #selector(didTapOne), keyEquivalent: "1")
        let cleanCookiesMenuItem = NSMenuItem(title: "Clean Cookies", action: #selector(didTapTwo), keyEquivalent: "2")
        menu.addItem(aboutMenuItem)
        menu.addItem(cleanCookiesMenuItem)
        menu.addItem(NSMenuItem.separator())

        let changeChatAIMenuItem = NSMenuItem(title: "Change AI Chat", action: nil, keyEquivalent: "")
        let changeChatAISubmenu = NSMenu()

        let aiChatOrder = ["Mistral", "Claude", "ChatGPT", "Gemini"]
        for title in aiChatOrder {
            if let url = aiChatOptions[title] {
                let menuItem = NSMenuItem(title: title, action: #selector(changeAIChat(sender:)), keyEquivalent: "")
                menuItem.representedObject = url
                changeChatAISubmenu.addItem(menuItem)
            }
        }

        changeChatAIMenuItem.submenu = changeChatAISubmenu
        menu.addItem(changeChatAIMenuItem)

        let changeWindowSizeMenuItem = NSMenuItem(title: "Change Window Size", action: nil, keyEquivalent: "")
        let changeWindowSizeSubmenu = NSMenu()

        let sortedWindowSizeKeys = ["Small", "Medium", "Large"]
        for size in sortedWindowSizeKeys {
            if let _ = windowSizeOptions[size] {
                let menuItem = NSMenuItem(title: size, action: #selector(changeWindowSize(sender:)), keyEquivalent: "")
                changeWindowSizeSubmenu.addItem(menuItem)
            }
        }
        changeWindowSizeMenuItem.submenu = changeWindowSizeSubmenu
        menu.addItem(changeWindowSizeMenuItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.delegate = self
    }
    
    func constructPopover() {
        popover = NSPopover()
        popover.contentViewController = MacMistralPopup()
        popover.delegate = self
        popover.behavior = .transient
        popover.contentSize = windowSizeOptions["Medium"] ?? CGSize(width: 500, height: 600)
    }
    
    func showMenu() {
        statusItem.menu = menu
        statusItem.popUpMenu(menu)
    }
    
    func removeMenu() {
        statusItem.menu = nil
    }
    
    func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
            deinitKeys()
        } else {
            if let button = statusItem.button {
                NSApplication.shared.activate(ignoringOtherApps: true)
                updateMenuItemsState()
                updateWindowSizeMenuItemsState()
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.level = .floating
                popover.contentViewController?.view.window?.makeKey()
                constructKeys()
            }
        }
    }

    private func deinitKeys() {
        hotCKey = nil
        hotVKey = nil
        hotXKey = nil
        hotZKey = nil
        hotAKey = nil
    }

    private func constructKeys() {
        hotCKey = HotKey(key: .c, modifiers: [.command]) // Global hotkey
        hotVKey = HotKey(key: .v, modifiers: [.command]) // Global hotkey
        hotZKey = HotKey(key: .z, modifiers: [.command]) // Global hotkey
        hotXKey = HotKey(key: .x, modifiers: [.command]) // Global hotkey
        hotAKey = HotKey(key: .a, modifiers: [.command]) // Global hotkey
        
        hotCKey?.keyDownHandler = {
            NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self)
        }
        
        hotVKey?.keyDownHandler = {
            NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self)
        }
        
        hotXKey?.keyDownHandler = {
            NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self)
        }
        
        hotZKey?.keyDownHandler = {
            NSApp.sendAction(Selector("undo:"), to: nil, from: self)
        }
        
        hotAKey?.keyDownHandler = {
            NSApp.sendAction(#selector(NSStandardKeyBindingResponding.selectAll(_:)), to: nil, from: self)
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

extension AppDelegate: NSPopoverDelegate {
    func popoverWillClose(_ notification: Notification) {
        deinitKeys()
    }
}

extension NSImage {
    func resized(to size: CGSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        draw(in: NSRect(origin: .zero, size: size), from: NSZeroRect, operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}

class AboutWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.delegate = self
    }
}

extension AboutWindowController: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil) // Hide the window instead of closing
        return false // Prevent the window from closing
    }
}
