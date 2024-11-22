#!/usr/bin/bash

# Указываем директорию для работы
directory="/home/psmon/vsp_files/"

# Текущая дата и время в секундах с начала эпохи
current_time_sec=$(date +%s)

# Указываем URL для отправки данных
url="localhost:8428/api/v1/import/prometheus"

# Переходим в указанную директорию
cd "$directory" || { echo "Ошибка: не удалось перейти в директорию $directory"; exit 1; }

# Создаем или очищаем лог-файлы
log_file="log.txt"
log_bad_file="log_bad.txt"
> "$log_file"
> "$log_bad_file"

# Формируем маску для поиска файлов
mask="2[4-6][0-1][0-2][0-9][0-5][0-9]*.txt"

# Находим файлы по маске
files=$(ls $mask 2>/dev/null)

# Проверяем, найдены ли файлы
if [ -z "$files" ]; then
    echo "Файлы не найдены!"
    exit 1
fi

# Перебираем найденные файлы и проверяем их срок годности
for file in $files; do
    # Извлекаем дату и время из имени файла
    file_date="${file:0:6}"  # ГГММДД
    file_time="${file:6:4}"  # ЧЧММ
    
    # Проверяем валидность времени (часы < 24 и минуты < 60)
    hour="${file_time:0:2}"
    minute="${file_time:2:2}"
    if (( 10#$hour >= 24 || 10#$minute >= 60 )); then
        echo "$file" >> "$log_bad_file"
        rm "$file"
        continue
    fi

    # Преобразуем дату и время в секунды с начала эпохи
    year="20${file_date:0:2}"
    month="${file_date:2:2}"
    day="${file_date:4:2}"
    file_time_sec=$(date -d "${year}-${month}-${day} ${hour}:${minute}" +%s 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        echo "$file" >> "$log_bad_file"
        rm "$file"
        continue
    fi

    # Сравниваем разницу времени, чтобы знать, не старше ли файл 5 минут
    if (( current_time_sec - file_time_sec > 301 )); then
        difference=$((current_time_sec - file_time_sec))
        echo "difference = $difference"
        echo "$file" >> "$log_bad_file"
        rm "$file"
        continue
    fi

    # Флаг для отслеживания успешной обработки файла
    all_success=true

    # Обработка файлов с "NV" в имени
    if [[ "$file" == *NV* ]]; then
        IFS=$'\t' read -r _ label2 label3 label4 label5 label6 < "$file"

        while IFS=$'\t' read -r col1 col2 col3 col4 col5; do
            data_value="NV{$label2=\"${col2}\", $label3=\"${col3}\", $label4=\"${col4}\"} $col5"
            response_value=$(curl -s -w "%{http_code}" -o /dev/null -X POST -d "$data_value" "$url")
            if [[ $response_value -ne 200 && $response_value -ne 204 ]]; then
                all_success=false
            fi
        done < <(tail -n +2 "$file")

    # Обработка файлов с "LV" в имени
elif [[ "$file" == *LV* ]]; then
    # Считываем заголовок, убирая символы \r
    IFS=$'\t' read -r header_label state_col2 raw_state_col3 < <(head -n 1 "$file" | tr -d '\r')
    state_col3="${raw_state_col3//$'\r'/}"

   # Пропускаем первую строку и читаем остальные строки файла
    tail -n +2 "$file" | while IFS=$'\t' read -r column1 column2 column3; do
        # Проверяем, если строка пустая, то пропускаем её
        if [[ -z "$column1" && -z "$column2" && -z "$column3" ]]; then
            continue
        fi

        # Убираем символы \r из каждой колонки данных
        column1="${column1//$'\r'/}"
        column2="${column2//$'\r'/}"
        column3="${column3//$'\r'/}"

        # Форматируем link_type
        formatted_link_type="${column1// /_}"
        formatted_link_type="${formatted_link_type//(/_}"
        formatted_link_type="${formatted_link_type//)/_}"
        formatted_link_type="${formatted_link_type%_}"  # Убираем символы _ в конце

        # Подготовка данных для state_col2
        data_value="NLV{LINK_TYPE=\"$formatted_link_type\", state=\"$state_col2\"} $column2"
        response_value=$(curl -s -w "%{http_code}" -o /dev/null -X POST -d "$data_value" "$url")
        if [[ "$response_value" != "200" ]]; then
            all_success=false
        fi

        # Подготовка данных для state_col3
        data_value="NLV{LINK_TYPE=\"${formatted_link_type}\", state=\"${state_col3}\"} ${column3}"
        sent_data+=("$data_value")  # Добавляем строку в массив
        echo "Отправляем на сервер: $data_value"  # Выводим строку в терминал
        response_value=$(curl -s -w "%{http_code}" -o /dev/null -X POST -d "$data_value" "$url")
        if [[ "$response_value" != "200" ]]; then
            all_success=false
        fi
    done

    # Вывод всех отправленных данных
    echo "Все отправленные данные:"
    for line in "${sent_data[@]}"; do
        echo "$line"
    done

    # Обработка файлов с "CV" в имени
elif [[ "$file" == *CV* ]]; then
    IFS=$'\t' read -r _ label2 label3 label4 label5 label6 label7 label8 label9 < "$file"

    awk -F'\t' -v url="$url" -v label2_name="$label2" -v label3_name="$label3" -v label4_name="$label4" -v label5_name="$label5" -v label6_name="$label6" -v label7_name="$label7" '
    NR > 1 {
        col1 = $1
        col2 = ($2 == "" ? "NULL" : "\"" $2 "\"")
        col3 = ($3 == "" ? "NULL" : "\"" $3 "\"")
        col4 = ($4 == "" ? "NULL" : "\"" $4 "\"")
        col5 = ($5 == "" ? "NULL" : "\"" $5 "\"")
        col6 = ($6 == "" ? "NULL" : "\"" $6 "\"")
        col7 = ($7 == "" ? "NULL" : "\"" $7 "\"")
        data_value = "CV{" label2_name "=\"" col2 "\", " label3_name "=\"" col3 "\", " label4_name "=\"" col4 "\", " label5_name "=\"" col5 "\", " label6_name "=\"" col6 "\", " label7_name "=\"" col7 "\"} " col1
        cmd = "curl -s -w \"%{http_code}\" -o /dev/null -X POST -d \047" data_value "\047 \"" url "\""
        cmd | getline response_value
        close(cmd)
        if (response_value != "200" && response_value != "204") {
            print "Ошибка при отправке данных из файла " FILENAME " (metric: CV). Код ответа: " response_value
        }
    }' "$file"
fi

    # Запись имени обработанного файла в log.txt, если данные успешно отправлены
    if [[ $all_success == true ]]; then
        echo "$file" >> "$log_file"
    fi

    # Удаляем исходный файл
    rm "$file"
done
