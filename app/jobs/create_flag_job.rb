class CreateFlagJob
  @queue = :flags

  def self.perform(params)
    puts "JOBS: Start creating flag with #{params}"

    Flag.create(params)

    puts "JOBS: Flag created with #{params}"
  end
end
