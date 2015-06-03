namespace 'tef' do

  task :set_tef_environment do
    ENV['TEF_ENV'] ||= 'dev'
    ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'
    ENV['TEF_AMQP_USER_DEV'] ||= 'guest'
    ENV['TEF_AMQP_PASSWORD_DEV'] ||= 'guest'
  end

end
