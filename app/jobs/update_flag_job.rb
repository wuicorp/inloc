class UpdateFlagJob
  @queue = :flags

  def perform(flag_id, params)
    puts "JOBS: Start updating flag #{flag_id} with #{params}"

    Flag.find_by_id(flag_id).update_attributes!(params)

    puts "JOBS: Flag #{flag_id} updated with #{params}"
  end
end
