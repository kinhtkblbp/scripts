#!/bin/bash

# Kiểm tra số lượng tham số
if [ "$#" -ne 2 ]; then
    echo "Cách sử dụng: $0 <số_lần_test> <url>"
    echo "Ví dụ: $0 10 'https://api.example.com'"
    exit 1
fi

# Lấy tham số đầu vào
TIMES=$1
URL=$2

# Kiểm tra số lần test có phải là số không
if ! [[ "$TIMES" =~ ^[0-9]+$ ]]; then
    echo "Lỗi: Số lần test phải là số nguyên dương"
    exit 1
fi

echo "Bắt đầu test API $TIMES lần:"
echo "URL: $URL"
echo "----------------------------------------"

# Mảng lưu các kết quả để tính trung bình
declare -a connect_times=()
declare -a starttransfer_times=()
declare -a total_times=()

for i in $(seq 1 $TIMES)
do
    echo "Lần thử #$i:"
    
    # Thực hiện curl và lưu kết quả vào biến
    result=$(curl -w "\ntime_connect: %{time_connect}\ntime_starttransfer: %{time_starttransfer}\ntime_total: %{time_total}" \
        -o /dev/null -s "$URL")
    
    # Kiểm tra nếu curl bị lỗi
    if [ $? -ne 0 ]; then
        echo "Lỗi: Không thể kết nối tới URL"
        exit 1
    }
    
    # Trích xuất các giá trị thời gian
    connect=$(echo "$result" | grep "time_connect:" | cut -d' ' -f2)
    starttransfer=$(echo "$result" | grep "time_starttransfer:" | cut -d' ' -f2)
    total=$(echo "$result" | grep "time_total:" | cut -d' ' -f2)
    
    # Lưu vào mảng
    connect_times+=($connect)
    starttransfer_times+=($starttransfer)
    total_times+=($total)
    
    echo "Thời gian kết nối: ${connect}s"
    echo "Thời gian bắt đầu truyền: ${starttransfer}s"
    echo "Tổng thời gian: ${total}s"
    echo "----------------------------------------"
    
    # Delay 1 giây giữa các request
    sleep 1
done

# Hàm tính trung bình
calc_avg() {
    local sum=0
    local len=${#1[@]}
    for n in "${@}"; do
        sum=$(echo "$sum + $n" | bc)
    done
    echo "scale=3; $sum / $len" | bc
}

echo "KẾT QUẢ TRUNG BÌNH SAU $TIMES LẦN:"
echo "Thời gian kết nối TB: $(calc_avg "${connect_times[@]}")s"
echo "Thời gian bắt đầu truyền TB: $(calc_avg "${starttransfer_times[@]}")s"
echo "Tổng thời gian TB: $(calc_avg "${total_times[@]}")s"