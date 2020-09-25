require 'inspec'

property :profiles, Array, required: true
property :node_name, String, required: true
property :target, String, required: true, sensitive: true
property :organization_name, String, required: true

default_action :run

action :run do
  $stdout.puts "" # Make output more
  RemoteAudit::ExceptionManager.execblock do
    guid = RemoteAudit::GuidManager.get(new_resource.node_name)

    Chef::Log.debug "Starting scan of node #{new_resource.node_name} with guid #{guid}"
    Chef::Log.debug "Starting scan of node organization #{new_resource.organization_name}"
    runner = Inspec::Runner.new('target' => new_resource.target, 'report' => true)

    new_resource.profiles.each do |p|
      RemoteAudit::ExceptionManager.execblock do
        profile = RemoteAudit::ProfileManager.download_profile(p)
        runner.add_target(profile.path)
      end
    end

    runner.run
    results = runner.report

    passed_controls = results[:controls].select { |c| c[:status] == 'passed' }.size
    failed_controls = results[:controls].select { |c| c[:status] == 'failed' }.size
    skipped_controls = results[:controls].select { |c| c[:status] == 'skipped' }.size

    results[:profiles].select! { |p| p } # Remove nil profiles
    results[:type] = 'inspec_report'
    results.delete(:controls) # Ensure source controls are never stored or shipped
    results[:platform].delete :target # Ensure we dont report the target as it may contain passwords
    results[:node_name] = new_resource.node_name
    results[:end_time] = Time.now.utc.strftime('%FT%TZ')
    results[:node_uuid] = guid
    results[:environment] = "remote_scanner_#{node.name}"
    results[:report_uuid] = SecureRandom.uuid
    results[:organization_name] = new_resource.organization_name

    report_size = results.to_json.bytesize
    if report_size > 900 * 1024
      Chef::Log.warn "Compliance report size is #{(report_size / (1024 * 1024.0)).round(2)} MB"
    end

    rest = Chef::ServerAPI.new
    rest.post('data-collector', results)

    # Abuse converge_by to display converge stats
    converge_by "Inspec summary for #{new_resource.node_name}:"\
      " #{passed_controls} successful,"\
      " #{failed_controls} failures,"\
      " #{skipped_controls} skipped"\
      " in #{results[:statistics][:duration].round(2)}s"\
      " size #{(report_size / (1024 * 1024.0)).round(2)}mB" do
    end
  end
end
