class MessageMailer < ApplicationMailer
  default from: "Evercam Support <support@evercam.io>"
  default to: "Support <ciaran@evercam.io>"

  def new_message(message)
    @message = message

    mail ({subject: "Message from #{message.name}",
           reply_to: message.email})
  end

end
