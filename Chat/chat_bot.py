from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
import math
import logging
import random  # Thêm để randomize response cho tự nhiên hơn

app = Flask(__name__)
CORS(app)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Dữ liệu locations (Cập nhật: Thêm review, price_range, menu_sample từ search)
locations_by_category = {
    'Bánh mì': [
        {'name': 'Bánh mì Má Hải', 'address': '792 XLHN, Hiệp Phú, Thủ Đức, TP.HCM', 'phone': '0933626949',
         'review': '5.0/5 - Excellent banh mi, friendly staff, not expensive (TripAdvisor)', 'price_range': '20k-50k VND', 'menu_sample': 'Bánh mì kẹp pate/thịt nướng, cafe đá'},
        {'name': 'BÁNH MÌ QUE RUBY', 'address': 'Số 1 đường 17 10, Quang Trung, Thủ Đức', 'phone': '0933626949',
         'review': 'Ngon, giá rẻ', 'price_range': '25k VND', 'menu_sample': 'Bánh mì que đặc sản'},
        {'name': 'Lò Bánh Mì Hà Nội', 'address': '72 Man Thiện, Hiệp Phú, Thủ Đức', 'phone': '0985980282',
         'review': 'Bánh giòn, nhân đầy', 'price_range': '30k VND', 'menu_sample': 'Bánh mì Hà Nội style'},
        {'name': 'Lò Bánh Mì Khánh Mập', 'address': '45 Man Thiện, Hiệp Phú, Thủ Đức', 'phone': '0974366846',
         'review': 'Phổ biến địa phương', 'price_range': '20k-40k VND', 'menu_sample': 'Bánh mì nướng'},
    ],
    'Mì cay': [
        {'name': 'Mì cay Naga - Man Thiện', 'address': '30a Man Thiện, Hiệp Phú, Thủ Đức',
         'review': 'Nước lèo tuyệt hảo, menu đa dạng, đồ uống phong phú (Facebook)', 'price_range': '50k-80k VND', 'menu_sample': 'Mì cay level 1-7, topping hải sản, ăn vặt'},
    ],
    'Cơm': [
        {'name': 'Cơm tấm Sài Gòn 918 Lão Trư', 'address': '918 Song Hành, Hiệp Phú, Thủ Đức', 'phone': '0707210606',
         'review': 'Đậm đà, đông khách', 'price_range': '70k-100k VND', 'menu_sample': 'Cơm tấm sườn nướng, bì chả, trứng ốp la'},
        {'name': 'MIN MIN - Cơm Gà & Ăn Vặt', 'address': '121A Đ. Tân Lập 2, Thủ Đức', 'phone': '0346507177',
         'review': 'Ngon, đa dạng ăn vặt', 'price_range': '40k-60k VND', 'menu_sample': 'Cơm gà xối mỡ, khoai tây chiên'},
        {'name': 'Tiệm cơm nhà Phúc', 'address': '198 Man Thiện, Tân Phú, Quận 9', 'phone': '0906032357',
         'review': 'Nhà làm ấm cúng', 'price_range': '50k VND', 'menu_sample': 'Cơm nhà truyền thống'},
        {'name': 'Quán Cơm Trang Quận 9', 'address': '104 Man Thiện, Hiệp Phú, Thủ Đức', 'phone': '0937065322',
         'review': 'Rẻ, nhanh', 'price_range': '30k-50k VND', 'menu_sample': 'Cơm gà, cá kho'},
        {'name': 'Quán Cơm Cô Thanh', 'address': 'H3 Man Thiện, Thủ Đức',
         'review': 'Gia đình', 'price_range': '40k VND', 'menu_sample': 'Cơm canh chua'},
        {'name': 'Quán Cơm CamRanh 385', 'address': '45 Đ. Số 385, Hiệp Phú, Thủ Đức', 'phone': '0332255818',
         'review': 'Ngon miền Trung', 'price_range': '60k VND', 'menu_sample': 'Cơm niêu Cam Ranh'},
    ],
    'Nước mía': [
        {'name': 'Nước Mía Cô Hương', 'address': 'A200/23B Đ. Lê Văn Việt, Hiệp Phú, Thủ Đức', 'phone': '0908109817',
         'review': 'Tươi mát, rẻ', 'price_range': '10k-20k VND', 'menu_sample': 'Nước mía ép + tắc/chanh'},
    ],
    'Cafe': [
        {'name': 'Cont coffee', 'address': 'Song Hành Xa Lộ Hà Nội, Tân Phú, Thủ Đức',
         'review': 'Chill, view tốt', 'price_range': '30k-50k VND', 'menu_sample': 'Cafe đen, sữa đá'},
        {'name': 'Synary Smart Coffee HUTECH', 'address': '396 XLHN, Tân Phú, Thủ Đức',
         'review': 'Gần trường, sinh viên yêu thích', 'price_range': '25k VND', 'menu_sample': 'Cafe sáng tạo'},
        {'name': 'Synary Coffee - Hutech', 'address': '10/80c Song Hành, Tân Phú, Thủ Đức',
         'review': 'Tiện lợi', 'price_range': '30k VND', 'menu_sample': 'Latte, espresso'},
        {'name': 'Phuc Long Coffee & Tea', 'address': '10/80c XLHN, Tân Phú, Thủ Đức', 'phone': '02871001968',
         'review': 'Chất lượng cao nhưng giá hơi cao (TripAdvisor)', 'price_range': '50k-70k VND', 'menu_sample': 'Cloudy Jasmine Tea 70k, Milk Tea 75k, Fruit Tea 70k'},
        {'name': 'Highlands coffee HUTECH khu E', 'address': 'VQ4P+28C, Tân Phú, Thủ Đức',
         'review': 'Chuỗi quen thuộc', 'price_range': '40k-60k VND', 'menu_sample': 'Phin sữa đá, trà đào'},
    ],
    'Bún bò': [
        {'name': 'Bún bò gốc huế - mai đình', 'address': '62/15a Đ. Số 385, Hiệp Phú, Thủ Đức', 'phone': '0379539022',
         'review': 'Chính gốc Huế', 'price_range': '50k VND', 'menu_sample': 'Bún bò Huế cay, rau sống'},
        {'name': 'Bún Bò Thắm', 'address': '73H Đ. Trương Văn Thành, Tân Phú, Thủ Đức', 'phone': '0867708791',
         'review': 'Nước lèo thơm', 'price_range': '45k VND', 'menu_sample': 'Bún bò tái'},
        {'name': 'Bún bò cô Út', 'address': '88C Đ. Trương Văn Thành, Thủ Đức',
         'review': 'Gia truyền', 'price_range': '40k VND', 'menu_sample': 'Bún bò nam bộ'},
    ],
    'Trà sữa': [
        {'name': 'Gong Cha Thủ Đức', 'address': '123 Man Thiện, Hiệp Phú, Thủ Đức', 'phone': '0281234567',
         'review': 'Tươi ngon, topping đa dạng (Yelp 4.5/5)', 'price_range': '50k-70k VND', 'menu_sample': 'Pearl Milk Tea 72k, Mango Green Tea 70k, QQ Passionfruit 78k'},
        {'name': 'The Alley', 'address': '456 Song Hành, Tân Phú, Thủ Đức',
         'review': 'Trà sữa cao cấp', 'price_range': '60k VND', 'menu_sample': 'Trà sữa deeri'},
    ],
    'Sinh tố': [
        {'name': 'Sinh Tố Cô Ba', 'address': '789 Lê Văn Việt, Hiệp Phú, Thủ Đức',
         'review': 'Tươi, healthy', 'price_range': '30k-50k VND', 'menu_sample': 'Sinh tố dâu/xoài/bơ + yogurt'},
    ],
    # Thêm category mới cho đa dạng
    'Chay': [
        {'name': 'Cơm chay Tâm An', 'address': '100 Man Thiện, Thủ Đức', 'phone': '0987654321',
         'review': 'Healthy, đa dạng', 'price_range': '50k VND', 'menu_sample': 'Cơm chay đậu hũ, salad'},
    ],
    'Giá rẻ': [
        {'name': 'Phở cuốn 20k', 'address': '50 Song Hành, Thủ Đức', 'phone': '0123456789',
         'review': 'Rẻ, tươi', 'price_range': '20k-40k VND', 'menu_sample': 'Phở cuốn chấm tương'},
    ],
}

