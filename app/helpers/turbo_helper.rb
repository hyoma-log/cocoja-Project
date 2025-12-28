module TurboHelper
  def turbo_frame_request?
    request.headers['Turbo-Frame'].present?
  end

  def turbo_stream_request?
    request.format.to_s == Mime[:turbo_stream]
  end
end
