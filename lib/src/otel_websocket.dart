// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_websocket_suppression.dart';

const _tracerName = 'dartastic_otel_libs_websocket';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a WebSocket handshake (`upgrade`) in a CLIENT span.
Future<T> tracedWebsocketConnect<T>({
  required String url,
  required Future<T> Function() invoke,
  String? subprotocol,
}) async {
  if (websocketInstrumentationSuppressed()) {
    return invoke();
  }
  final uri = Uri.tryParse(url);
  final m = <String, Object>{
    'url.full': url,
    'http.request.method': 'GET',
    'http.request.header.upgrade': 'websocket',
    'websocket.protocol': uri?.scheme == 'wss' ? 'wss' : 'ws',
  };
  if (subprotocol != null) m['websocket.subprotocol'] = subprotocol;
  if (uri != null && uri.host.isNotEmpty) {
    m['server.address'] = uri.host;
  }

  final span = _tracer().startSpan(
    'websocket connect',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps the outbound send of a single WebSocket frame in a
/// PRODUCER span. Use for high-fanout / billing-relevant frames;
/// for high-throughput streams sample or skip.
Future<T> tracedWebsocketSend<T>({
  required String destinationName,
  required Future<T> Function() invoke,
  int? payloadSize,
  String? opcode,
}) async {
  if (websocketInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'messaging.system': 'websocket',
    'messaging.operation': 'publish',
    'messaging.destination.name': destinationName,
  };
  if (payloadSize != null) m['messaging.message.body.size'] = payloadSize;
  if (opcode != null) m['websocket.opcode'] = opcode;

  final span = _tracer().startSpan(
    'websocket send $destinationName',
    kind: SpanKind.producer,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
