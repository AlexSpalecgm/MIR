#!/bin/bash

# Ваш список метрик
metrics_file="1.txt"
# Адрес вашего VictoriaMetrics
vm_url="http://localhost:8428"
# Лог-файл
log_file="script.log"

# Перенаправляем весь вывод скрипта в лог-файл
exec > >(tee -a "$log_file") 2>&1

while read metric; do
    echo "Метрика: $metric"
    # Получаем все метки для этой метрики
    labels=$(curl -s "$vm_url/api/v1/labels" | jq -r '.data[]')
    echo "Метки:"
    for label in $labels; do
        echo "  $label"
        # Получаем все значения для этой метки (если нужно, можно оставить или убрать)
        # values=$(curl -s "$vm_url/api/v1/label/$label/values")
        # echo "    Значения:"
        # echo "$values" | jq -r '.data[]'
    done
done < "$metrics_file"
