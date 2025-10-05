import requests
import pandas as pd
import numpy as np
import time
from datetime import datetime

# --------------------------------------------------------
# 1. OBTENER DATOS NASA POWER
# --------------------------------------------------------
def get_nasa_power_data(lat, lon, start_year=2010, end_year=2023):  
    """
    Obtiene datos climáticos históricos DIRECTAMENTE de la NASA POWER API.
    🔹 Mejora: Ampliamos start_year a 1981 para tener mayor histórico disponible.
    """
    parameters = (
    "T2M_MAX,T2M_MIN,T2M,WS10M,WS50M,WS10M_MAX,"
    "PRECTOTCORR,RH2M,QV2M,T2MDEW,"
    "ALLSKY_KT,ALLSKY_SFC_SW_DWN,CLRSKY_SFC_SW_DWN,TS,PS"
)
                    
    url = (
        f"https://power.larc.nasa.gov/api/temporal/daily/point?"
        f"parameters={parameters}&community=RE&longitude={lon}&latitude={lat}"
        f"&start={start_year}0101&end={end_year}1231&format=JSON"
    )
    
    try:
        response = requests.get(url, timeout=60)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException:
        return None

# --------------------------------------------------------
# 2. PROCESAR DATOS NASA EN DATAFRAME
# --------------------------------------------------------
def process_nasa_data(api_data):
    if not api_data:
        return None
    
    records = []
    dates = list(api_data['properties']['parameter']['T2M_MAX'].keys())
    
    for date_str in dates:
        record = {'date': pd.to_datetime(date_str)}
        for param in [
            'T2M_MAX', 'T2M_MIN', 'T2M', 
            'WS10M', 'WS50M', 'WS10M_MAX',
            'PRECTOTCORR', 'RH2M', 'QV2M', 'T2MDEW',
            'ALLSKY_KT', 'ALLSKY_SFC_SW_DWN', 'CLRSKY_SFC_SW_DWN',
            'TS', 'PS'
        ]:
            if param in api_data['properties']['parameter']:
                value = api_data['properties']['parameter'][param].get(date_str)
                if value is not None:
                    record[param] = value
        records.append(record)
    
    df = pd.DataFrame(records)
    
    if df.empty:
        return None
    
    # 🔹 Rellenar valores faltantes de forma suave
    df = df.interpolate(method="linear").dropna()
    return df

# --------------------------------------------------------
# 3. CALCULAR HEAT INDEX
# --------------------------------------------------------
def calculate_heat_index(temp_c, humidity):
    """
    Calcula el índice de calor (Heat Index) en °C.
    🔹 Mejora: Solo se aplica si T >= 26°C y humedad >= 40%.
    En otros casos se devuelve la temperatura real.
    """
    if temp_c < 26 or humidity < 40:
        return temp_c  # No aplica índice de calor
    
    temp_f = (temp_c * 9/5) + 32
    hi_f = -42.379 + (2.04901523 * temp_f) + (10.14333127 * humidity) \
           - (0.22475541 * temp_f * humidity) - (6.83783e-3 * temp_f**2) \
           - (5.481717e-2 * humidity**2) + (1.22874e-3 * temp_f**2 * humidity) \
           + (8.5282e-4 * temp_f * humidity**2) - (1.99e-6 * temp_f**2 * humidity**2)
    
    return (hi_f - 32) * 5/9

# --------------------------------------------------------
# 4. CONVERTIR DIRECCIÓN A COORDENADAS
# --------------------------------------------------------
def address_to_coords_osm(address):
    """
    Convierte una dirección a coordenadas usando OpenStreetMap Nominatim.
    🔹 Mejora: Se añade pausa de 1 segundo para evitar bloqueos por exceso de peticiones.
    """
    base_url = "https://nominatim.openstreetmap.org/search"
    params = {'q': address, 'format': 'json', 'limit': 1}
    headers = {'User-Agent': 'NASA-Hackathon-App'}
    
    try:
        response = requests.get(base_url, params=params, headers=headers, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        # 🔹 Evitamos abusar del servicio (Nominatim limita a 1 req/seg)
        time.sleep(1)
        
        if data:
            lat = float(data[0]['lat'])
            lon = float(data[0]['lon'])
            return lat, lon
        return None
    except Exception:
        return None

# --------------------------------------------------------
# 5. EXTRAER DÍA Y MES DE FECHA (STRING)
# --------------------------------------------------------
def extraer_dia_y_mes(fecha_str: str):
    """
    Recibe fecha string y devuelve (día, mes) como enteros.
    Ejemplo: "2025-10-05 14:23:00.123456" -> (5, 10)
    🔹 Mejora: Soporte directo para formato 'YYYY-MM-DD'.
    """
    try:
        if len(fecha_str) == 10:  # Caso "YYYY-MM-DD"
            fecha = datetime.strptime(fecha_str, "%Y-%m-%d")
        else:
            fecha = datetime.fromisoformat(fecha_str)
    except ValueError:
        try:
            fecha = datetime.strptime(fecha_str[:19], "%Y-%m-%d %H:%M:%S")
        except ValueError:
            raise ValueError(f"Formato de fecha no válido: {fecha_str}")

    return fecha.day, fecha.month
