import os
import telebot
from flask import Flask
from threading import Thread

# Создаем Flask приложение для здоровья (нужно Render)
app = Flask(__name__)

@app.route('/')
def home():
    return "Бот работает!"

# Получаем токен
TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
bot = telebot.TeleBot(TOKEN)

# Обработчики команд
@bot.message_handler(commands=['start'])
def send_welcome(message):
    bot.reply_to(message, "🚀 Бот запущен на Render!")

@bot.message_handler(commands=['help'])
def send_help(message):
    bot.reply_to(message, "/start - запуск\n/help - помощь")

@bot.message_handler(func=lambda message: True)
def echo_all(message):
    bot.reply_to(message, f"Вы сказали: {message.text}")

# Функция запуска бота
def run_bot():
    print("Бот запускается...")
    bot.infinity_polling(timeout=10, long_polling_timeout=5)

if __name__ == "__main__":
    # Запускаем Flask в отдельном потоке
    flask_thread = Thread(target=lambda: app.run(host='0.0.0.0', port=10000, debug=False, use_reloader=False))
    flask_thread.start()

    # Запускаем бота
    run_bot()