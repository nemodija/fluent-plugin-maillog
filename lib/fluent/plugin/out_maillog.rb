class Fluent::MaillogOutput < Fluent::Output
  Fluent::Plugin.register_output('maillog', self)

  attr_accessor :records
  attr_reader   :latest_clean_time

  def initialize
    super
    @records = Hash.new
    @latest_clean_time = Time.now.to_i
  end

  def configure(conf)
    super
    @base_pattern = /^(?<time>.{3}\s{1,2}\d{1,2} \d{2}:\d{2}:\d{2}) (?<host>\S+) (?<cmd>.+)\[\d+\]: (?<qid>[0-9a-zA-Z]+): (?<message>.+)$/
    # patterns
    @regist_patterns = [
      /^client=.+$/,
      /^message-id=<(?<message_id>[^,]+)>$/,
      /^DKIM-Signature field added \(s=(?<dkim_s>[^,]+), d=(?<dkim_d>[^,]+)\)$/
    ]
    @reemit_patterns = [
      /^to=<(?<to>[^,]+)>, relay=(?<relay>[^ ]+), delay=(?<delay>[^ ]+), delays=(?<delays>[^ ]+), dsn=(?<dsn>[^ ]+), status=(?<status>[^ ]+) \((?<message>.+)\)$/
    ]
    @remove_patterns = [
      /^removed$/
    ]
  end

  def start
    super
  end

  def shutdown
    super
  end

  def emit(tag, es, chain)
    es.each do |time,record|
      record.values.each do |line|
        summary = summarize(line)
        next if summary.nil?
        Fluent::Engine.emit(tag, time, summary)
      end
    end
    chain.next
  end

  def summarize(line)

    if @base_pattern =~ line
      qid     = Regexp.last_match[:qid]
      time    = Regexp.last_match[:time]
      message = Regexp.last_match[:message]
      return nil if qid.nil? || time.nil?
      record = @records[qid]
      if record.nil?
        record = { 'qid' => qid, 'time' => Time.parse(time).to_i } 
        @records.store(qid, record)
      end

      # regist
      @regist_patterns.each do |pattern|
        if pattern =~ message
          pattern.named_captures.keys.each do |name|
            record[name] = Regexp.last_match[name.to_sym]
          end
          return nil
        end
      end

      # reemit
      @reemit_patterns.each do |pattern|
        if pattern =~ message
          pattern.named_captures.keys.each do |name|
            record[name] = Regexp.last_match[name.to_sym]
          end
          record['time'] = Time.parse(time).to_i
          return record
        end
      end

      # remove
      @remove_patterns.each do |pattern|
        if pattern =~ message
          @records.delete(qid)
        end
      end
    end

    clean_records

    return nil
  end

  def clean_records(clean_interval = 60, survival_time = 3600)
    return if Time.now.to_i < @latest_clean_time + clean_interval
    @records.delete_if do |key, record|
      Time.now.to_i > record['time'] + survival_time
    end
    @latest_clean_time = Time.now.to_i
  end
end
