module HealthDataStandards
  module CQM
    class QueryCache

      # FIXME:
      def self.aggregate_measure(measure_id, effective_date, filters=nil, sub_id=nil)
        query_hash = {'effective_date' => effective_date, 'measure_id' => measure_id}
        if filters
          query_hash.merge!(filters)
        end
        if sub_id
          query_hash.merge!(sub_id)
        end
        cache_entries = self.where(query_hash)
        aggregate_count = AggregateCount.new(measure_id)
        cache_entries.each do |cache_entry|
          #Need to modify cache_entries value to be the antinumerator value. This is a Query Cache object
          Rails.logger.info("Cache Entry is #{cache_entry}")
          cache_entry.population_ids.each do |pop_type, pop_id|
            if ((pop_type == "DENOM" || pop_type == "IPP") && cache_entry["DENEXCEP"] != 0)
              Rails.logger.info("Setting cache_entry #{pop_type} to #{cache_entry.antinumerator}")
              cache_entry[pop_type] = cache_entry.antinumerator
              Rails.logger.info("Cache_entry #{pop_type} is now #{cache_entry[pop_type]}")
            end
          end
          aggregate_count.add_entry(cache_entry)
        end
        aggregate_count
      end
    end
  end
end
