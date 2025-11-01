import json
import math
from datetime import datetime
import sys

# Dữ liệu locations (chỉ liên quan đến đồ ăn uống)
locations_by_category = {
    'Bánh mì': [
        {'name': 'Lò Bánh Mì An Tiêm', 'address': 'VQC5+J4M, Lê Trọng Tấn, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0909992888'},
        {'name': 'Ba Dẹo - Bò Kho Bánh Mì - Hủ Tiếu Bò Kho', 'address': '10 Đ. Trần Thị Vững, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80},
        {'name': 'Tiệm Bánh Mì Hoàng Phúc', 'address': '9 Lê Trọng Tấn, An Bình, Thành Phố, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0399028979'},
        {'name': 'Bánh mỳ hà nội', 'address': '4b Bình Đường 3, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0971587844'},
        {'name': 'Lò Bánh Mì Hằng', 'address': '1242, Đường Kha Vạn Cân, Phường Linh Tây, Quận Thủ Đứ, Phường Linh Trung, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0909100868'},
        {'name': 'Bánh Mì', 'address': 'VQ97+89X, Phường Linh Trung, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0936979653'},
        {'name': 'Lò Bánh Mì Út Tâm', 'address': '1360 Đ. Kha Vạn Cân, Phường Linh Trung, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0966300142'},
    ],
    'Mì cay': [
        {'name': 'Mỳ cay nam hàn xuyên á', 'address': '125 QL1A, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0938525997'},
    ],
    'Cơm': [
        {'name': 'Cơm gà xối mỡ Bảo Như', 'address': '64 Đ. số 12, An Bình, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0902982950'},
        {'name': 'Tiệm Cơm Phát Ký', 'address': 'VQ94+4R4, Đào Trinh Nhất, Phường An Bình, Thị Xã Dĩ An, Tỉnh Bình Dương, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0373983727'},
        {'name': 'Cơm gà xối mỡ 455 chi nhánh 3', 'address': '129 Đ. Đào Trinh Nhất, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80},
        {'name': 'Quán Gà Ta Thanh Thư', 'address': '115 Đ. An Bình, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0368006162'},
        {'name': 'Quán Cơm Minh Hiếu', 'address': 'Bình Đường 2, Phường An Bình, Tỉnh Bình Dương, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0935099880'},
        {'name': 'Cơm Bầu Bí', 'address': 'h8 đường số 3, Bình Đường 2An Bình,Tx. Dĩ An, Bình, Đường Số 3, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0937303986'},
        {'name': 'Cơm tấm - Ngon tấm tắc 2', 'address': '53 Đ.Số 6, An Bình, Dĩ An, Bình Dương 70000, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0899159268'},
        {'name': 'Cơm bình dân Cô Liên', 'address': '71a Đ.Số 6, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0933686508'},
        {'name': 'Cơm Tấm CẬU ÚT', 'address': '10 Đường Số 2, p, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0338382721'},
        {'name': 'Cơm tấm - Ngon tấm tắc 1', 'address': '12/2 Đ. Trần Thị Vững, An Bình, Dĩ An, Bình Dương 70000, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0977068938'},
    ],
    'Nước mía': [
        {'name': 'Nước Mía Cốt Dừa', 'address': 'Linh Trung, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80},
    ],
    'Cafe': [
        {'name': 'Coffee & Billiard Cao Su', 'address': '82 Đ. số 12, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0909715219'},
        {'name': 'KIEN RAU coffee', 'address': '19 Đ. số 12, An Bình, Thủ Đức, Thành phố Hồ Chí Minh 70000, Việt Nam', 'lat': 10.90, 'lng': 106.80},
        {'name': 'HIM LAM Coffee', 'address': '14 Đ. Trần Thị Vững, An Bình, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80},
        {'name': 'Trầm Coffee&Food', 'address': 'Đường B, Trưng Trắc, Dĩ An, Bình Dương 75000, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0997997979'},
        {'name': 'Lâu Đài Phố - Castle Land Coffee', 'address': 'KDC Himlam Phú Đông, Đường D/Số 1 Đ. Trần Thị Vững, P, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80},
        {'name': 'Be You Coffee & Tea', 'address': 'đường số 1, Trần Thị Vững, phường Linh Tây, xã An Bình, Dĩ An tỉnh Bình Dương, Tỉnh Bình Dương, Bình Dương 590000, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0794109468'},
        {'name': 'Puppy Coffee', 'address': 'VQ83+WXR, KDC Himlam Phú Đông,Đường P, Đ. Trần Thị Vững, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80},
        {'name': 'RIO THE COFFEE', 'address': '02 Đường Số 1, Khu Dân Cư Him Lam, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0949812955'},
        {'name': 'Coffee Trường Hải', 'address': 'H33 TP, Đ. Số 5/H34 Đường 2, Khu Dân Cư Bình, Dĩ An, Bình Dương 75000, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0985055335'},
        {'name': 'Cafe 365', 'address': 'C4 Lê Trọng Tấn, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0962276828'},
        {'name': 'Cà phê sân vườn 1111', 'address': 'Bình/Đường 2/2 Bình Dương, An Bình, Dĩ An, Bình Dương 75000, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0777994136'},
    ],
    'Bún bò': [
        {'name': 'Bún bò Cô Hồng', 'address': '66 Đ. An Bình, Khu dân cư Him Lam Phú Đông, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80},
        {'name': 'Bún bò Cô Thu', 'address': '79 Hồ Tùng Mậu, Linh Tây, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80},
        {'name': 'Phở 1111', 'address': '82 Hồ Tùng Mậu, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0904289539'},
        {'name': 'Bún Bò Bà Ba chi nhánh Đào Trinh Nhất', 'address': 'giao với đường, 10a29 ( góc 2 mặt tiền ngã ba, 4 Đ. Đào Trinh Nhất, Linh Tây, Thủ Đức, Thành phố Hồ Chí Minh 71310, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0988178501'},
        {'name': 'Quán bún bò + bún riêu (lẩu bò)', 'address': '19 Đ. Đào Trinh Nhất, Linh Tây, Thủ Đức, Thành phố Hồ Chí Minh 70000, Việt Nam', 'lat': 10.90, 'lng': 106.80},
        {'name': 'Bún Bò Huế - Chả Vĩ Dạ', 'address': 'VQF6+35H, Dương Đình Nghệ, Phường Linh Trung, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80},
        {'name': 'Quán gà ta, bún bò Thủy Trinh', 'address': '1 Đ. Số 13, Linh Tây, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0978737094'},
        {'name': 'Bún Bò Phú Qúy', 'address': '979 Đ. Kha Vạn Cân, Linh Chiểu, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0976918702'},
        {'name': 'Quán bún bò Huế THIÊN OANH', 'address': '65 Đ. Đào Trinh Nhất, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0903659540'},
        {'name': 'Bún Bò Bà Năm', 'address': 'VQC4+V8Q, Chu Văn An, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0908646533'},
    ],
    'Trà sữa': [
        {'name': 'TRÀ SỮA MOON', 'address': '42 Đường số 4, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0918128578'},
        {'name': 'tiệm trà sữa 96', 'address': '42 Đ. Số 7, Bình Đường 2, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0379833184'},
        {'name': 'Trà Sữa Panda Moon An Bình', 'address': 'Đ. Số 5/24 Đường 2, khu phố bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0962378201'},
        {'name': 'Trà sữa Hello', 'address': 'VQC5+M78, Lê Trọng Tấn, An Bình, Dĩ An, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0984299075'},
        {'name': 'Trà Sữa AMI', 'address': '145a Lê Trọng Tấn, khu phố bình đường 2, Dĩ An, Bình Dương 75000, Việt Nam', 'lat': 10.90, 'lng': 106.80},
        {'name': 'Trà sữa Tí Hon', 'address': '62 đường Hồ Tùng Mậu, An Bình, Thủ Đức, Thành phố Hồ Chí Minh 700000, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0982372673'},
        {'name': 'AZA trà sữa và hơn thế nữa', 'address': '83 Đ. An Bình, An Bình, Dĩ An, Bình Dương 75300, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0913777535'},
        {'name': 'Trà sữa Vân Anh 2', 'address': '40 Đ. Đào Trinh Nhất, Linh Tây, Thủ Đức, Bình Dương, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0377332251'},
    ],
    'Sinh tố': [
        {'name': 'Sinh tố, nước ép Lem Juice', 'address': '62 Đ. số 12, An Bình, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0342776133'},
    ],
    'Nước ép': [
        {'name': 'SINH TỐ - NƯỚC ÉP TITO', 'address': '5 Đ. Hoàng Diệu 2, Phường Linh Trung, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0949389323'},
        {'name': 'Trang My Café Mang Về Sinh Tố - Nước Ép', 'address': 'An Bình, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80},
        {'name': 'Milano Coffee. Trà trái cây tươi, rau má, sinh tố, nước ép nguyên chất', 'address': '853 Đ. Kha Vạn Cân, Linh Chiểu, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0937985353'},
        {'name': 'ReViet Juice', 'address': '7 Số 1, Linh Xuân, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.90, 'lng': 106.80, 'phone': '0931855775'},
    ],
}

# Đề xuất món dựa trên khung giờ (chỉ đồ ăn uống)
suggestions_by_time_slot = {
    'sáng': ['Bánh mì', 'Cafe', 'Nước mía'],
    'trưa': ['Cơm', 'Mì cay', 'Bún bò'],
    'tối': ['Trà sữa', 'Sinh tố', 'Nước ép'],
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
    
    # Lời chào hỏi dựa trên khung giờ
    greetings = {
        'sáng': 'Chào buổi sáng! Đây là các gợi ý đồ ăn sáng gần bạn:',
        'trưa': 'Chào buổi trưa! Đây là các gợi ý đồ ăn trưa gần bạn:',
        'tối': 'Chào buổi tối! Đây là các gợi ý đồ ăn tối gần bạn:',
        'khác': 'Chào bạn! Đây là các gợi ý đồ ăn uống gần bạn:'
    }
    greeting = greetings.get(time_slot, greetings['khác'])
    
    suggestions = suggestions_by_time_slot.get(time_slot, ['Bánh mì'])
    all_locs = []
    for category in suggestions:
        locations = locations_by_category.get(category, [])
        for loc in locations:
            loc_lat = loc.get('lat', 10.90)
            loc_lng = loc.get('lng', 106.80)
            distance = haversine_distance(lat, lng, loc_lat, loc_lng)
            loc_copy = loc.copy()
            loc_copy['category'] = category
            loc_copy['distance'] = round(distance, 1)
            all_locs.append(loc_copy)
    # Sort theo khoảng cách
    all_locs.sort(key=lambda x: x['distance'])
    return {
        'greeting': greeting,
        'time_slot': time_slot,
        'current_time': datetime.now().strftime('%H:%M'),
        'recommendations': all_locs[:5]  # Top 5
    }

if __name__ == "__main__":
    # Sử dụng: python realtime.py <lat> <lng>
    if len(sys.argv) != 3:
        print(json.dumps(generate_recommendations(10.90, 106.80)))  # Default Dĩ An, Bình Dương
    else:
        lat = float(sys.argv[1])
        lng = float(sys.argv[2])
        result = generate_recommendations(lat, lng)
        print(json.dumps(result, ensure_ascii=False, indent=2))