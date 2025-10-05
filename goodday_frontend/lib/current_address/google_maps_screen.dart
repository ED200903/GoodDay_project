import 'package:flutter/material.dart';
import 'package:maps_google_v2/api_services/api_services.dart';
import 'package:maps_google_v2/clima_result.dart';

class GoogleMapsScreen extends StatefulWidget {
  final double lat, lng;
  const GoogleMapsScreen({super.key, required this.lat, required this.lng});

  @override
  State<GoogleMapsScreen> createState() => _GoogleMapsScreenState();
}

class _GoogleMapsScreenState extends State<GoogleMapsScreen> {
  bool isLoading = true;
  Map<String, dynamic>? clima;
  String? fechaSeleccionada;
  List<Map<String, String>> fechasDisponibles = [];

  @override
  void initState() {
    super.initState();
    fechasDisponibles = generarFechas();
    fechaSeleccionada = fechasDisponibles.first['fecha'];
    obtenerClimaDesdeAPI();
  }

  /// 🔹 Genera 7 días (hoy + 6 días)
  List<Map<String, String>> generarFechas() {
    final hoy = DateTime.now();
    const diasSemana = [
      "Lun",
      "Mar",
      "Mié",
      "Jue",
      "Vie",
      "Sáb",
      "Dom"
    ];

    return List.generate(7, (i) {
      final fecha = hoy.add(Duration(days: i));
      final fechaApi =
          "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
      final diaStr = diasSemana[fecha.weekday - 1];
      final numeroDia = fecha.day.toString();
      return {
        "fecha": fechaApi, // para API
        "dia": diaStr,
        "numero": numeroDia,
      };
    });
  }

  Future<void> obtenerClimaDesdeAPI() async {
    if (fechaSeleccionada == null) return;
    try {
      setState(() => isLoading = true);

      final data = await ApiServices().obtenerClima(
        widget.lat,
        widget.lng,
        fechaSeleccionada!,
      );

      setState(() {
        clima = data;
        isLoading = false;
      });
      print("✅ Clima recibido: $data");
    } catch (e) {
      print("❌ Error al obtener clima: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text("Clima desde API Flask"),
      ),
      body: Column(
        children: [
          // 🔹 Selector de días en horizontal
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: fechasDisponibles.map((f) {
                  final isSelected = fechaSeleccionada == f['fecha'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        fechaSeleccionada = f['fecha'];
                      });
                      obtenerClimaDesdeAPI();
                    },
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blueAccent : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            f['numero']!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            f['dia']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(),
          // 🔹 Resultado clima
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : clima == null
                    ? const Center(child: Text("No se pudo obtener el clima"))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ClimaResult(data: clima!),
                      ),
          ),
        ],
      ),
    );
  }
}
