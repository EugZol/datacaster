RSpec.describe Datacaster do
  include Dry::Monads[:result]

  before(:all) do
    @i18n_module = Datacaster::Config.i18n_module
    Datacaster::Config.i18n_module = Datacaster::SubstituteI18n
  end

  after(:all) do
    Datacaster::Config.i18n_module = @i18n_module
  end

  describe 'partial schema' do
    it 'shares check context with full schema in hash checks' do
      common_validator =
        Datacaster.partial_schema do
          hash_schema(
            description: string
          )
        end

      person_validator =
        Datacaster.partial_schema do
          hash_schema(
            name: string
          )
        end

      record_validator =
        Datacaster.schema do
          common_validator * person_validator
        end

      record = {name: 'John', description: 'a person'}
      expect(record_validator.(record).to_dry_result).to eq Success(record)

      record = {name: 'John', description: 'a person', extra: '123'}
      expect(record_validator.(record).to_dry_result).to eq Failure(extra: ['must be absent'])
    end

    it "doesn't leak with transform_to_hash" do
      person_details = Datacaster.partial_schema do
        transform_to_hash(
          name: pick(:name),
          name_kind: pick(:name_kind)
        ) & switch(:name_kind).on('SPECIAL', cast { Failure('is special') }).else(pass)
      end

      full_details = Datacaster.schema do
        switch(:kind, person: person_details)
      end

      ordinary = {name: 'John', name_kind: 'ORDINARY', kind: :person}
      expect(full_details.(ordinary).to_dry_result).to eq Success(ordinary)

      additional_fields = {name: 'John', name_kind: 'ORDINARY', kind: :person, extra: '123'}
      expect(full_details.(additional_fields).to_dry_result).to eq Failure(extra: ['must be absent'])
    end

    it 'allows literal hashes' do
      a_hash = Datacaster.schema { hash_value }
      expect(a_hash.({}).to_dry_result).to eq Success({})
      expect(a_hash.(some: :thing, any: :thing).to_dry_result).to eq Success(some: :thing, any: :thing)
    end
  end
end
