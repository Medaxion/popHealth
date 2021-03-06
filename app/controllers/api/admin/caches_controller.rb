module Api
  module Admin
    class CachesController < ApplicationController
      resource_description do
        resource_id 'Admin::Caches'
        short 'Caches Admin'
        formats ['json']
        description "This resource allows for administrative tasks to be performed on the cache via the API."
      end
      include LogsHelper
      before_filter :authenticate_user!
      before_filter :validate_authorization!

      api :GET, "/admin/caches/count", "Return count of caches in the database."
      example '{"query_cache_count":56, "patient_cache_count":100}'
      def count
        log_admin_api_call LogAction::VIEW, "Count of caches"
        json = {}
        json['query_cache_count'] = HealthDataStandards::CQM::QueryCache.count
        json['patient_cache_count'] = PatientCache.count
        render :json => json
      end

      api :DELETE, "/admin/caches", "Empty all caches in the database."
      def destroy
        log_admin_api_call LogAction::DELETE, "Empty all caches"
        HealthDataStandards::CQM::QueryCache.delete_all
        PatientCache.delete_all
        render status: 200, text: 'Server caches have been emptied.'
      end

      api :DELETE, "/admin/caches/reset", "Reset pophealth records for recalculation"
      def reset
        log_admin_api_call LogAction::DELETE, "Reset database"
        Record.delete_all
        Delayed::Job.delete_all
        Log.delete_all
        PatientCache.delete_all
        HealthDataStandards::CQM::QueryCache.delete_all
        QME::QualityReport.delete_all
        render status: 200, text: 'Pophealth has been reset and is ready for calculation'
      end

      private

      def validate_authorization!
        authorize! :admin, :users
      end
    end
  end
end