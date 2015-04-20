require 'oj'
require 'active_record'

module Sequent
  module Core

    module SerializesEvent

      def event
        payload = Oj.strict_load(self.event_json, {})
        Class.const_get(self.event_type.to_sym).deserialize_from_json(payload)
      end

      def event=(event)
        self.aggregate_id = event.aggregate_id
        self.sequence_number = event.sequence_number
        self.organization_id = event.organization_id if event.respond_to?(:organization_id)
        self.event_type = event.class.name
        self.created_at = event.created_at
        self.event_json = Oj.dump(event.attributes)
      end

    end

    class EventRecord < ActiveRecord::Base
      include SerializesEvent

      self.table_name = "event_records"

      belongs_to :command_record

      validates_presence_of :aggregate_id, :sequence_number, :event_type, :event_json
      validates_numericality_of :sequence_number



    end

  end
end

