from flask import Flask, request
import telebot
import os

# 1. Инициализируем Flask и бота
app = Flask(__name__)
TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
bot = telebot.TeleBot(TOKEN)

# 2. Обработчик для главной страницы (для проверки)
@app.route('/')
def home():
    return '🤖 Бот жив! Webhook URL: /webhook'

# 3. СЕРДЦЕ СИСТЕМЫ: Сюда Telegram будет присылать сообщения
@app.route('/webhook', methods=['POST'])
def telegram_webhook():
    # 3.1 Получаем и разбираем данные от Telegram
    json_data = request.get_json()
    # Создаём объект "обновления" из JSON
    update = telebot.types.Update.de_json(json_data)

    # 3.2 Передаём обновление боту на обработку
    bot.process_new_updates([update])

    # 3.3 Всегда отвечаем 'OK', чтобы Telegram знал, что мы получили данные
    return 'OK', 200

# 4. ЛОГИКА БОТА (остаётся почти такой же!)
@bot.message_handler(commands=['start'])
def send_welcome(message):
    bot.reply_to(message, f"Привет, {message.from_user.first_name}! Я работаю через вебхук!")

@bot.message_handler(func=lambda m: True)
def echo_all(message):
    bot.reply_to(message, f"Вы написали: {message.text}")

# 5. Запуск и настройка вебхука
if __name__ == '__main__':
    from threading import Thread
    # 5.1 Устанавливаем вебхук в отдельном потоке при старте
    def set_webhook_on_start():
        # Удаляем старый вебхук, если был
        bot.remove_webhook()
        # Ждём немного, чтобы Flask точно запустился
        import time
        time.sleep(2)
        # !! ВАЖНО: Подставь сюда свой реальный URL с Render !!
        WEBHOOK_URL = 'https://render-bot-meuj.onrender.com/webhook'
        bot.set_webhook(url=WEBHOOK_URL)
        print(f'✅ Вебхук установлен на {WEBHOOK_URL}')

    Thread(target=set_webhook_on_start).start()

    # 5.2 Запускаем Flask-сервер
    app.run(host='0.0.0.0', port=10000)