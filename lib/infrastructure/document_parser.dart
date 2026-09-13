import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as p;

class ParsedDocument {
  final String text;
  final String filename;
  final String extension;
  final String mimeType;
  final String checksum;
  final int size;
  final DateTime modifiedAt;

  const ParsedDocument({
    required this.text,
    required this.filename,
    required this.extension,
    required this.mimeType,
    required this.checksum,
    required this.size,
    required this.modifiedAt,
  });
}

class DocumentParser {
  Future<String> extract(String path) async => (await inspect(path)).text;

  Future<ParsedDocument> inspect(String path) async {
    final file = File(path);
    final stat = await file.stat();
    if (stat.size > 20 * 1024 * 1024) {
      throw const FormatException('Choose a document smaller than 20 MB.');
    }
    final bytes = await file.readAsBytes();
    final extension = p.extension(path).toLowerCase();
    String text;
    if (['.txt', '.md', '.markdown'].contains(extension)) {
      text = utf8.decode(bytes);
    } else if (extension == '.pdf') {
      text = _extractPdfText(bytes);
    } else if (extension == '.docx') {
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      final document = archive.findFile('word/document.xml');
      if (document == null) {
        throw const FormatException('DOCX has no document body.');
      }
      if (document.size > 40 * 1024 * 1024) {
        throw const FormatException('Expanded document is too large.');
      }
      final xml = XmlDocument.parse(utf8.decode(document.content as List<int>));
      text = xml.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'p')
          .map(
            (paragraph) => paragraph.descendants
                .whereType<XmlElement>()
                .where((e) => e.name.local == 't')
                .map((e) => e.innerText)
                .join(),
          )
          .join('\n');
    } else {
      throw const FormatException(
        'Supported: TXT, Markdown, text-based PDF and DOCX. Convert legacy DOC to DOCX/TXT.',
      );
    }
    if (text.trim().isEmpty) {
      throw const FormatException(
        'No text found. Scanned documents require OCR.',
      );
    }
    return ParsedDocument(
      text: text,
      filename: p.basename(path),
      extension: extension,
      mimeType: switch (extension) {
        '.txt' => 'text/plain',
        '.md' || '.markdown' => 'text/markdown',
        '.pdf' => 'application/pdf',
        '.docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        _ => 'application/octet-stream',
      },
      checksum: _checksum(bytes),
      size: stat.size,
      modifiedAt: stat.modified,
    );
  }

  String _checksum(List<int> bytes) {
    var first = 0x811c9dc5;
    var second = 0x9e3779b9;
    for (final byte in bytes) {
      first = ((first ^ byte) * 0x01000193) & 0xffffffff;
      second = ((second ^ (byte + 31)) * 0x01000193) & 0xffffffff;
    }
    return '${first.toRadixString(16).padLeft(8, '0')}${second.toRadixString(16).padLeft(8, '0')}';
  }

  String _extractPdfText(List<int> bytes) {
    if (bytes.length < 5 || latin1.decode(bytes.take(5).toList()) != '%PDF-') {
      throw const FormatException('The selected file is not a valid PDF.');
    }
    final source = latin1.decode(bytes);
    final output = <String>[];
    var expandedBytes = 0;
    final streams = RegExp(
      r'stream\r?\n([\s\S]*?)\r?\nendstream',
    ).allMatches(source);
    for (final stream in streams) {
      List<int> content = latin1.encode(stream.group(1)!);
      final dictionaryStart = stream.start < 600 ? 0 : stream.start - 600;
      final dictionary = source.substring(dictionaryStart, stream.start);
      if (dictionary.contains('/FlateDecode')) {
        try {
          content = zlib.decode(content);
        } catch (_) {
          continue;
        }
      }
      expandedBytes += content.length;
      if (expandedBytes > 40 * 1024 * 1024) {
        throw const FormatException('Expanded PDF text is too large.');
      }
      final decoded = latin1.decode(content);
      for (final block in RegExp(r'BT([\s\S]*?)ET').allMatches(decoded)) {
        final body = block.group(1)!;
        final parts = <({int offset, String value})>[];
        for (final match in RegExp(r'\((?:\\.|[^\\)])*\)').allMatches(body)) {
          final value = _decodePdfLiteral(match.group(0)!);
          if (value.trim().isNotEmpty) {
            parts.add((offset: match.start, value: value));
          }
        }
        for (final match in RegExp(r'<([0-9A-Fa-f\s]+)>').allMatches(body)) {
          final value = _decodePdfHex(match.group(1)!);
          if (value.trim().isNotEmpty) {
            parts.add((offset: match.start, value: value));
          }
        }
        parts.sort((a, b) => a.offset.compareTo(b.offset));
        if (parts.isNotEmpty) {
          output.add(parts.map((part) => part.value).join(' '));
        }
      }
    }
    final text = output
        .join('\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    if (text.isEmpty) {
      throw const FormatException(
        'No extractable PDF text found. Scanned or custom-font PDFs require OCR or conversion to TXT/DOCX.',
      );
    }
    return text;
  }

  String _decodePdfLiteral(String token) {
    final source = token.substring(1, token.length - 1);
    final bytes = <int>[];
    for (var index = 0; index < source.length; index++) {
      final code = source.codeUnitAt(index);
      if (code != 0x5c || index + 1 >= source.length) {
        bytes.add(code & 0xff);
        continue;
      }
      final next = source.codeUnitAt(++index);
      const escaped = {
        0x6e: 0x0a,
        0x72: 0x0d,
        0x74: 0x09,
        0x62: 0x08,
        0x66: 0x0c,
      };
      final replacement = escaped[next];
      if (replacement != null) {
        bytes.add(replacement);
      } else if (next == 0x0d || next == 0x0a) {
        if (next == 0x0d &&
            index + 1 < source.length &&
            source.codeUnitAt(index + 1) == 0x0a) {
          index++;
        }
      } else if (next >= 0x30 && next <= 0x37) {
        var octal = String.fromCharCode(next);
        for (
          var count = 0;
          count < 2 &&
              index + 1 < source.length &&
              source.codeUnitAt(index + 1) >= 0x30 &&
              source.codeUnitAt(index + 1) <= 0x37;
          count++
        ) {
          octal += source[++index];
        }
        bytes.add(int.parse(octal, radix: 8) & 0xff);
      } else {
        bytes.add(next & 0xff);
      }
    }
    return _decodePdfBytes(bytes);
  }

  String _decodePdfHex(String value) {
    var compact = value.replaceAll(RegExp(r'\s+'), '');
    if (compact.length.isOdd) compact += '0';
    final bytes = <int>[
      for (var index = 0; index < compact.length; index += 2)
        int.parse(compact.substring(index, index + 2), radix: 16),
    ];
    return _decodePdfBytes(bytes);
  }

  String _decodePdfBytes(List<int> bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xfe && bytes[1] == 0xff) {
      final units = <int>[];
      for (var index = 2; index + 1 < bytes.length; index += 2) {
        units.add((bytes[index] << 8) | bytes[index + 1]);
      }
      return String.fromCharCodes(units);
    }
    return latin1.decode(bytes);
  }
}
