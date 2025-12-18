#!/bin/bash

# ============================================
# Скрипт проверки статуса вебхука Telegram бота
# Использование: ./check_webhook.sh
# ============================================

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔍 Проверка статуса вебхука Telegram бота${NC}"
echo "=============================================="

# Проверяем наличие токена
if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    echo -e "${RED}❌ Ошибка: переменная TELEGRAM_BOT_TOKEN не установлена${NC}"
    echo "Установите её командой:"
    echo "  export TELEGRAM_BOT_TOKEN='ваш_токен'"
    exit 1
fi

echo -e "✅ Токен обнаружен: ${TELEGRAM_BOT_TOKEN:0:10}..."
echo -e "⏳ Запрашиваю информацию у Telegram API..."

# Выполняем запрос
RESPONSE=$(curl -s -w "\n%{http_code}" \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo")

# Разделяем тело ответа и HTTP код
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

echo ""
echo -e "${CYAN}📊 Статус вебхука:${NC}"
echo "----------------------"

if [ "$HTTP_CODE" = "200" ]; then
    # Проверяем успешность ответа API
    if echo "$RESPONSE_BODY" | grep -q '"ok":true'; then
        # Извлекаем и форматируем информацию
        URL=$(echo "$RESPONSE_BODY" | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
        HAS_CERT=$(echo "$RESPONSE_BODY" | grep -o '"has_custom_certificate":[^,]*' | cut -d':' -f2)
        PENDING_UPDATES=$(echo "$RESPONSE_BODY" | grep -o '"pending_update_count":[^,]*' | cut -d':' -f2)
        LAST_ERROR=$(echo "$RESPONSE_BODY" | grep -o '"last_error_message":"[^"]*"' | cut -d'"' -f4)
        LAST_ERROR_DATE=$(echo "$RESPONSE_BODY" | grep -o '"last_error_date":[^,]*' | cut -d':' -f2)

        if [ -z "$URL" ] || [ "$URL" = '""' ]; then
            echo -e "${YELLOW}⚠️  Вебхук не установлен${NC}"
            echo "   Для установки выполните: ./set_webhook.sh <ваш_url>"
        else
            echo -e "${GREEN}✅ Вебхук установлен${NC}"
            echo "   URL: $URL"
            echo "   Ожидающих обновлений: $PENDING_UPDATES"

            if [ "$LAST_ERROR_DATE" != "0" ] && [ -n "$LAST_ERROR" ]; then
                echo -e "${RED}   Последняя ошибка: $LAST_ERROR${NC}"

                # Конвертируем Unix timestamp в читаемую дату
                if [ "$LAST_ERROR_DATE" != "0" ]; then
                    ERROR_DATE=$(date -d @"$LAST_ERROR_DATE" 2>/dev/null || echo "неизвестная дата")
                    echo "   Дата ошибки: $ERROR_DATE"
                fi
            else
                echo -e "${GREEN}   Последних ошибок нет${NC}"
            fi

            if [ "$HAS_CERT" = "true" ]; then
                echo "   Используется собственный SSL сертификат"
            fi
        fi
    else
        echo -e "${RED}❌ Ошибка в ответе API${NC}"
        echo "Тело ответа:"
        echo "$RESPONSE_BODY" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE_BODY"
    fi
else
    echo -e "${RED}❌ HTTP ошибка: $HTTP_CODE${NC}"
    echo "Ответ сервера:"
    echo "$RESPONSE_BODY"
fi

# Дополнительная проверка: тестируем доступность вебхука
echo ""
echo -e "${CYAN}🌐 Проверка доступности вебхука:${NC}"
echo "--------------------------------"

if [ -n "$URL" ] && [ "$URL" != '""' ]; then
    echo -e "Проверяю доступность: $URL"

    # Проверяем доступность эндпоинта
    WEBHOOK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -I "$URL")

    if [ "$WEBHOOK_STATUS" = "200" ] || [ "$WEBHOOK_STATUS" = "404" ]; then
        # 404 - это нормально, если это специальная страница для вебхука
        echo -e "${GREEN}✅ Вебхук доступен (HTTP $WEBHOOK_STATUS)${NC}"
    elif [ "$WEBHOOK_STATUS" = "000" ]; then
        echo -e "${RED}❌ Вебхук недоступен (таймаут)${NC}"
        echo "   Возможно, сервис выключен или URL неверный"
    else
        echo -e "${YELLOW}⚠️  Вебхук отвечает с кодом: $WEBHOOK_STATUS${NC}"
    fi
else
    echo "Нет URL для проверки доступности"
fi