import SwiftUI
#if canImport(VisionKit) && canImport(UIKit)
import VisionKit
import UIKit

public struct DocumentScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedPages: [UIImage]
    @Environment(\.dismiss) private var dismiss

    public init(scannedPages: Binding<[UIImage]>) {
        self._scannedPages = scannedPages
    }

    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerRepresentable

        init(_ parent: DocumentScannerRepresentable) {
            self.parent = parent
        }

        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            parent.scannedPages.append(contentsOf: images)
            parent.dismiss()
        }

        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("VisionKit scanner failed: \(error.localizedDescription)")
            parent.dismiss()
        }
    }
}
#else
public struct DocumentScannerRepresentable: View {
    @Binding var scannedPages: [Any]
    public init(scannedPages: Binding<[Any]>) {
        self._scannedPages = scannedPages
    }
    public var body: some View {
        Text("VisionKit Document Scanner is available on physical iOS devices.")
            .font(.subheadline)
            .padding()
    }
}
#endif
