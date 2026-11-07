// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_websocket/otel_websocket.dart';

/// Traces Websocket calls with OpenTelemetry.
///
/// `otel_websocket` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Websocket call in
/// [tracedWebsocketConnect]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'websocket-example');

  // Wraps a WebSocket handshake (upgrade) in a CLIENT span.
  final websocketConnectId = await tracedWebsocketConnect<String>(
    url: 'https://api.example.com/v1/resource',
    subprotocol: 'example',
    invoke: () async {
      // Make the Websocket call here, then report what it returned.
      return 'websocket_8f3a2c';
    },
  );
  OTelLog.info('tracedWebsocketConnect returned $websocketConnectId');

  // Wraps the outbound send of a single WebSocket frame in a PRODUCER span.
  final websocketSendId = await tracedWebsocketSend<String>(
    destinationName: 'example',
    payloadSize: 512,
    opcode: 'example',
    invoke: () async {
      // Make the Websocket call here, then report what it returned.
      return 'websocket_8f3a2c';
    },
  );
  OTelLog.info('tracedWebsocketSend returned $websocketSendId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutWebsocketInstrumentationAsync.
  await runWithoutWebsocketInstrumentationAsync(
    () => tracedWebsocketConnect<String>(
      url: 'https://api.example.com/v1/resource',
      subprotocol: 'example',
      invoke: () async {
        return 'websocket_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
