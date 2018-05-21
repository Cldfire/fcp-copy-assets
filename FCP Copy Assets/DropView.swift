//

import Cocoa
import SWXMLHash

class DropView: NSView {
    let pasteboardType = NSPasteboard.PasteboardType(rawValue: "public.utf8-plain-text")
    let folderMutex = Mutex.init()
    var folder: URL?
    
    @IBOutlet weak var lastActionText: NSTextField!
    
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
        
        askUserForCopyLocation()
        
        // Process the XML while the user is selecting a location
        DispatchQueue.global().async {
            var srcPaths: [URL] = []
            
            var err: ParsingError? = nil
            let parser = SWXMLHash.config { config in
                config.detectParsingErrors = true
            }.parse(data)
            
            switch parser {
            case .parsingError(let error):
                err = error
            default:
                err = nil
            }
            
            if let error = err {
                DispatchQueue.main.async {
                    buildAlert(
                        """
                        A parsing error ocurred at line \(error.line) column \(error.column);
                        no files will be copied
                        """
                    ).runModal()
                }
            }
            
            for elem in parser["fcpxml"]["resources"]["asset"].all {
                srcPaths.append(URL.init(string: elem.element!.attribute(by: "src")!.text)!)
            }
            
            // Now that we have what we needed from the XML, lock `folder` and do copying
            // if `folder` has been set to something
            self.folderMutex.lock()
            if let folder = self.folder {
                let copied = self.copyFilesToFolder(srcPaths, folder: folder)
                let attempted = srcPaths.count
                let folderString = folder.absoluteString.removingPercentEncoding!

                DispatchQueue.main.async {
                    self.lastActionText.stringValue = "Copied \(copied)/\(attempted) files to \(folderString)"
                }
                
                self.folder = nil
            }
            self.folderMutex.unlock()
        }
        
        return true
    }
    
    /// Determines where the user wants to copy the assets; does not block.
    ///
    /// The first thing this method does is lock `folderMutex`. It then creates and displays an
    /// `NSOpenPanel`, setting `folder` to the chosen folder if OK was clicked and unlocking the
    /// mutex regardless.
    func askUserForCopyLocation() {
        folderMutex.lock()
        
        let openPanel = NSOpenPanel.init()
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        
        openPanel.begin(completionHandler: { response in
            if response == NSApplication.ModalResponse.OK {
                self.folder = openPanel.url!
            }
            
            self.folderMutex.unlock()
        })
    }
    
    /// Returns the number of files that were successfully copied.
    ///
    /// File names are not changed in the copying process. If the names of any files to be copied
    /// conflict with the names of files already in `folder`, those files will fail to copy.
    ///
    /// Any errors that occur will be displayed to the user in an alert after an attempt has
    /// been made to copy every file.
    func copyFilesToFolder(_ files: [URL], folder: URL) -> Int {
        var errors: [Error] = []
        var copied = files.count;
        
        for url in files {
            do {
                try FileManager.default.copyItem(
                    at: url,
                    to: folder.appendingPathComponent(url.lastPathComponent)
                )
            } catch let error {
                copied -= 1
                errors.append(error)
            }
        }
        
        if !errors.isEmpty {
            DispatchQueue.main.async {
                buildAlert("\(errors.map { $0.localizedDescription })").runModal()
            }
        }
        
        return copied
    }
}

/// A simple helper that configures an `NSAlert` instance with a single "OK" button and the
/// provided text.
func buildAlert(_ text: String) -> NSAlert {
    let alert = NSAlert()
    alert.messageText = text
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    
    return alert
}
