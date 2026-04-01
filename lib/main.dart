import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const RiassumiApp());
}

class RiassumiApp extends StatelessWidget {
  const RiassumiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Riassumi8',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7EEDB),
        primaryColor: const Color(0xFF81D4FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF81D4FA),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF81D4FA),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController controller = TextEditingController();
  String titolo = "";
  String descrizione = "";
  String approfondimento = "";
  String immagine = "";
  final List<String> ricercheSalvate = [];
  bool showApprofondimento = false;

  Future<void> cercaWikipedia(String query) async {
    if (query.trim().isEmpty) return;

    final url =
        "https://it.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(query.toLowerCase())}";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        titolo = data['title'] ?? "";
        descrizione = data['extract'] ?? "Nessun riassunto trovato";
        immagine = data['thumbnail'] != null ? data['thumbnail']['source'] : "";
        approfondimento = data['description'] ??
            data['extract'] ??
            "Nessun approfondimento disponibile";
        showApprofondimento = true;
      });
    } else {
      setState(() {
        descrizione = "Errore nella ricerca";
        approfondimento = "";
        showApprofondimento = false;
      });
    }
  }

  void apriLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Errore apertura link';
    }
  }

  void salvaRicerca() {
    if (titolo.isNotEmpty && !ricercheSalvate.contains(titolo)) {
      setState(() {
        ricercheSalvate.add(titolo);
      });
    }
  }

  void vaiIndietro() {
    setState(() {
      showApprofondimento = false;
    });
  }

  // 📤 CONDIVIDI
  void condividi() {
    final link = "https://massimo12c.github.io/riassumi8/";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Condividi"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link));
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.copy),
                label: const Text("Copia link"),
              ),
              ElevatedButton.icon(
                onPressed: () => apriLink("https://wa.me/?text=$link"),
                icon: const Icon(Icons.chat),
                label: const Text("WhatsApp"),
              ),
              ElevatedButton.icon(
                onPressed: () => apriLink("https://t.me/share/url?url=$link"),
                icon: const Icon(Icons.send),
                label: const Text("Telegram"),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    apriLink("mailto:?subject=Riassumi8&body=$link"),
                icon: const Icon(Icons.email),
                label: const Text("Email"),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🖨️ STAMPA PDF
  void stampaPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(titolo,
                  style: pw.TextStyle(
                      fontSize: 28, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text(descrizione, style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.Text("Approfondimento:",
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(approfondimento, style: pw.TextStyle(fontSize: 16)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riassumi8"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: showApprofondimento
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      color: Colors.white,
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (immagine.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  immagine,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 15),
                            Text(
                              titolo,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8D6E63),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              descrizione,
                              textAlign: TextAlign.justify,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 15),
                            const Divider(),
                            const SizedBox(height: 10),
                            const Text(
                              "Approfondimento:",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              approfondimento,
                              textAlign: TextAlign.justify,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: salvaRicerca,
                              icon: const Icon(Icons.save),
                              label: const Text("Salva"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF81D4FA),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: vaiIndietro,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Indietro"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF81D4FA),
                      ),
                    )
                  ],
                ),
              )
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: "Scrivi un argomento...",
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onSubmitted: (_) => cercaWikipedia(controller.text),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => cercaWikipedia(controller.text),
                        child: const Icon(Icons.arrow_forward),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF81D4FA),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (ricercheSalvate.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Ricerche Salvate:",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: ricercheSalvate.length,
                              itemBuilder: (context, index) {
                                final item = ricercheSalvate[index];
                                return Dismissible(
                                  key: Key(item),
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) => setState(
                                      () => ricercheSalvate.removeAt(index)),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    color: Colors.white,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(20),
                                      title: Text(
                                        item,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      onTap: () => cercaWikipedia(item),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => apriLink(
                            "https://www.google.com/search?q=${controller.text}"),
                        icon: const Icon(Icons.search, size: 28),
                        label: const Text("Google",
                            style: TextStyle(fontSize: 20)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C6BC0),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => apriLink(
                            "https://www.youtube.com/results?search_query=${controller.text}"),
                        icon: const Icon(Icons.video_library, size: 28),
                        label: const Text("YouTube",
                            style: TextStyle(fontSize: 20)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE57373),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => apriLink("https://chat.openai.com/"),
                        icon: const Icon(Icons.chat, size: 28),
                        label: const Text("ChatGPT",
                            style: TextStyle(fontSize: 20)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF81C784),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: condividi,
                        icon: const Icon(Icons.share),
                        label: const Text("Condividi"),
                      ),
                      ElevatedButton.icon(
                        onPressed: stampaPDF,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("Stampa PDF"),
                      ),
                    ],
                  )
                ],
              ),
      ),
    );
  }
}
