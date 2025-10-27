import json
import math
from datetime import datetime
import sys
import requests
from firebase_admin import credentials, firestore
import firebase_admin

# Khởi tạo Firebase Admin (thay thế bằng path đến service account key của bạn)
if not firebase_admin._apps:
    cred = credentials.Certificate('path/to/your/serviceAccountKey.json')  # Thay bằng file key thật
    firebase_admin.initialize_app(cred)
db = firestore.client()

# Default position (HCM)
DEFAULT_LAT = 10.7769
DEFAULT_LNG = 106.7009

# API Key cho Google Geocoding (uncomment và thay key thật)
# GOOGLE_API_KEY = 'YOUR_GOOGLE_API_KEY'

# Đề xuất món dựa trên khung giờ (giữ nguyên)
suggestions_by_time_slot = {
    'sáng': ['Bánh mì', 'Cafe', 'Nước mía'],
    'trưa': ['Cơm sườn', 'Mì cay', 'Bún bò'],
    'tối': ['Trà sữa', 'Sinh tố', 'Cafe'],
    'khác': ['Bánh mì', 'Nước mía'],  # Fallback
}

def fetch_lat_lng(address):
    """Fetch lat/lng từ Google Geocoding API (fallback default nếu không có key)"""
    # Uncomment để dùng real API
    # url = f"https://maps.googleapis.com/maps/api/geocode/json?address={requests.utils.quote(address)}&key={GOOGLE_API_KEY}"
    # response = requests.get(url)
    # if response.status_code == 200:
    #     data = response.json()
    #     if data['results']:
    #         loc = data['results'][0]['geometry']['location']
    #         return loc['lat'], loc['lng']
    # Fallback: Trả về default
    return DEFAULT_LAT, DEFAULT_LNG

def haversine_distance(lat1, lon1, lat2, lon2):
    """Tính khoảng cách Haversine (km) - Giống Dart files"""
    R = 6371.0  # Bán kính Trái Đất
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def fetch_and_filter_locations(category, lat, lng):
    """Fetch locations từ Firestore theo category, geocode, filter <=5km, sort theo distance - Giống Dart files"""
    try:
        # Fetch từ Firestore
        locations_ref = db.collection('locations').where('category', '==', category)
        snapshot = locations_ref.get()
        
        all_locs = []
        for doc in snapshot:
            data = doc.to_dict()
            loc = {
                'id': doc.id,
                'name': data.get('name', ''),
                'address': data.get('address', ''),
                'phone': data.get('phone', ''),
                'category': data.get('category', ''),
                'distance': 0.0,
            }
            # Fetch lat/lng
            loc_lat, loc_lng = fetch_lat_lng(loc['address'])
            distance = haversine_distance(lat, lng, loc_lat, loc_lng)
            loc['distance'] = round(distance, 1)
            if distance <= 5.0:  # Filter 5km như Dart
                all_locs.append(loc)
        
        # Sort theo distance
        all_locs.sort(key=lambda x: x['distance'])
        return all_locs[:5]  # Top 5 như result.dart
    except Exception as e:
        print(f"Error fetching locations: {e}", file=sys.stderr)
        return []

def detect_time_slot():
    """Detect khung giờ hiện tại - Giống result.dart"""
    now = datetime.now()
    current_time = now.hour + now.minute / 60.0
    if 6.0 <= current_time <= 10.5:
        return 'sáng'
    elif 11.0 <= current_time <= 14.5:
        return 'trưa'
    elif 18.0 <= current_time <= 21.0:
        return 'tối'
    else:
        return 'khác'

def generate_recommendations(lat, lng, time_slot=None):
    """Generate recommendations - Tích hợp Firestore và filter 5km"""
    if time_slot is None:
        time_slot = detect_time_slot()
    
    # Lời chào hỏi dựa trên khung giờ
    greetings = {
        'sáng': 'Chào buổi sáng! Đây là các gợi ý đồ ăn sáng gần bạn trong 5km:',
        'trưa': 'Chào buổi trưa! Đây là các gợi ý đồ ăn trưa gần bạn trong 5km:',
        'tối': 'Chào buổi tối! Đây là các gợi ý đồ ăn tối gần bạn trong 5km:',
        'khác': 'Chào bạn! Đây là các gợi ý đồ ăn uống gần bạn trong 5km:'
    }
    greeting = greetings.get(time_slot, greetings['khác'])
    
    suggestions = suggestions_by_time_slot.get(time_slot, ['Bánh mì'])
    all_locs = []
    for category in suggestions:
        locs = fetch_and_filter_locations(category, lat, lng)
        for loc in locs:
            loc['category'] = category  # Đảm bảo có category
            all_locs.append(loc)
    
    # Sort toàn bộ theo distance
    all_locs.sort(key=lambda x: x['distance'])
    
    if not all_locs:
        return {
            'greeting': f'{greeting} Không tìm thấy quán nào trong 5km.',
            'time_slot': time_slot,
            'current_time': datetime.now().strftime('%H:%M'),
            'recommendations': []
        }
    
    return {
        'greeting': greeting,
        'time_slot': time_slot,
        'current_time': datetime.now().strftime('%H:%M'),
        'recommendations': all_locs[:5]  # Top 5 overall
    }

if __name__ == "__main__":
    # Sử dụng: python realtime.py <lat> <lng>
    if len(sys.argv) != 3:
        result = generate_recommendations(DEFAULT_LAT, DEFAULT_LNG)
    else:
        lat = float(sys.argv[1])
        lng = float(sys.argv[2])
        result = generate_recommendations(lat, lng)
    print(json.dumps(result, ensure_ascii=False, indent=2))