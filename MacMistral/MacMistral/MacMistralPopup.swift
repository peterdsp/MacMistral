//
//  MacMistralPopup.swift
//  MacMistral
//
//  Created by Petros Dhespollari on 16/3/24.
//

import AppKit
import SwiftUI
import WebKit

class MacMistralPopup: NSViewController {
    override func loadView() {
        // create a hosting controller with your SwiftUI view
        let hostingController = NSHostingController(rootView: MainUI())
        self.view = hostingController.view
        self.view.frame = CGRect(origin: .zero, size: .init(width: 500, height: 700))
    }

    override func mouseDragged(with event: NSEvent) {
        guard let appDelegate: AppDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        var size = appDelegate.popover?.contentSize ?? CGSize.zero
        size.width += event.deltaX
        size.height += event.deltaY
        // Update popover size depend on your reference
        appDelegate.popover?.contentSize = size
    }
}

struct MainUI: View {
    @State private var action = WebViewAction.idle
    @State private var state = WebViewState.empty
    @State private var address = "https://chat.mistral.ai/chat/"

    var webConfig: WebViewConfig {
        var defaultC = WebViewConfig.default
        return defaultC
    }

    var body: some View {
        VStack(spacing: 0.0) {
            self.errorView
            WebView(config: self.webConfig,
                    action: self.$action,
                    state: self.$state,
                    restrictedPages: nil)
            Image(systemName: "line.1.horizontal")
        }
        .onAppear {
            if let url = URL(string: address) {
                self.action = .load(URLRequest(url: url))
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var navigationToolbar: some View {
        HStack(spacing: 10) {
            if self.state.isLoading {
                if #available(iOS 14, macOS 10.15, *) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Loading")
                }
            }
            Spacer()
            Button(action: {
                self.action = .reload
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .imageScale(.large)
                    .foregroundColor(.init(nsColor: .labelColor))
            }
            if self.state.canGoBack {
                Button(action: {
                    self.action = .goBack
                }) {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                        .foregroundColor(.init(nsColor: .labelColor))
                }
            }
            if self.state.canGoForward {
                Button(action: {
                    self.action = .goForward
                }) {
                    Image(systemName: "chevron.right")
                        .imageScale(.large)
                        .foregroundColor(.init(nsColor: .labelColor))
                }
            }
        }.background(Color(nsColor: .windowBackgroundColor))
            .padding([.top, .leading, .trailing, .bottom], 15.0)
    }

    private var errorView: some View {
        Group {
            if let error = state.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
            }
        }
    }
}

enum WebViewHelper {
    static func clean() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        print("[WebCacheCleaner] All cookies deleted")

        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                print("[WebCacheCleaner] Record \(record) deleted")
            }
        }
    }
}

struct MainUI_Previews: PreviewProvider {
    static var previews: some View {
        MainUI()
    }
}
