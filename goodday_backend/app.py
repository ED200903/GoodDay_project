from flask import Flask, jsonify
from clima_utils import (
    get_nasa_power_data, process_nasa_data, calculate_heat_index,
    address_to_coords_osm, extraer_dia_y_mes
)
import pandas as pd
import numpy as np

app = Flask(__name__)

@app.route("/clima/<lat>/<lon>/<fecha>", methods=["GET"])
def clima(lat, lon, fecha):
    try:
        # 1. Convertir parámetros
        lat = float(lat)
        lon = float(lon)
        dia, mes = extraer_dia_y_mes(fecha)

        # 2. Obtener datos NASA
        nasa_data = get_nasa_power_data(lat, lon)
        df = process_nasa_data(nasa_data)

        if df is None or df.empty:
            return jsonify({"error": "No se encontraron datos para esta ubicación"}), 404

        # 3. Calcular Heat Index para cada fila
        df["HEAT_INDEX"] = df.apply(
            lambda row: calculate_heat_index(row["T2M"], row["RH2M"]),
            axis=1
        )

        # 4. Filtrar solo las fechas del día/mes en todos los años
        target_days = []
        for year in range(1984, 2024):
            try:
                fecha_obj = pd.to_datetime(f"{year}-{mes:02d}-{dia:02d}")
                day_data = df[df["date"] == fecha_obj]
                if not day_data.empty:
                    target_days.append(day_data.iloc[0])
            except ValueError:
                continue

        if not target_days:
            return jsonify({"error": "No hay datos para esa fecha"}), 404

        target_df = pd.DataFrame(target_days)

        # 5. Calcular estadísticas generales
        stats = {
            "temp_max_promedio": np.mean(target_df["T2M_MAX"]),
            "temp_min_promedio": np.mean(target_df["T2M_MIN"]),
            "temp_promedio": np.mean(target_df["T2M"]),
            "viento_10m_promedio": np.mean(target_df["WS10M"]),
            "viento_50m_promedio": np.mean(target_df["WS50M"]),
            "viento_rafaga_max": np.max(target_df["WS10M_MAX"]),
            "dias_lluvia": int(np.sum(target_df["PRECTOTCORR"] > 1)),  # cuenta días con lluvia > 1mm
            "total_dias": int(len(target_df)),
            "heat_index_promedio": np.mean(target_df["HEAT_INDEX"]),
            "humedad_relativa_promedio": np.mean(target_df["RH2M"]),
            "humedad_absoluta_promedio": np.mean(target_df["QV2M"]),
            "rocío_promedio": np.mean(target_df["T2MDEW"]),
            "presion_superficie_promedio": np.mean(target_df["PS"]),
            "temperatura_suelo_promedio": np.mean(target_df["TS"]),
            "radiacion_solar": np.mean(target_df["ALLSKY_SFC_SW_DWN"]),
            "radiacion_solar_despejado": np.mean(target_df["CLRSKY_SFC_SW_DWN"]),
            "indice_claridad": np.mean(target_df["ALLSKY_KT"]),
        }
        
        
        # 6. Calcular condiciones extremas (textos simples pero basados en varias variables)
        condiciones = []
        if stats["temp_max_promedio"] > 32 and stats["humedad_relativa_promedio"] > 60:
            condiciones.append("🥵 Muy caluroso y húmedo")
        elif stats["temp_min_promedio"] < 5:
            condiciones.append("❄️ Muy frío")

        if stats["viento_rafaga_max"] > 15:
            condiciones.append("💨 Viento fuerte")

        if stats["dias_lluvia"] > (0.3 * stats["total_dias"]) and stats["indice_claridad"] < 0.4:
            condiciones.append("🌧️ Alta probabilidad de lluvia")

        if stats["heat_index_promedio"] > 32:
            condiciones.append("🔥 Sensación térmica incómoda")

        if stats["radiacion_solar"] > 800:
            condiciones.append("☀️ Radiación solar muy alta")
            
        # 7. Motor inferencial: predicciones (basadas en ≥3 variables)
        predicciones = []
        if (stats["dias_lluvia"]/stats["total_dias"] > 0.4 and 
            stats["humedad_relativa_promedio"] > 70 and 
            stats["indice_claridad"] < 0.5):
            predicciones.append("🌧️ Alta probabilidad de lluvia, día húmedo y nublado.")
        
        if (stats["indice_claridad"] > 0.6 and 
            stats["radiacion_solar"]/stats["radiacion_solar_despejado"] > 0.7 and 
            stats["dias_lluvia"]/stats["total_dias"] < 0.2):
            predicciones.append("☀️ Día mayormente soleado, buen momento para actividades al aire libre.")

        if (stats["temp_promedio"] > 25 and 
            stats["humedad_relativa_promedio"] > 65 and 
            stats["heat_index_promedio"] > stats["temp_promedio"] + 3):
            predicciones.append("🥵 Clima caluroso y húmedo, sensación de bochorno incómoda.")

        if (stats["temp_promedio"] < 15 and 
            stats["humedad_relativa_promedio"] > 70 and 
            stats["rocío_promedio"] > 5):
            predicciones.append("❄️ Día frío y húmedo, posible sensación de incomodidad.")

        if (stats["viento_10m_promedio"] > 4 and 
            stats["viento_rafaga_max"] > 8 and 
            stats["indice_claridad"] > 0.5):
            predicciones.append("💨 Día ventoso, precaución en exteriores.")

        if (stats["radiacion_solar"] > 6 and 
            stats["radiacion_solar_despejado"] > 6.5 and 
            stats["indice_claridad"] > 0.5):
            predicciones.append("🌞 Radiación solar alta, usa protector solar.")

        # 8. Devolver JSON
        return jsonify({
            "lat": lat,
            "lon": lon,
            "fecha_consulta": fecha,
            "estadisticas": stats,
            "condiciones_extremas": condiciones,
            "predicciones": predicciones
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
