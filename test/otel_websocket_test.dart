// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_websocket/otel_websocket.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_websocket-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('connect records CLIENT span', () async {
    await tracedWebsocketConnect<String>(
      url: 'wss://realtime.example.com/socket',
      subprotocol: 'phoenix',
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('websocket connect')!);
    expect(a['url.full'], 'wss://realtime.example.com/socket');
    expect(a['websocket.protocol'], 'wss');
    expect(a['websocket.subprotocol'], 'phoenix');
    expect(a['server.address'], 'realtime.example.com');
  });

  test('send records PRODUCER span', () async {
    await tracedWebsocketSend<String>(
      destinationName: 'orders.channel',
      payloadSize: 256,
      opcode: 'text',
      invoke: () async => 'sent',
    );
    final a = attrsOf(spans.findSpanByName('websocket send orders.channel')!);
    expect(a['messaging.system'], 'websocket');
    expect(a['websocket.opcode'], 'text');
    expect(a['messaging.message.body.size'], 256);
  });

  test('suppression skips spans', () async {
    await runWithoutWebsocketInstrumentationAsync(() async {
      await tracedWebsocketConnect<String>(
        url: 'wss://x/y',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('websocket '), isEmpty);
  });
}
