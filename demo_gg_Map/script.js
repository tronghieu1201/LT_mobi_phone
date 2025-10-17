// Lấy các phần tử
const toggleBtn = document.getElementById('toggleMapBtn');
const searchContainer = document.getElementById('search-container');
const addressInput = document.getElementById('address-input');
const searchAddressBtn = document.getElementById('searchAddressBtn');
const currentLocationBtn = document.getElementById('currentLocationBtn');
const mapContainer = document.getElementById('map-container');
const mapIframe = document.getElementById('map-iframe');
const errorMessage = document.getElementById('error-message');

let isSearchVisible = false;

// Hàm cập nhật bản đồ với URL
function updateMap(mapUrl) {
    mapIframe.src = mapUrl;
    mapContainer.style.display = 'block';
    searchContainer.style.display = 'none'; // Ẩn phần tìm kiếm sau khi hiển thị map
    toggleBtn.textContent = '🗺️ Xem Map';
    isSearchVisible = false;
}

// Hàm xử lý khi lấy vị trí thành công
function onLocationSuccess(position) {
    const lat = position.coords.latitude;
    const lng = position.coords.longitude;
    const mapUrl = `https://www.google.com/maps?q=${lat},${lng}&hl=vi&z=15&output=embed`;
    updateMap(mapUrl);
    currentLocationBtn.disabled = false;
    currentLocationBtn.textContent = '📍 Vị trí của bạn';
    errorMessage.style.display = 'none';
}

// Hàm xử lý khi lấy vị trí thất bại
function onLocationError(error) {
    let errorMsg = 'Không thể quét vị trí của bạn: ';
    switch (error.code) {
        case error.PERMISSION_DENIED:
            errorMsg += 'Bạn từ chối chia sẻ vị trí.';
            break;
        case error.POSITION_UNAVAILABLE:
            errorMsg += 'Thông tin vị trí không khả dụng.';
            break;
        case error.TIMEOUT:
            errorMsg += 'Yêu cầu quét vị trí hết thời gian.';
            break;
        default:
            errorMsg += 'Lỗi không xác định.';
            break;
    }
    errorMessage.textContent = errorMsg;
    errorMessage.style.display = 'block';
    currentLocationBtn.disabled = false;
    currentLocationBtn.textContent = '📍 Vị trí của bạn';
}

// Sự kiện cho nút toggle
toggleBtn.addEventListener('click', function() {
    if (searchContainer.style.display === 'none' && mapContainer.style.display === 'none') {
        searchContainer.style.display = 'block';
        toggleBtn.textContent = 'Ẩn Tìm Kiếm';
        isSearchVisible = true;
        mapContainer.style.display = 'none';
    } else if (isSearchVisible) {
        searchContainer.style.display = 'none';
        mapContainer.style.display = 'none';
        toggleBtn.textContent = '🗺️ Xem Map';
        isSearchVisible = false;
    } else {
        // Nếu map đang hiển thị, ẩn map và quay về toggle
        mapContainer.style.display = 'none';
        searchContainer.style.display = 'block';
        toggleBtn.textContent = 'Ẩn Tìm Kiếm';
        isSearchVisible = true;
    }
});

// Sự kiện cho nút tìm kiếm địa chỉ
searchAddressBtn.addEventListener('click', function() {
    const query = addressInput.value.trim();
    if (query) {
        const mapUrl = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(query)}&output=embed`;
        updateMap(mapUrl);
        addressInput.value = ''; // Xóa input sau khi tìm
    } else {
        errorMessage.textContent = 'Vui lòng nhập địa chỉ.';
        errorMessage.style.display = 'block';
    }
});

// Sự kiện cho nút vị trí hiện tại
currentLocationBtn.addEventListener('click', function() {
    if (navigator.geolocation) {
        currentLocationBtn.disabled = true;
        currentLocationBtn.textContent = 'Đang quét vị trí...';
        errorMessage.style.display = 'none';

        navigator.geolocation.getCurrentPosition(onLocationSuccess, onLocationError, {
            enableHighAccuracy: true,
            timeout: 10000,
            maximumAge: 60000
        });
    } else {
        errorMessage.textContent = 'Trình duyệt của bạn không hỗ trợ quét vị trí.';
        errorMessage.style.display = 'block';
        currentLocationBtn.disabled = false;
        currentLocationBtn.textContent = '📍 Vị trí của bạn';
    }
});