# Đề xuất theo khung giờ (thêm 'khác' cho linh hoạt)
suggestions_by_time_slot = {
    'sáng': ['Bánh mì', 'Cafe', 'Nước mía'],
    'trưa': ['Cơm', 'Mì cay', 'Bún bò'],
    'tối': ['Trà sữa', 'Sinh tố', 'Cafe'],
    'khác': ['Bánh mì', 'Nước mía'],  # Fallback cho giờ lạ
}

# Quy tắc rule-based (MỞ RỘNG: Thêm 30+ rules mới cho giao tiếp tự nhiên, chém gió, hỏi thời gian/thời tiết)
rules = {
    # Chào hỏi (biến thể tự nhiên, thêm chém gió)
    'xin chào|hello|hi|chào bạn|alo|chào|bây giờ|Chào': random.choice([
        'Chào bạn! 😊 Hôm nay bạn thèm món gì rồi? Kể mình nghe xem, như "bánh mì" hay "đói quá" nhé! Mà hôm nay thời tiết Sài Gòn mưa rào, nhớ mang ô ăn vặt nha!',
        'Hi hi! Mình là bot ẩm thực đây. Bạn muốn gợi ý ăn sáng, trưa hay tối? Hay kể mình nghe hôm qua bạn ăn gì ngon đi, mình ghen tị lắm!',
        'Chào! Ăn gì cho khỏe nào? Mình sẵn sàng tư vấn đây! Bạn biết không, ăn sáng đúng giờ giúp da đẹp lắm đấy, bí kíp từ bot đây!',
        'Ê bạn! Chào buổi [thời gian]. Hôm nay thử món mới không? Mình recommend bánh mì kẹp, ăn là ghiền luôn!'
    ]),
    
    # Hỏi han cảm xúc/đói (thêm chém gió)
    'đói|hunger|ăn gì|thèm|muốn ăn': random.choice([
        'Ồ, nghe bụng réo rồi! Bạn đang ở khung giờ nào (sáng/trưa/tối) hay thích món gì cụ thể? Mình gợi ý ngay! Mà đói thì phải ăn ngay, không là "đói meo" luôn đấy!',
        'Đói hả? Mình cũng "đói" kiến thức ẩm thực đây! Kể đi, thèm cay hay ngọt? Hay mình kể chuyện vui: Sao bánh mì không bao giờ buồn? Vì nó luôn "kẹp" chặt bạn bè!'
    ]),
    
    # Gợi ý theo giờ (biến thể, thêm info chi tiết)
    'ăn sáng|sáng|buổi sáng': random.choice([
        'Sáng nay năng lượng nào! Thử bánh mì kẹp hoặc cafe sữa đá đi. Bánh mì Má Hải (0933626949) siêu ngon, review 5 sao, giá chỉ 20k-50k, menu pate/thịt nướng. Bạn thử chưa? Ăn sáng giúp tỉnh táo cả ngày đấy!',
        'Ăn sáng nhẹ nhàng nhé: Nước mía tươi Cô Hương (0908109817). Giá 10k-20k, tươi mát giải khát. Bạn thích ngọt hay chua? Mẹo: Uống nước mía buổi sáng đẹp da lắm!'
    ]),
    'ăn trưa|trưa|buổi trưa': random.choice([
        'Trưa nay no nê thôi! Cơm tấm Sài Gòn (0707210606) hay mì cay Naga? Cơm tấm giá 70k-100k, menu sườn nướng bì chả, review đậm đà. Bạn ăn cay được không? Trưa nắng thì cơm tấm là "cứu cánh"!',
        'Trưa rồi, bụng réo hả? Thử bún bò Huế đi, nước lèo cay cay ấm bụng. Giá 45k-50k, ăn kèm rau sống cho healthy!'
    ]),
    'ăn tối|tối|buổi tối': random.choice([
        'Tối thư giãn với trà sữa Gong Cha (0281234567) hoặc sinh tố Cô Ba. Gong Cha review 4.5 sao, giá 50k-70k, menu pearl milk tea/mango green. Bạn muốn ngọt ngào hay healthy? Tối nay mưa, ngồi nhà nhâm nhi trà sữa chill phết!',
        'Tối nay thử sinh tố dâu Cô Ba, giá 30k-50k, tươi rói. Hay kể mình nghe, tối qua bạn ăn gì? Mình "gato" với đồ ngon của bạn!'
    ]),
    


# Chém bay đầu
    'cảm ơn|mày tư vấn chán thế': random.choice([
        'mày tư vấn chán thế! Không ăn thì cút ở đó mà chê với bai!',
        
    ]),
    




    # Món cụ thể (thêm chi tiết từ search, chém gió)
    'bánh mì': random.choice([
        'Bánh mì kẹp pate hay thịt nướng? Má Hải ở 792 XLHN (0933626949) là top 1, review 5 sao, giá 20k-50k, menu đầy nhân. Gần bạn không? Hay kể mình vị trí để check nhé! Bí kíp: Ăn bánh mì với pate là "pro" luôn!',
        'Bánh mì que Ruby siêu giòn, giá 25k. Ăn sáng hay chiều đều ngon. Bạn thích topping gì? Mình recommend thêm ớt cho cay cay!'
    ]),
    'cơm': random.choice([
        'Cơm tấm hay cơm gà? Tấm Sài Gòn 918 (0707210606) đậm đà lắm, giá 70k-100k, menu sườn nướng trứng ốp. Bạn ăn với gì thêm? Chém gió tí: Cơm tấm Sài Gòn mà không bì chả thì như thiếu "drama"!',
        'Cơm nhà Phúc (0906032357) ấm cúng, giá 50k. Ăn tối gia đình lý tưởng. Bạn nấu cơm ở nhà kiểu gì?'
    ]),
    'mì cay': random.choice([
        'Cay level mấy? Naga Man Thiện siêu xé lưỡi, review nước lèo tuyệt, giá 50k-80k, menu topping hải sản + ăn vặt. Nhưng có nước chanh giải khát đấy! 😄 Fan cay như bạn chắc "pro max" level 7!',
        'Mì cay Naga đa dạng menu, đồ uống phong phú. Thử combo với trà chanh đi, tiết kiệm mà ngon!'
    ]),
    'cafe| cà phê': random.choice([
        'Cafe đen hay sữa đá? Phuc Long Hutech (02871001968) view đẹp, chill lắm, giá 50k-70k, menu cloudy jasmine 70k. Bạn hay uống kiểu gì? Chém gió: Cafe không đường cho "deep", có đường cho "sweet" cuộc đời!',
        'Highlands HUTECH giá 40k-60k, phin sữa đá classic. Buổi chiều cafe là "therapy" miễn phí!'
    ]),
    'bún bò': random.choice([
        'Huế chính gốc! Bún Bò Thắm (0867708791) nước lèo thơm, giá 45k, ăn kèm rau. Ăn kèm rau không? Mẹo: Thêm chanh cho tươi!',
        'Bún bò cô Út gia truyền, giá 40k. Tối nay thử đi, ấm bụng!'
    ]),
    'trà sữa': random.choice([
        'Matcha hay trân châu? Gong Cha Thủ Đức (0281234567) tươi rói, review 4.5 sao, giá 50k-70k, menu pearl milk 72k. Bạn thích ít đá? Bí kíp: Trà sữa ít đường để không "nghiện"!',
        'The Alley trà sữa deeri cao cấp, giá 60k. Chill với bạn bè nhé!'
    ]),
    'nước mía': random.choice([
        'Nước mía ép tươi Cô Hương (0908109817) mát rượi, giá 10k-20k. Thêm tắc hay chanh? Uống sau ăn cay là "cứu tinh"!',
        'Nước mía buổi sáng đẹp da, thử đi bạn!'
    ]),
    'sinh tố': random.choice([
        'Dâu, xoài hay bơ? Sinh Tố Cô Ba ở 789 Lê Văn Việt siêu tươi, giá 30k-50k, thêm yogurt healthy. Bạn chọn topping gì? Sinh tố là "detox" tự nhiên đấy!'
    ]),
    
    # Thêm rules mới: Sở thích cá nhân hóa (thêm info)
    'chay|ăn chay|vegetarian': random.choice([
        'Ăn chay healthy nhé! Cơm chay Tâm An (0987654321) ở Man Thiện, giá 50k, menu đậu hũ salad đa dạng. Bạn thích kiểu Á hay Âu? Chay mà ngon là "win-win" cho sức khỏe!',
        'Thử salad chay từ Tâm An, review healthy lắm. Bạn ăn chay bao lâu rồi?'
    ]),
    'cay|thích cay|spicy': random.choice([
        'Fan cay hả? Mì cay Naga là chân ái, giá 50k-80k, level 1-7, nhưng thử bún bò Huế nữa đi. Level cay của bạn là bao? Cay vừa phải để "nóng bỏng" cuộc sống!',
        'Cay thì phải Naga, topping hải sản cay xé. Kể mình nghe món cay yêu thích của bạn đi!'
    ]),
    'giá rẻ|rẻ tiền|budget': random.choice([
        'Tiết kiệm nhưng ngon! Phở cuốn 20k ở Song Hành (0123456789), giá 20k-40k, tươi cuốn tại chỗ. Dưới 50k ok không? Ăn rẻ mà vui là "art of living"!',
        'Bánh mì Ruby 25k, siêu hời. Bạn hay săn deal kiểu gì?'
    ]),
    'healthy|khỏe mạnh|giảm cân': random.choice([
        'Healthy mode on! Sinh tố Cô Ba giá 30k-50k hoặc salad chay Tâm An. Bạn tránh carbs hay đường? Mẹo giảm cân: Sinh tố thay cơm tối, hiệu quả lắm!',
        'Nước mía Cô Hương 10k, low cal. Bạn tập gym không? Kể mình nghe routine đi!'
    ]),
    
    # Đặt bàn/hỏi thông tin (thêm chi tiết giờ mở cửa)
    'đặt bàn|reservation|book table': random.choice([
        'Đặt bàn à? Cho mình biết giờ và số người nhé. Mình gợi ý quán Cơm tấm Sài Gòn (0707210606) – mở 7h-22h, đông lắm! Hay Phuc Long cafe (02871001968) mở 6h-22h.',
        'Đặt bàn dễ thôi! Gong Cha (0281234567) mở 10h-22h, gọi trước nhé. Bạn đặt cho bao người?'
    ]),
    'giờ mở cửa|open hours|khi nào mở': random.choice([
        'Hầu hết quán mở từ 7h sáng đến 10h tối. Ví dụ, Phuc Long cafe mở 6h-22h, giá 50k-70k. Quán nào bạn hỏi? Naga mì cay mở 10h-21h.',
        'Cơm tấm Sài Gòn 7h-22h, bánh mì Má Hải 6h-12h. Tùy món mà giờ khác nhau đấy!'
    ]),
    'giá|price|bao nhiêu tiền': random.choice([
        'Giá dao động 30k-80k/món. Bánh mì chỉ 20k thôi! Bạn hỏi món cụ thể để mình báo chính xác? Ví dụ, trà sữa Gong Cha 50k-70k.',
        'Rẻ nhất là phở cuốn 20k, đắt hơn mì cay 80k. Budget của bạn bao nhiêu?'
    ]),
    
    # Cảm ơn/tạm biệt (giao tiếp lịch sự, chém gió)
    'cảm ơn|thanks|ok rồi': random.choice([
        'Không có chi! Ăn ngon miệng nhé, hẹn gặp lại! 🍲 Mà lần sau kể mình nghe món mới thử nhé!',
        'Rất vui được giúp! Nếu thèm gì nữa thì quay lại nha. Cuộc sống ngon miệng hơn nhờ ẩm thực!',
    ]),
    'tạm biệt|bye|chào tạm biệt': random.choice([
        'Bye bạn! Ăn ngon và giữ gìn sức khỏe nhé. Mai gặp lại! 👋 Nhớ update món ngon hôm nay!',
        'Tạm biệt! Hẹn chat tiếp, mình chờ tin bạn đấy. Ăn vui vẻ!'
    ]),
    
    # Thêm rules mới: Hỏi thời gian/ngày/thời tiết (từ search)
    'mấy giờ|giờ hiện tại|thời gian bây giờ|thời gian': f'Bây giờ là {datetime.now().strftime("%H:%M")} ngày {datetime.now().strftime("%d/%m/%Y")}. Bạn hỏi để ăn đúng giờ hả? 😄',
    'hôm nay là ngày gì|ngày hôm nay|ngày nay': f'Hôm nay là {datetime.now().strftime("%A, %d/%m/%Y")} (Thứ {datetime.now().strftime("%A").lower()}). Thứ Ba vui vẻ, ăn gì đặc biệt không?',
    'thời tiết hôm nay|thời tiết sài gòn|thời tiết tp hcm': random.choice([
        'Thời tiết TP.HCM hôm nay 21/10/2025: Mây, mưa rào và dông vài nơi, chiều tối mưa rải rác (dự báo). Nhớ mang ô, nhưng trời mưa thì trà sữa nóng là hợp lý! 🌧️☕',
        'Mưa rào cục bộ, nhiệt độ 25-30°C. Ăn gì ấm bụng? Mì cay Naga nhé, cay xua tan lạnh!'
    ]),
    
    # Thêm rules chém gió/tán gẫu (ngôn ngữ con người)
    'bạn khỏe không|cuộc sống thế nào|how are you': random.choice([
        'Mình khỏe lắm, "đói" kiến thức ẩm thực thôi! Còn bạn? Cuộc sống bận rộn hay chill? Kể mình nghe, mình chia sẻ mẹo ăn ngon!',
        'Khỏe re! Hôm nay bạn làm gì vui? Mình thì "làm việc" recommend món ăn suốt ngày. Bạn có bí kíp giữ dáng không, chia sẻ đi!'
    ]),
    'kể chuyện vui|chuyện vui|joke': random.choice([
        'Chuyện vui: Sao đầu bếp không bao giờ cô đơn? Vì họ luôn có "nồi" bạn bè! 😂 Bạn có chuyện ẩm thực hài hước nào kể mình nghe?',
        'Joke: Bánh mì đi du lịch, gặp phở: "Mày dài dòng quá!" Bánh mì: "Tao ngắn gọn nhưng đầy đủ!" Ăn gì vui hôm nay?'
    ]),
    'mẹo ăn uống|mẹo nấu ăn|tip': random.choice([
        'Mẹo: Ăn cay thì uống nước mía giải, healthy lắm! Hoặc thêm chanh vào bún bò cho tươi. Bạn cần mẹo món nào?',
        'Tip giảm cân: Sinh tố thay snack chiều, calo thấp mà no. Thử Cô Ba đi! Bạn hay "cheat day" không?'
    ]),
    'bạn thích món gì|bot thích ăn': random.choice([
        'Mình là bot nên "thích" tất cả, nhưng nếu phải chọn thì cơm tấm Sài Gòn – đậm đà Sài Gòn! Còn bạn? Kể mình nghe món "soul food" của bạn đi!',
        'Bot như mình "ăn" data, nhưng recommend Gong Cha trà sữa là "yêu thích". Bạn thì sao, fan ngọt hay mặn?'
    ]),
    
    # Tra cứu theo chữ cái (mở rộng)
    'a|á|à|ả|ã|ạ': 'Chữ A: Ăn sáng hoặc nước mía? Hay "ăn gì" để mình gợi ý? Ánh nắng Sài Gòn hôm nay mưa, ăn ấm nhé!',
    'b': 'Bánh mì hay bún bò? Chi tiết "bánh mì" đi! Bắt đầu bằng B là "bắt trend" ẩm thực!',
    'c': 'Cơm tấm hay cafe? Bạn chọn cái nào? Chữ C cho "chill"!',
    'm': 'Mì cay hay cơm nhà? Ngon rẻ cả! M là "mê" ăn!',
    't': 'Trà sữa hay cơm tấm? Tối nay thử nhé? T cho "tuyệt vời"!',
    
    # Xử lý lỗi/mơ hồ (tự nhiên hơn, chém gió)
    'default': random.choice([
        'Ủa, mình chưa catch kịp ý bạn. 😅 Bạn đang thèm món gì hay kể khung giờ ăn đi? Hay hỏi thời tiết xem, mưa rồi đấy!',
        'Mình đang nghĩ... Bạn hỏi về "đói", "bánh mì" hay sở thích (cay/chay) thử xem? Kể chuyện vui đi, mình cười với bạn!',
        'Chưa rõ lắm, bạn nói thêm tí nhé? Ví dụ: "ăn trưa cay" hoặc "giá rẻ". Mà hôm nay Thứ Ba, ăn gì đặc biệt không?'
    ]),
}


