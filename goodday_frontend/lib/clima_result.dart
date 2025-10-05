import 'package:flutter/material.dart';

class ClimaResult extends StatelessWidget {
  final Map<String, dynamic> data;
  const ClimaResult({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final estadisticas = data["estadisticas"];
    final condiciones = data["condiciones_extremas"] ?? [];
    final predicciones = data["predicciones"] ?? [];

    Widget climaCard(String emoji, String label, String value) {
      return Expanded(
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📊 Resumen del clima",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // 🔹 Fila 1: temperaturas
          Row(
            children: [
              climaCard("🌡️", "Temp. máx", "${estadisticas["temp_max_promedio"]?.toStringAsFixed(1)} °C"),
              climaCard("❄️", "Temp. mín", "${estadisticas["temp_min_promedio"]?.toStringAsFixed(1)} °C"),
              climaCard("🌤️", "Promedio", "${estadisticas["temp_promedio"]?.toStringAsFixed(1)} °C"),
            ],
          ),

          // 🔹 Fila 2: viento y lluvia
          Row(
            children: [
              climaCard("💨", "Viento 10m", "${estadisticas["viento_10m_promedio"]?.toStringAsFixed(1)} m/s"),
              climaCard("💨", "Ráfaga máx", "${estadisticas["viento_rafaga_max"]?.toStringAsFixed(1)} m/s"),
              climaCard("💧", "Días lluvia", "${estadisticas["dias_lluvia"]}/${estadisticas["total_dias"]}"),
            ],
          ),

          // 🔹 Fila 3: humedad y radiación
          Row(
            children: [
              climaCard("💦", "Humedad", "${estadisticas["humedad_relativa_promedio"]?.toStringAsFixed(1)}%"),
              climaCard("🔥", "Heat Index", "${estadisticas["heat_index_promedio"]?.toStringAsFixed(1)} °C"),
              climaCard("☀️", "Radiación", "${estadisticas["radiacion_solar"]?.toStringAsFixed(1)}"),
            ],
          ),

          const SizedBox(height: 20),

          // 🔹 Condiciones extremas
          if (condiciones.isNotEmpty) ...[
            const Text(
              "⚠️ Condiciones extremas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: condiciones
                  .map<Widget>(
                    (c) => Chip(
                      avatar: const Icon(Icons.warning, color: Colors.red),
                      label: Text(c),
                      backgroundColor: Colors.red[50],
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],

          // 🔹 Predicciones (comentarios inferenciales)
          if (predicciones.isNotEmpty) ...[
            const Text(
              "🤖 Predicciones para este día",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: predicciones.map<Widget>((p) {
                return Card(
                  color: Colors.blue[50],
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.insights, color: Colors.blueAccent),
                    title: Text(
                      p,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
