require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'
require 'pony'

my_mail = 'vadim.volovenko@gmail.com'
password = "12SPOrter@!@!"
subject = "Напоминание о событии"

TOKEN = "1398645931:AAEhVwDb7IYuXso6A48c3jQ5ntqm5nbTWa4"

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|

    user = User.find_or_create_by(telegram_id: message.chat.id)
    events = Event.all

    case user.step
    when "name"
      user.update(name: message.text)
      user.step = "email"
      user.save
      bot.api.send_message(chat_id: message.chat.id, text: "Напиши мне email")

    when "email"
      user.update(email: message.text)
      bot.api.send_message(chat_id: message.chat.id, text: "Спасибо, я сохранил твои данные. Теперь отправь мне дату события /event")
      user.save
      user.step = nil
      user.save

    when "date"
      user.events.create(date: message.text)
      user.step = "text"
      user.save
      bot.api.send_message(chat_id: message.chat.id, text: "Напиши описания события")
    when "text"
      new_event = user.events.last
      new_event.text = message.text
      bot.api.send_message(chat_id: message.chat.id, text: "Спасибо, я сохранил твои данные. Я обязательно напомню тебе здесь, а также продублирую на почту.")
      new_event.save
      user.step = nil
      user.save
      sleep (user.events.last.date.to_time.to_i - Time.now.to_time.to_i)
      bot.api.send_message(chat_id: message.chat.id, text: "Напоминаю! #{new_event.text}")

      Pony.mail(
                subject: subject,
                body: "Вы попросили напомнить Вам о событии. #{new_event.text}",
                to: user.email,
                from: my_mail,
                via: :smtp,
                via_options: {
                  address: 'smtp.gmail.com',
                  port: '587',
                  enable_starttls_auto: true,
                  user_name: my_mail,
                  password: password,
                  authentication: :plain
                }
      )
    end

    case message.text
    when "/user"
      user.step = "name"
      user.save
      bot.api.send_message(chat_id: message.chat.id, text: "Напиши свое имя")
    when "/event"
      user.step = "date"
      user.save
      bot.api.send_message(chat_id: message.chat.id, text: "Напиши дату и время, например: #{Time.now.strftime("%Y-%m-%d %H:%M")}")

    when "/events"
      user.events.each do | event |
        bot.api.send_message(chat_id: message.chat.id, text: "#{event.date} #{event.text}")
      end
    end
  end
end
