RspecApiDocumentation.configure do |config|
    # Output folder
    config.docs_dir = Rails.root.join("doc", "api")

    # An array of output format(s).
    # Possible values are :json, :html, :combined_text, :combined_json,
    #   :json_iodocs, :textile, :markdown, :append_json
    config.format = [:json]

    # Change how the post body is formatted by default, you can still override by `raw_post`
    # Can be :json, :xml, or a proc that will be passed the params
    config.request_body_formatter = [:json]
  end