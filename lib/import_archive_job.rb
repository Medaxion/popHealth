class ImportArchiveJob
  attr_accessor :file, :current_user, :practice
  
  def initialize(options)
    @file = options['file'].path
    @current_user = options['user']
    @practice = options['practice']
    puts "Initializing"
  end

  def before
    puts "Before"
    Log.create(:username => @current_user.username, :event => 'record import')
  end

  def perform
    puts "Perform"
    puts @file
    begin
    missing_patients = BulkRecordImporter.import_archive(File.new(@file), nil, @practice)
    rescue => e
      raise
    end
    missing_patients.each do |id|
      Log.create(:username => @current_user.username, :event => "patient was present in patient manifest but not found after import", :medical_record_number => id)
    end
  end

  def after
    puts "After"
    #File.delete(@file)
    #HealthDataStandards::CQM::QueryCache.delete_all
    #PatientCache.delete_all    
  end
end