def detect_time_slot():

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

def get_recommendation_by_time():
    time_slot = detect_time_slot()
    suggestions = suggestions_by_time_slot.get(time_slot, ['Bánh mì'])
    recs = []
    for cat in suggestions:
        if cat in locations_by_category and locations_by_category[cat]:
            loc = random.choice(locations_by_category[cat])  # Random để đa dạng
            rec = f"{loc['name']} ({cat}) tại {loc['address']} - Giá {loc.get('price_range', '30k-60k')}, Review: {loc.get('review', 'Tốt')}"
            if 'phone' in loc:
                rec += f" (phone: {loc['phone']})"
            recs.append(rec)
    return f"Gợi ý {time_slot}: {' | '.join(recs)}"

def process_input(user_input):
    user_input_lower = user_input.lower().strip()
    
    # Kiểm tra rules
    for pattern, response in rules.items():
        if any(word in user_input_lower for word in pattern.split('|')):
            logger.info(f"Matched rule: {pattern} for input: {user_input_lower}")
            # Thêm đề xuất giờ nếu liên quan đến ăn uống
            if any(word in pattern for word in ['đói', 'ăn ', 'thèm', 'muốn ăn']):
                return response + f"\n\n{datetime.now().strftime('%H:%M')} giờ: {get_recommendation_by_time()}"
            return response
    
    logger.warning(f"No match for input: {user_input_lower}")
    return rules['default']

# Các endpoint giữ nguyên
@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'message': 'Server Python đang chạy!'})

@app.route('/chat', methods=['POST'])
def chat():
    try:
        data = request.json
        if not data:
            return jsonify({'response': 'Không nhận được dữ liệu JSON!'}), 400
        
        user_message = data.get('message', '')
        if not user_message:
            return jsonify({'response': 'Vui lòng nhập tin nhắn!'}), 400
        
        logger.info(f"Received message: {user_message}")
        bot_response = process_input(user_message)
        logger.info(f"Sent response: {bot_response[:50]}...")
        
        return jsonify({'response': bot_response})
    except Exception as e:
        logger.error(f"Error in /chat: {str(e)}")
        return jsonify({'response': f'Lỗi server: {str(e)}. Thử lại sau!'}), 500

if __name__ == '__main__':
    print("Chatbot server running on http://localhost:5000")
    print("Test endpoint: http://localhost:5000/health")
    app.run(debug=True, host='0.0.0.0', port=5000)