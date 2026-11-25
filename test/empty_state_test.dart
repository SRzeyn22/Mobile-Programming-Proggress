import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/UAS/widgets/state_message.dart';

void main() {
  testWidgets('StateMessage menampilkan ilustrasi menggantikan ikon',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StateMessage(
            icon: Icons.favorite_border_rounded,
            illustration: SizedBox(key: Key('illustration'), width: 180),
            title: 'Belum ada negara favorit',
            message: 'Deskripsi',
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('illustration')), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    expect(find.text('Belum ada negara favorit'), findsOneWidget);
  });

  testWidgets('StateMessage tanpa ilustrasi tetap memakai ikon dan tidak overflow',
      (tester) async {
    tester.view.physicalSize = const Size(400, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StateMessage(
            icon: Icons.wifi_off_rounded,
            title: 'Judul',
            message: 'Pesan yang cukup panjang untuk layar pendek.',
            buttonText: 'Coba lagi',
            onPressed: null,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
