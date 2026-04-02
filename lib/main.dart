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
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF81D4FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF81D4FA),
          foregroundColor: Colors.white,
          elevation: 0,
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
      });
    } else {
      setState(() {
        descrizione = "Errore nella ricerca";
        approfondimento = "";
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

  void stampaPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                titolo,
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(descrizione, style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.Text(
                "Approfondimento:",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
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
        child: _home(),
      ),
    );
  }

  // 🔵 HOME PRINCIPALE
  Widget _home() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 🔍 BARRA DI RICERCA
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
                  padding: const EdgeInsets.all(18),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // ⭐ CARD APPROFONDISCI GRANDE ⭐
          if (titolo.isNotEmpty) _cardApprofondisci(),

          const SizedBox(height: 30),

          // 📌 RICERCHE SALVATE
          if (ricercheSalvate.isNotEmpty) _ricercheSalvate(),

          const SizedBox(height: 20),

          // 🔗 GOOGLE / YOUTUBE / CHATGPT IN STILE “COSA POSSO FARE”
          _bottoniWeb(),

          const SizedBox(height: 25),

          // 📤 CONDIVIDI + PDF
          _bottoniFinali(),
        ],
      ),
    );
  }

  // 🔵 CARD APPROFONDISCI CON IMMAGINE
  Widget _cardApprofondisci() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (immagine.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                immagine,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            titolo,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8D6E63),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            descrizione + "\n\n" + approfondimento,
            style: const TextStyle(fontSize: 20, height: 1.5),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                final url =
                    "https://it.wikipedia.org/wiki/${Uri.encodeComponent(titolo)}";
                apriLink(url);
              },
              icon: const Icon(Icons.open_in_new, size: 30),
              label: const Text("Apri su Wikipedia",
                  style: TextStyle(fontSize: 22)),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
                backgroundColor: const Color(0xFF81D4FA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: salvaRicerca,
              icon: const Icon(Icons.save),
              label: const Text("Salva"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  titolo = "";
                  descrizione = "";
                  approfondimento = "";
                  immagine = "";
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text("Indietro"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB0BEC5),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔵 RICERCHE SALVATE
  Widget _ricercheSalvate() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ricercheSalvate.length,
      itemBuilder: (context, index) {
        final item = ricercheSalvate[index];
        return Dismissible(
          key: Key(item),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => setState(() => ricercheSalvate.removeAt(index)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              title: Text(item, style: const TextStyle(fontSize: 20)),
              onTap: () => cercaWikipedia(item),
            ),
          ),
        );
      },
    );
  }

  // 🔵 CARD STILE “COSA POSSO FARE”
  Widget _categoriaCard({
    required Color colore,
    required IconData icona,
    required String testo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colore,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icona, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              testo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔵 GOOGLE / YOUTUBE / CHATGPT IN STILE CARD
  Widget _bottoniWeb() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _categoriaCard(
          colore: const Color(0xFF42A5F5),
          icona: Icons.search,
          testo: "Google",
          onTap: () =>
              apriLink("https://www.google.com/search?q=${controller.text}"),
        ),
        _categoriaCard(
          colore: const Color(0xFFE53935),
          icona: Icons.video_library,
          testo: "YouTube",
          onTap: () => apriLink(
              "https://www.youtube.com/results?search_query=${controller.text}"),
        ),
        _categoriaCard(
          colore: const Color(0xFF43A047),
          icona: Icons.chat,
          testo: "ChatGPT",
          onTap: () => apriLink("https://chat.openai.com/"),
        ),
      ],
    );
  }

  // 🔵 BOTTONI FINALI
  Widget _bottoniFinali() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: condividi,
          icon: const Icon(Icons.share),
          label: const Text("Condividi"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
        ElevatedButton.icon(
          onPressed: stampaPDF,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text("Stampa PDF"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ],
    );
  }
}
