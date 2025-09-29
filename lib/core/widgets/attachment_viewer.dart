import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pdfx/pdfx.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' ;
// import 'package:file_saver/file_saver.dart';
// import 'package:open_filex/open_filex.dart';

class AttachmentViewer extends StatefulWidget {
  final String url;
  final String? fileName;
  final String? fileType;

  const AttachmentViewer({super.key, required this.url, this.fileName, required this.fileType});

  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  bool _isPdf = false;

  // bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _isPdf = widget.fileType!.toLowerCase() == 'pdf';
  }

  // Future<void> _downloadAndOpenFile() async {
  //   setState(() => _isDownloading = true);
  //   try {
  //     // For web or mobile download
  //     if (widget.url.startsWith('http')) {
  //       if (await canLaunchUrl(Uri.parse(widget.url))) {
  //         await launchUrl(Uri.parse(widget.url));
  //       }
  //     } else {
  //       // For local files (if needed)
  //       final ByteData data = await rootBundle.load(widget.url);
  //       final Uint8List bytes = data.buffer.asUint8List();
  //       final String path = await FileSaver.instance.saveFile(
  //         name: widget.fileName ?? 'attachment_${DateTime.now().toIso8601String()}',
  //         bytes: bytes,
  //         fileExtension: _isPdf ? 'pdf' : 'jpg',
  //         mimeType: _isPdf ? MimeType.pdf : MimeType.jpeg,
  //       );
  //       await OpenFilex.open(path);
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to open file: $e')),
  //     );
  //   } finally {
  //     setState(() => _isDownloading = false);
  //   }
  // }

  void _showFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(widget.fileName ?? 'Attachment'),
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.download),
            //     onPressed: _downloadAndOpenFile,
            //   ),
            // ],
          ),
          body: _isPdf
              ? PdfViewPinch(
                  controller: PdfControllerPinch(
                    document: PdfDocument.openData(
                      NetworkAssetBundle(
                        Uri.parse(widget.url))
                        .load(widget.url)
                        .then((data) => data.buffer.asUint8List()
                      ),
                    ),
                  ),
                )
              : InteractiveViewer(
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: widget.url,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showFullScreen,
          child:  _isPdf
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.picture_as_pdf, size: 48, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 8),
                      const Text('PDF Document'),
                    ],
                  )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    width: 100,
                    imageUrl: widget.url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(
                      padding: EdgeInsets.all(16),
                    )),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                  ),
          ),
  
        const SizedBox(height: 8),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     OutlinedButton.icon(
        //       label: _isDownloading
        //           ? const SizedBox(
        //               width: 16,
        //               height: 16,
        //               child: CircularProgressIndicator(strokeWidth: 2),
        //             )
        //           : const Icon(Icons.download, size: 20),
        //       onPressed: _downloadAndOpenFile,
        //     ),
        //     const SizedBox(width: 16),
        //     OutlinedButton.icon(
        //       label: const Icon(Icons.fullscreen, size: 20),
        //       onPressed: _showFullScreen,
        //     ),
        //   ],
        // ),
      ],
    );
  }
}