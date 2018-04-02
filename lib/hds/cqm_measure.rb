module HealthDataStandards
   module CQM
    class Measure
      include Mongoid::Document
      field :lower_is_better, type: Boolean

      has_and_belongs_to_many :value_sets, class_name: 'HealthDataStandards::SVS::ValueSet', inverse_of: nil, primary_key: 'oid', foreign_key: 'oids'

      def value_sets_to_hashes
        value_sets.inject({}) do |h2,vs|
          h2[vs.oid] = vs.concepts.map { |c| c.attributes.slice('code', 'code_system') }; h2
        end
      end

      # this is called in hds Measure but does not resolve correctly
      def data_criteria
        return nil unless self['hqmf_document'] and self['hqmf_document']['data_criteria']
        self['hqmf_document']['data_criteria'].map { |key, val| { key => val } }
      end

      # replaced with the one from cypress for compatibility with their baroque processing
      # def data_criteria
      #   self.hqmf_document['data_criteria']
      # end
      # def population_criteria
      #   self.hqmf_document['population_criteria']
      # end
      # doesn't actually match the damn data in cqm/measure
      # def all_data_criteria
      #   return @crit if @crit
      #   @crit = []
      #   self.data_criteria.each do |k, v|
      #       @crit << HQMF::DataCriteria.from_json(k,v)
      #   end
      #   @crit
      # end

      def to_hash
        {
          :name =>  self[:name],
          :cms_id => self[:cms_id],
          :nqf_id => self[:nqf_id],
          :hqmf_id => self[:hqmf_id],
          :hqmf_set_id => self[:hqmf_set_id],
          :hqmf_version_number => self[:hqmf_version_number],
          :value_sets => self.value_sets_to_hashes
        }
      end
    end
  end
end
