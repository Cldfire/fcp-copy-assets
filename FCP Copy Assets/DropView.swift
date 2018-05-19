//

import Cocoa
import SWXMLHash

class DropView: NSView {
    let pasteboardType = NSPasteboard.PasteboardType(rawValue: "public.utf8-plain-text")
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        registerForDraggedTypes([pasteboardType])
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let data = sender.draggingPasteboard().data(forType: pasteboardType) else {
            return false
        }
        
        var srcPaths: [URL] = []
        var err: ParsingError? = nil
        let parser = SWXMLHash.config {
            config in
            config.detectParsingErrors = true
        }.parse(data)
        
        switch parser {
        case .parsingError(let error):
            err = error
        default:
            err = nil
        }
        
        if let error = err {
            self.showAlert("A parsing error ocurred at line \(error.line) column \(error.column)")
            return false
        }
        
        for elem in parser["fcpxml"]["resources"]["asset"].all {
            srcPaths.append(URL.init(string: elem.element!.attribute(by: "src")!.text)!)
        }
        
        handleCopyingAssets(self.window!, assets: srcPaths)
        
        return true
    }
    
    func showAlert(_ text: String) {
        let alert = NSAlert()
        alert.messageText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    /// Determines where the user wants to copy the assets and then handles the copying and potential errors.
    func handleCopyingAssets(_ window: NSWindow, assets: [URL]) {
        let openPanel = NSOpenPanel.init()
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        
        openPanel.beginSheetModal(for: window, completionHandler: { response in
            if response == NSApplication.ModalResponse.OK {
                self.copyFilesToFolder(assets, folder: openPanel.url!)
            }
        })
    }
    
    func copyFilesToFolder(_ files: [URL], folder: URL) {
        var errors: [Error] = []
        
        for url in files {
            do {
                try FileManager.default.copyItem(at: url, to: folder.appendingPathComponent(url.lastPathComponent))
            } catch let error {
                errors.append(error)
            }
        }
        
        if !errors.isEmpty {
            showAlert("\(errors.map { $0.localizedDescription })")
        }
    }
}
