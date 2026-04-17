import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqflite/sqflite.dart';

/// Serves vector tiles from a bundled mbtiles file over `127.0.0.1:<port>`.
///
/// mbtiles uses TMS y-axis, so rows are flipped from the XYZ scheme that
/// maplibre_gl asks for. Tile bodies are stored gzip-compressed; we pass
/// them through as-is with `Content-Encoding: gzip`.
class TileServer {
  TileServer._();
  static final TileServer instance = TileServer._();

  HttpServer? _server;
  Database? _mbtiles;
  int? _port;

  int get port => _port ?? 0;
  bool get isRunning => _server != null;

  Future<int> start() async {
    if (_server != null) return _port!;

    final docs = await getApplicationDocumentsDirectory();
    final mbtilesPath = p.join(docs.path, 'sofia.mbtiles');
    final mbtilesFile = File(mbtilesPath);
    if (!await mbtilesFile.exists()) {
      final bytes = await rootBundle.load('assets/sofia.mbtiles');
      await mbtilesFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }

    _mbtiles = await openReadOnlyDatabase(mbtilesPath);

    final router = Router()
      ..get('/tiles/<z>/<x>/<y>.pbf', _serveTile);

    _server = await shelf_io.serve(
      const Pipeline().addHandler(router.call),
      InternetAddress.loopbackIPv4,
      0,
    );
    _port = _server!.port;
    return _port!;
  }

  Future<Response> _serveTile(Request req, String z, String x, String y) async {
    final zi = int.tryParse(z);
    final xi = int.tryParse(x);
    final yi = int.tryParse(y);
    if (zi == null || xi == null || yi == null) {
      return Response.badRequest();
    }
    // XYZ → TMS flip.
    final tmsY = (1 << zi) - 1 - yi;
    final rows = await _mbtiles!.query(
      'tiles',
      columns: ['tile_data'],
      where: 'zoom_level = ? AND tile_column = ? AND tile_row = ?',
      whereArgs: [zi, xi, tmsY],
      limit: 1,
    );
    if (rows.isEmpty) return Response.notFound('no tile');
    final blob = rows.first['tile_data'] as Uint8List;
    return Response.ok(
      blob,
      headers: {
        'Content-Type': 'application/x-protobuf',
        'Content-Encoding': 'gzip',
        'Access-Control-Allow-Origin': '*',
      },
    );
  }

  /// Starts the server (if needed) and writes the runtime style file with
  /// `{PORT}` substituted. Returns the on-disk path to the style JSON.
  Future<String> prepareStyle() async {
    final port = await start();
    final docs = await getApplicationDocumentsDirectory();
    final stylePath = p.join(docs.path, 'style_sofia.runtime.json');
    final src = await rootBundle.loadString('assets/style/style_sofia.json');
    final rewritten = src
        .replaceAll('{PORT}', '$port')
        .replaceAll('{DOCS}', Uri.file(docs.path).toString());
    await File(stylePath).writeAsString(rewritten);
    return stylePath;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    await _mbtiles?.close();
    _server = null;
    _mbtiles = null;
    _port = null;
  }
}
