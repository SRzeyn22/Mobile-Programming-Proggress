import 'package:flutter/material.dart';

import 'Modul-1/main.dart' as m0;

import 'Modul-2/Tugas/main.dart' as m1;

import 'Modul-3/Praktikum/main.dart' as m2;
import 'Modul-3/Tugas/main.dart' as m3;

import 'Modul-4/Praktikum/Percobaan-1/main.dart' as m5;
import 'Modul-4/Praktikum/Percobaan-2/main.dart' as m6;
import 'Modul-4/Tugas/main.dart' as m8;

import 'Modul-5/Praktikum/Percobaan-1/main.dart' as m9;
import 'Modul-5/Praktikum/Percobaan-2/main.dart' as m10;
import 'Modul-5/Praktikum/Percobaan-3/main.dart' as m11;
import 'Modul-5/Tugas/main.dart' as m12;

import 'Modul-6/Praktikum/Percobaan-1/main.dart' as m13;
import 'Modul-6/Praktikum/Percobaan-2/main.dart' as m14;
import 'Modul-6/Praktikum/Percobaan-3/main.dart' as m15;
import 'Modul-6/Praktikum/Percobaan-4/main.dart' as m16;
import 'Modul-6/Tugas/main.dart' as m18;

import 'Modul-7/Tugas/main.dart' as m19;

import 'Modul-8/Praktikum/main.dart' as m20;
import 'Modul-8/Tugas/main.dart' as m21;

import 'Modul-9/Praktikum/Percobaan-1/main.dart' as m22;
import 'Modul-9/Praktikum/Percobaan-2/main.dart' as m23;
import 'Modul-9/Tugas/tugas.dart' as m24;

import 'Modul-10%20(Game)/Praktikum/Percobaan-1/main.dart' as m25;
import 'Modul-10%20(Game)/Praktikum/Percobaan-2/main.dart' as m26;
import 'Modul-10%20(Game)/Tugas/main.dart' as m27;

import 'Modul-11/Tugas/main.dart' as m28;

import 'Modul-12/main.dart' as m29;
import 'Modul-13/main.dart' as m30;

import 'UTS/main.dart' as m31;
import 'UAS/main.dart' as m32;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tugas Flutter',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

// Membuka salah satu hasil modul.
// Tombol kembali berada di kiri bawah agar bisa kembali ke menu.
void _bukaModul(BuildContext context, Widget modul) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (context) => _ModulHost(modul: modul)));
}

class _ModulHost extends StatelessWidget {
  const _ModulHost({required this.modul});

