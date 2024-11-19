#!/bin/bash

# Текущая дата и время в секундах с начала эпохи
current_time_sec=$(date +%s)

# Указываем URL для отправки данных
url="localhost:8428/api/v1/import/prometheus"

# Создаем или очищаем лог-файлы
> log.txt
> log_bad.txt

# Формируем маску для поиска файлов
mask="2[4-6][0-1][0-9][0-2][0-9][0-5][0-9]*.txt"

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

    # Преобразуем дату в формат YYYY-MM-DD
    year="20${file_date:0:2}"
    month="${file_date:2:2}"
    day="${file_date:4:2}"
    hour="${file_time:0:2}"
    minute="${file_time:2:2}"

    # Проверяем валидность времени (часы < 24 и минуты < 60)
    if (( 10#$hour >= 24 || 10#$minute >= 60 )); then
        echo "$file" >> log_bad.txt
        rm "$file"
        continue
    fi

    # Преобразуем дату и время в секунды с начала эпохи
    file_time_sec=$(date -d "${year}-${month}-${day} ${hour}:${minute}" +%s 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        echo "$file" >> log_bad.txt
        rm "$file"
        continue
    fi

    # Сравниваем разницу времени, чтобы знать, не старше ли файл 5 минут
    if (( current_time_sec - file_time_sec > 300 )); then
        echo "$file" >> log_bad.txt
        rm "$file"
        continue
    fi

    # Флаг для отслеживания успешной обработки файла
    all_success=true

    # Обработка файлов с "NV" в имени
    if [[ "$file" == *NV* ]]; then
        IFS=$'\t' read -r _ label2 label3 label4 label5 label6 < "$file"

        while IFS=$'\t' read -r col1 col2 col3 col4 col5; do
            data_value="NV{$label2=\"$col2\", $label3=\"$col3\", $label4=\"$col4\"} $col5"
            response_value=$(curl -s -w "%{http_code}" -o /dev/null -X POST -d "$data_value" "$url")

            if [[ $response_value -ne 200 && $response_value -ne 204 ]]; then
                all_success=false
            fi
        done < <(tail -n +2 "$file")
        
    # Обработка файлов с "LV" в имени
    elif [[ "$file" == *LV* ]]; then
        IFS=$'\t' read -r header_label state_col2 state_col3 < "$file"
        while IFS=$'\t' read -r link_type value_col2 value_col3; do
            formatted_link_type=$(echo "$link_type" | tr -s ' ' '_' | tr -s '(' '_' | tr -s ')' '_' | sed 's/[ _]$//')

            for state in "$state_col2" "$state_col3"; do
                metric_value="$value_col2"
                data_value="LV{LINK_TYPE=\"${formatted_link_type}\", state=\"$state\"} $metric_value"
                response_value=$(curl -s -w "%{http_code}" -o /dev/null -X POST -d "$data_value" "$url")

                if [[ $response_value -ne 200 && $response_value -ne 204 ]]; then
                    all_success=false
                fi
            done

        done < <(tail -n +2 "$file")

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

            data_value = "CV{" label2_name "=" col2 ", " label3_name "=" col3 ", " label4_name "=" col4 ", " label5_name "=" col5 ", " label6_name "=" col6 ", " label7_name "=" col7 "} " col1
            cmd = "curl -s -w \"%{http_code}\" -o /dev/null -X POST -d \047" data_value "\047 " url
            cmd | getline response_value
            close(cmd)

            if (response_value != "200" && response_value != "204") {
                print "Ошибка при отправке данных из файла " FILENAME " (metric: CV). Код ответа: " response_value
            }
        }
        ' "$file"
    fi

    # Перемещаем файл в log.txt, если данные успешно отправлены
    if [[ $all_success == true ]]; then
        echo "$file" >> log.txt
    fi

    # Удаляем исходный файл
    rm "$file"
done
