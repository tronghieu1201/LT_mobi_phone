import json
import math
from datetime import datetime
import sys

# Dữ liệu locations (tương tự Dart, với lat/lng)
locations_by_category = {
    'Bánh mì': [
        {'name': 'Bánh mì Má Hải', 'address': '792 XLHN, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8665, 'lng': 106.7900},
        {'name': 'BÁNH MÌ QUE RUBY', 'address': 'Số 1 đường 17 10, Quang Trung/29 đường Lê Văn Chí, Thủ Đức, Thành phố Hồ Chí Minh 71300, Việt Nam', 'lat': 10.8650, 'lng': 106.7850, 'phone': '0933626949'},
        {'name': 'Lò Bánh Mì Hà Nội', 'address': '72 Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8640, 'lng': 106.7840, 'phone': '0985980282'},
        {'name': 'Lò Bánh Mì Khánh Mập', 'address': '45 Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8635, 'lng': 106.7835, 'phone': '0974366846'},
    ],
    'Mì cay': [
        {'name': 'Mì cay Naga - Man Thiện', 'address': '30a Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8620, 'lng': 106.7820},
    ],
    'Cơm': [
        {'name': 'Cơm tấm Sài Gòn 918 Lão Trư', 'address': '918 Song Hành Xa Lộ Hà Nội, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh 71206, Việt Nam', 'lat': 10.8610, 'lng': 106.7810, 'phone': '0707210606'},
        {'name': 'MIN MIN - Cơm Gà & Ăn Vặt', 'address': '121A Đ. Tân Lập 2, P, Thủ Đức, Thành phố Hồ Chí Minh 72000, Việt Nam', 'lat': 10.8600, 'lng': 106.7800, 'phone': '0346507177'},
        {'name': 'Tiệm cơm nhà Phúc', 'address': '198 Man Thiện, Phường Tân Phú, Quận 9, Hồ Chí Minh, Việt Nam', 'lat': 10.8590, 'lng': 106.7790, 'phone': '0906032357'},
        {'name': 'Quán Cơm Trang Quận 9', 'address': '104 Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8580, 'lng': 106.7780, 'phone': '0937065322'},
        {'name': 'Quán Cơm Cô Thanh', 'address': 'H3 Man Thiện, Khu phố 1, Thủ Đức, Hồ Chí Minh, Việt Nam', 'lat': 10.8570, 'lng': 106.7770},
        {'name': 'Quán Cơm CamRanh 385', 'address': '45 Đ. Số 385, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8560, 'lng': 106.7760, 'phone': '0332255818'},
    ],
    'Nước mía': [
        {'name': 'Nước Mía Cô Hương', 'address': 'A200/23B Đ. Lê Văn Việt, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8550, 'lng': 106.7750, 'phone': '0908109817'},
    ],
    'Cafe': [
        {'name': 'Cont coffee', 'address': 'Song Hành Xa Lộ Hà Nội, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh 70000, Việt Nam', 'lat': 10.8540, 'lng': 106.7740},
        {'name': 'Synary Smart Coffee HUTECH Thủ Đức Campus', 'address': '396 XLHN, Phường Tân Phú, Thủ Đức, Hồ Chí Minh, Việt Nam', 'lat': 10.8530, 'lng': 106.7730},
        {'name': 'Synary Coffee - Hutech', 'address': '10/80c Song Hành Xa Lộ Hà Nội, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8520, 'lng': 106.7720},
        {'name': 'Phuc Long Coffee & Tea (Phúc Long Hutech Q.9)', 'address': '10/80c XLHN, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8510, 'lng': 106.7710, 'phone': '02871001968'},
        {'name': 'Highlands coffee HUTECH khu E', 'address': 'VQ4P+28C, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8500, 'lng': 106.7700},
    ],
    'Bún bò': [
        {'name': 'Bún bò gốc huế - mai đình', 'address': '62/15a, 62 Đ. Số 385, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8490, 'lng': 106.7690, 'phone': '0379539022'},
        {'name': 'Bún Bò Thắm', 'address': '73H Đ. Trương Văn Thành, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8480, 'lng': 106.7680, 'phone': '0867708791'},
        {'name': 'Bún bò cô Út', 'address': '88C Đ. Trương Văn Thành, Khu Phố 6, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8470, 'lng': 106.7670},
    ],
    'Trà sữa': [
        {'name': 'Gong Cha Thủ Đức', 'address': '123 Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8460, 'lng': 106.7660, 'phone': '0281234567'},
        {'name': 'The Alley', 'address': '456 Song Hành, Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8450, 'lng': 106.7650},
    ],
    'Sinh tố': [
        {'name': 'Sinh Tố Cô Ba', 'address': '789 Lê Văn Việt, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8440, 'lng': 106.7640},
    ],
}

# Đề xuất món dựa trên khung giờ
suggestions_by_time_slot = {
    'sáng': ['Bánh mì', 'Cafe', 'Nước mía'],
    'trưa': ['Cơm', 'Mì cay', 'Bún bò'],
    'tối': ['Trà sữa', 'Sinh tố', 'Cafe'],
}

def haversine_distance(lat1, lon1, lat2, lon2):
    """Tính khoảng cách Haversine (km)"""
    R = 6371.0  # Bán kính Trái Đất
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def detect_time_slot():
    """Detect khung giờ hiện tại"""
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
    """Generate recommendations"""
    if time_slot is None:
        time_slot = detect_time_slot()
    suggestions = suggestions_by_time_slot.get(time_slot, ['Bánh mì'])
    all_locs = []
    for category in suggestions:
        locations = locations_by_category.get(category, [])
        for loc in locations:
            loc_lat = loc.get('lat', 21.0278)
            loc_lng = loc.get('lng', 105.8342)
            distance = haversine_distance(lat, lng, loc_lat, loc_lng)
            loc_copy = loc.copy()
            loc_copy['category'] = category
            loc_copy['distance'] = round(distance, 1)
            all_locs.append(loc_copy)
    # Sort theo khoảng cách
    all_locs.sort(key=lambda x: x['distance'])
    return {
        'time_slot': time_slot,
        'current_time': datetime.now().strftime('%H:%M'),
        'recommendations': all_locs[:5]  # Top 5
    }

if __name__ == "__main__":
    # Ví dụ sử dụng: python realtime.py <lat> <lng>
    if len(sys.argv) != 3:
        print(json.dumps(generate_recommendations(21.0278, 105.8342)))  # Default Hà Nội
    else:
        lat = float(sys.argv[1])
        lng = float(sys.argv[2])
        result = generate_recommendations(lat, lng)
        print(json.dumps(result, ensure_ascii=False, indent=2))