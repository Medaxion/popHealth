# Extending QualityReport so that updating a single patient can deal with
# OID dictionaries
module QME
  class QualityReport
    include Mongoid::Document

    field :aggregate_result, type: Integer

    # Removes the cached results for the patient with the supplied id and
    # recalculates as necessary
    def self.update_patient_results(id)
      # TODO: need to wait for any outstanding calculations to complete and then prevent
      # any new ones from starting until we are done.

      # drop any cached measure result calculations for the modified patient
      QME::PatientCache.where('value.medical_record_id' => id).destroy()

      # get a list of cached measure results for a single patient
      sample_patient = QME::PatientCache.where({}).first
      if sample_patient
        cached_results = QME::PatientCache.where({'value.patient_id' => sample_patient['value']['patient_id']})

        # for each cached result (a combination of measure_id, sub_id, effective_date and test_id)
        cached_results.each do |measure|
          # recalculate patient_cache value for modified patient
          value = measure['value']
          measure_model = QME::QualityMeasure.new(value['measure_id'], value['sub_id'], value['test_id'])
          oid_dictionary = OidHelper.generate_oid_dictionary(measure_model)
          map = QME::MapReduce::Executor.new(value['measure_id'], value['sub_id'],
                                             'effective_start_date' => value['effective_start_date'],
                                             'effective_date' => value['effective_date'], 'test_id' => value['test_id'],
                                             'oid_dictionary' => oid_dictionary)
	  Rails.logger.info("about to map for #{id}")
          map.map_record_into_measure_groups(id)
        end
      end

      # remove the query totals so they will be recalculated using the new results for
      # the modified patient

      QME::QualityReport.where({}).each do |qr|
        measure_model = QME::QualityMeasure.new(qr['measure_id'], qr['sub_id'], qr['test_id'])
        oid_dictionary = OidHelper.generate_oid_dictionary(measure_model)
        qr.calculate({"recalculate" => true, "oid_dictionary" => oid_dc}, true)
      end
    end

    # find_or_create fails if you create _and_ there is a prefilter
    def self.find_or_create(measure_id, sub_id, parameter_values)
      @parameter_values = parameter_values
      @parameter_values[:filters] = self.normalize_filters(@parameter_values[:filters])
      query = {measure_id: measure_id, sub_id: sub_id}
      query.merge! @parameter_values
      # PROBLEM: prefilter when present has format that will never match anything
      params= query.except!('prefilter')
      m=nil
      m = QME::QualityMeasure.where(:hqmf_id => params[:measure_id], :sub_id=> params[:sub_id]).first #rescue # bogus setting error on no docs
      if (m.present? && m[:prefilters].present?)
        # replicating correct measure prefilters here; alternative: stringify prefilter value
        params[:prefilters] = m[:prefilters]
      end
      qr = self.find_or_create_by(params)
    end
  end
end
