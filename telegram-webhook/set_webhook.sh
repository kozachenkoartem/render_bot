#!/bin/bash

# ============================================
# Скрипт установки вебхука для Telegram бота
# Использование: ./set_webhook.sh <ваш_url>
# Пример: ./set_webhook.sh https://my-bot.onrender.com
# ============================================

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DEFAULT_URL="https://render-bot-meuj.onrender.com/webhook"

echo -e "${YELLOW}⚙️  Настройка вебхука Telegram бота${NC}"
echo "====================================="

# Проверяем наличие токена
if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    echo -e "${RED}❌ Ошибка: переменная TELEGRAM_BOT_TOKEN не установлена${NC}"
    echo "Установите её командой:"
    echo "  export TELEGRAM_BOT_TOKEN='ваш_токен'"
    echo "Или добавьте в ~/.bashrc / ~/.zshrc"
    exit 1
fi

echo -e "✅ Токен обнаружен: ${TELEGRAM_BOT_TOKEN:0:10}..."

# Проверяем URL
if [ -z "$1" ]; then

    # Пробуем получить URL из переменной окружения
    if [ -n "$RENDER_EXTERNAL_URL" ]; then
        URL="$RENDER_EXTERNAL_URL"
        echo -e "📡 Использую URL из RENDER_EXTERNAL_URL: $URL"
    else
        echo -e "${YELLOW}⚠️  URL не указан. Использую значение по умолчанию :${DEFAULT_URL}${NC}"
        URL="$DEFAULT_URL"
    fi
else
    URL="$1"
fi

# Убираем слеш в конце, если есть
URL="${URL%/}"

# Формируем полный URL для вебхука
WEBHOOK_URL="${URL}/webhook"

echo -e "🔗 Устанавливаю вебхук на: ${GREEN}${WEBHOOK_URL}${NC}"
echo -e "⏳ Это может занять несколько секунд..."

# Отправляем запрос на установку вебхука
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
    -d "{\"url\": \"${WEBHOOK_URL}\", \"max_connections\": 100, \"drop_pending_updates\": true}")

# Разделяем тело ответа и HTTP код
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

echo ""
echo "📊 Результат запроса:"
echo "---------------------"

if [ "$HTTP_CODE" = "200" ]; then
    # Парсим JSON ответ
    if echo "$RESPONSE_BODY" | grep -q '"ok":true'; then
        echo -e "${GREEN}✅ Вебхук успешно установлен!${NC}"

        # Извлекаем дополнительную информацию
        WEBHOOK_INFO=$(echo "$RESPONSE_BODY" | grep -o '"result":[^,}]*' | cut -d':' -f2-)
        if [ -n "$WEBHOOK_INFO" ]; then
            echo "   URL: $WEBHOOK_URL"
            echo "   Max connections: 100"
            echo "   Pending updates: очищены"
        fi
    else
        echo -e "${RED}❌ Ошибка при установке вебхука${NC}"
        echo "Ответ от Telegram API:"
        echo "$RESPONSE_BODY" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE_BODY"
    fi
else
    echo -e "${RED}❌ HTTP ошибка: $HTTP_CODE${NC}"
    echo "Ответ сервера:"
    echo "$RESPONSE_BODY"
fi

# Предлагаем проверить статус
echo ""
echo -e "${YELLOW}📝 Для проверки статуса выполните:${NC}"
echo "  ./check_webhook.sh"
echo "или"
echo "  curl https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN:0:10}.../getWebhookInfo | python3 -m json.tool"