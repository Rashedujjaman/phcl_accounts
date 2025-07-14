import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

class AttachmentViewer extends StatefulWidget {
  final String url;
  final String fileName;

  const AttachmentViewer({super.key, required this.url, required this.fileName});

  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  bool _isPdf = false;
  bool _isDownloading = false;
  PdfControllerPinch? _pdfController;
  Uint8List? _pdfData;

  @override
  void initState() {
    super.initState();
    _isPdf = widget.url.toLowerCase().endsWith('.pdf');
    if (_isPdf){
      _initializePdfController();
    }
  }

  Future<void> _initializePdfController() async {
    try {
      if (_isPdf) {
        // Download PDF data first
        final response = await Dio().get(
          widget.url,
          options: Options(responseType: ResponseType.bytes),
        );
        
        _pdfData = Uint8List.fromList(response.data);
        
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openData(_pdfData!),
        );
        
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('PDF initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load PDF: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _downloadAndOpenFile() async {
    if (!mounted) return;
    
    setState(() => _isDownloading = true);
    
    try {
      if (kIsWeb) {
        await _handleWebUrl(widget.url);
      } else {
        await compute(_downloadAndOpenFileInIsolate, {
          'url': widget.url,
          'fileName': widget.fileName,
          'isPdf': _isPdf,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  static Future<void> _downloadAndOpenFileInIsolate(Map<String, dynamic> params) async {
    final url = params['url'] as String;
    final fileName = params['fileName'] as String?;
    final isPdf = params['isPdf'] as bool;

    if (url.startsWith('http')) {
      final tempDir = await getTemporaryDirectory();
      final fileExtension = isPdf ? '.pdf' : '.jpg';
      final filePath = '${tempDir.path}/${fileName ?? 'attachment${DateTime.now().millisecondsSinceEpoch}'}$fileExtension';
      
      final response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      
      final file = File(filePath);
      await file.writeAsBytes(response.data);
      
      await OpenFilex.open(filePath);
    } else {
      final ByteData data = await rootBundle.load(url);
      final Uint8List bytes = data.buffer.asUint8List();
      final path = await FileSaver.instance.saveFile(
        name: fileName ?? 'attachment_${DateTime.now().toIso8601String()}',
        bytes: bytes,
        fileExtension: isPdf ? 'pdf' : 'jpg',
        mimeType: isPdf ? MimeType.pdf : MimeType.jpeg,
      );
      await OpenFilex.open(path);
    }
  }

  Future<void> _handleWebUrl(String url) async {
    try {
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      throw Exception('URL launch failed: $e');
    }
  }

  void _showFullScreen() {
    if (_isPdf && _pdfController == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          // appBar: AppBar(
          //   title: Text(widget.fileName),
          //   actions: [
          //     IconButton(
          //       icon: const Icon(Icons.download),
          //       onPressed: _downloadAndOpenFile,
          //     ),
          //   ],
          // ),
          body: _isPdf
              ? PdfViewPinch(
                  controller: _pdfController!,
                  // controller: PdfControllerPinch(
                  //   document: PdfDocument.openData(
                  //     NetworkAssetBundle(
                  //       Uri.parse(widget.url))
                  //       .load(widget.url)
                  //       .then((data) => data.buffer.asUint8List()
                  //     ),
                  //   ),
                  // ),
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
      children: [
        GestureDetector(
          onTap: _showFullScreen,
          child:  _isPdf
                  ? (_pdfController != null 
                    ? PdfViewPinch(controller: _pdfController!) 
                    : const Center(child: CircularProgressIndicator()))
                // ? const Column(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                //       SizedBox(height: 8),
                //       Text('PDF Document'),
                //     ],
                //   )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    width: 100,
                    imageUrl: widget.url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                  ),
          ),
  
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              label: _isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 20),
              onPressed: _downloadAndOpenFile,
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              label: const Icon(Icons.fullscreen, size: 20),
              onPressed: _showFullScreen,
            ),
          ],
        ),
      ],
    );
  }
}