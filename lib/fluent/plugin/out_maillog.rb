class Fluent::MaillogOutput < Fluent::Output
  Fluent::Plugin.register_output('maillog', self)
end