  final Widget modul;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        modul,
        Positioned(
          left: 8,
          bottom: 8,
          child: SafeArea(
            child: Material(
              type: MaterialType.transparency,
              child: FloatingActionButton.small(
                heroTag: null,
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu Modul')),
      body: ListView(
        children: [
          // ================= MODUL 1 =================
          ExpansionTile(
            title: const Text('Modul 1'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ListTile(
                title: const Text('Praktikum'),
                onTap: () => _bukaModul(context, const m0.Modul1Page()),
              ),
            ],
          ),

          // ================= MODUL 2 =================
          ExpansionTile(
            title: const Text('Modul 2'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ListTile(
                title: const Text('Tugas'),
                onTap: () => _bukaModul(context, m1.MyApp()),
              ),
            ],
          ),

          // ================= MODUL 3 =================
          ExpansionTile(
            title: const Text('Modul 3'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ListTile(
                title: const Text('Praktikum'),
                onTap: () => _bukaModul(context, m2.MyApp()),
              ),
              ListTile(
                title: const Text('Tugas'),
                onTap: () => _bukaModul(context, m3.MyApp()),
              ),
            ],
          ),

          // ================= MODUL 4 =================
          ExpansionTile(
            title: const Text('Modul 4'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ExpansionTile(
                title: const Text('Praktikum'),
                childrenPadding: const EdgeInsets.only(left: 16),
                children: [
                  ListTile(
                    title: const Text('Percobaan-1'),
                    onTap: () => _bukaModul(context, m5.MyApp()),
                  ),
                  ListTile(
                    title: const Text('Percobaan-2'),
                    onTap: () => _bukaModul(context, m6.MyApp()),
                  ),
                ],
              ),
              ListTile(
                title: const Text('Tugas'),
                onTap: () => _bukaModul(context, m8.MyApp()),
              ),
            ],
          ),

          // ================= MODUL 5 =================
          ExpansionTile(
            title: const Text('Modul 5'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ExpansionTile(
                title: const Text('Praktikum'),
                childrenPadding: const EdgeInsets.only(left: 16),
                children: [
                  ListTile(
                    title: const Text('Percobaan-1'),
                    onTap: () => _bukaModul(context, m9.MyApp()),
                  ),
                  ListTile(
                    title: const Text('Percobaan-2'),
                    onTap: () => _bukaModul(context, m10.MyApp()),
                  ),
                  ListTile(
                    title: const Text('Percobaan-3'),
                    onTap: () => _bukaModul(context, m11.MyApp()),
                  ),
                ],
              ),
              ListTile(
                title: const Text('Tugas'),
                onTap: () => _bukaModul(context, m12.MyApp()),
              ),
            ],
          ),

          // ================= MODUL 6 =================
          ExpansionTile(
            title: const Text('Modul 6'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ExpansionTile(
                title: const Text('Praktikum'),
                childrenPadding: const EdgeInsets.only(left: 16),
                children: [
                  ListTile(
                    title: const Text('Percobaan-1'),
                    onTap: () => _bukaModul(context, m13.MyApp()),
                  ),
                  ListTile(
                    title: const Text('Percobaan-2'),
                    onTap: () => _bukaModul(context, m14.MyApp()),
                  ),
                  ListTile(
                    title: const Text('Percobaan-3'),
                    onTap: () => _bukaModul(context, m15.MyApp()),
                  ),
                  ListTile(
                    title: const Text('Percobaan-4'),
                    onTap: () => _bukaModul(context, m16.MyApp()),
                  ),
                ],
              ),
              ListTile(
                title: const Text('Tugas'),
                onTap: () => _bukaModul(context, m18.MyApp()),
              ),
            ],
          ),

          // ================= MODUL 7 =================
          ExpansionTile(
            title: const Text('Modul 7'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ListTile(
                title: const Text('Tugas'),
                onTap: () => _bukaModul(context, m19.MyApp()),
              ),
            ],
          ),

          // ================= MODUL 8 =================
          ExpansionTile(
            title: const Text('Modul 8'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ListTile(
                title: const Text('Praktikum'),
                onTap: () => _bukaModul(context, m20.MyApp()),
              ),
              ListTile(
                title: const Text('Tugas'),
                onTap: () => _bukaModul(context, m21.MyApp()),
              ),
            ],
          ),

          // ================= MODUL 9 =================
          ExpansionTile(
            title: const Text('Modul 9'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ExpansionTile(
                title: const Text('Praktikum'),
                childrenPadding: const EdgeInsets.only(left: 16),
                children: [
                  ListTile(
                    title: const Text('Percobaan-1'),
                    onTap: () => _bukaModul(context, m22.MyApp()),
                  ),
                  ListTile(
                    title: const Text('Percobaan-2'),
                    onTap: () => _bukaModul(context, m23.MyApp()),
                  ),
                ],
              ),
              ListTile(
                title: const Text('Tugas'),
                onTap: () => _bukaModul(context, m24.MyApp()),
              ),
            ],
          ),

          // ================= MODUL 10 =================
          ExpansionTile(
            title: const Text('Modul 10'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ExpansionTile(
                title: const Text('Praktikum'),
                childrenPadding: const EdgeInsets.only(left: 16),
                children: [
                  ListTile(
                    title: const Text('Percobaan-1'),
                    onTap: () => _bukaModul(context, m25.MyApp()),
                  ),
                  ListTile(
                    title: const Text('Percobaan-2'),
                    onTap: () => _bukaModul(context, m26.MyApp()),
                  ),
                ],
              ),
              ListTile(
                title: const Text('Tugas'),
                onTap: () => _bukaModul(context, m27.MyApp()),
              ),
            ],
          ),

          // ================= MODUL 11 =================
          ExpansionTile(
            title: const Text('Modul 11'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ListTile(
                title: const Text('Tugas'),
                onTap: () => _bukaModul(context, m28.MyApp()),
              ),
            ],
          ),

          // ================= MODUL 12 =================
          ExpansionTile(
            title: const Text('Modul 12'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ListTile(
                title: const Text('Praktikum'),
                onTap: () => _bukaModul(context, m29.MyApp()),
              ),
            ],
          ),

          // ================= MODUL 13 =================
          ExpansionTile(
            title: const Text('Modul 13'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ListTile(
                title: const Text('Praktikum'),
                onTap: () => _bukaModul(context, m30.MyApp()),
              ),
            ],
          ),

          // ================= UTS =================
          ExpansionTile(
            title: const Text('UTS'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ListTile(
                title: const Text('Country Explorer'),
                onTap: () => _bukaModul(context, m31.CountryExplorerApp()),
              ),
            ],
          ),

          // ================= UAS =================
          ExpansionTile(
            title: const Text('UAS'),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ListTile(
                title: const Text('Country Explorer'),
                onTap: () => _bukaModul(context, m32.CountryExplorerUasApp()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
