RSpec.describe Datacaster do
  include Dry::Monads[:result]

  describe 'switch node' do
    it 'performs switching with shortcuts' do
      caster =
        Datacaster.schema do
          person = hash_schema(kind: any, name: string)
          entity = hash_schema(kind: any, title: string)
          other = hash_schema(kind: any, comment: string)

          switch(:kind).
            on('person', person).
            on('entity', entity).
            else(other)
        end

      expect(caster.(kind: 'person', name: 'name').to_dry_result).to eq Success(kind: 'person', name: 'name')
      expect(caster.(kind: 'entity', title: 'entity').to_dry_result).to eq Success(kind: 'entity', title: 'entity')
      expect(caster.(kind: 'other', comment: 'other').to_dry_result).to eq Success(kind: 'other', comment: 'other')

      expect(caster.(kind: 'person', name: 1).to_dry_result).to eq Failure(name: ['is not a string'])
      expect(caster.(kind: 'entity', title: 1).to_dry_result).to eq Failure(title: ['is not a string'])
      expect(caster.(kind: 'another', comment: 1).to_dry_result).to eq Failure(comment: ['is not a string'])

      expect(caster.(1).to_dry_result).to eq Failure(["is not Enumerable"])
    end

    it 'performs switching with array shortcut' do
      caster =
        Datacaster.schema do
          switch([:first, :second], 'second' => transform { 1 }, 'else' => transform { 2 })
        end

      expect(caster.(first: {second: 'second'}).to_dry_result).to eq Success(1)
    end

    it 'performs switching without shortcuts' do
      caster =
        Datacaster.schema do
          switch.
            on(integer, transform(&:to_s)).
            on(string, to_integer)
        end

      expect(caster.(5).to_dry_result).to eq Success('5')
      expect(caster.('5').to_dry_result).to eq Success(5)
    end

    it 'performs switching with keyword arg definition' do
      caster =
        Datacaster.schema do
          switch(
            integer => transform(&:to_s),
            string => to_integer
          )
        end

      expect(caster.(5).to_dry_result).to eq Success('5')
      expect(caster.('5').to_dry_result).to eq Success(5)
    end

    it 'performs switching with string/symbol interchangebly' do
      caster =
        Datacaster.schema do
          switch(:kind,
            'person' => transform { 'person' },
            :entity => transform { 'entity' }
          )
        end

      expect(caster.(kind: 'person').to_dry_result).to eq Success('person')
      expect(caster.(kind: :person).to_dry_result).to eq Success('person')
      expect(caster.(kind: 'entity').to_dry_result).to eq Success('entity')
      expect(caster.(kind: :entity).to_dry_result).to eq Success('entity')

      caster =
        Datacaster.schema do
          switch(:kind).
            on('person', transform { 'person' }, strict: true).
            on(:entity, transform { 'entity' }, strict: true)
        end

      expect(caster.(kind: 'person').to_dry_result).to eq Success('person')
      expect(caster.(kind: :person).to_dry_result).to eq Failure(['is invalid'])
      expect(caster.(kind: 'entity').to_dry_result).to eq Failure(['is invalid'])
      expect(caster.(kind: :entity).to_dry_result).to eq Success('entity')
    end

    it 'returns error of switch caster' do
      caster =
        Datacaster.schema do
          key_extractor = cast do |x|
            if x.key?(:test)
              Datacaster.ValidResult(x[:test])
            else
              Datacaster.ErrorResult(test: [Datacaster::I18nValues::Key.new(['.any', 'datacaster.errors.any'], value: x)])
            end
          end

          switch(key_extractor).
            on(1, transform_to_value('1')).
            on(2, transform_to_value('2'))
        end

      expect(caster.({test: 1}).to_dry_result).to eq Success('1')
      expect(caster.({}).to_dry_result).to eq Failure(test: ["should be present"])
    end

    it 'returns standard error without else clause' do
      caster =
        Datacaster.schema do
          switch.
            on(1, transform_to_value('1')).
            on(2, transform_to_value('2'))
        end

      expect(caster.(3).to_dry_result).to eq Failure(["is invalid"])
    end

    it 'marks matched-on value as checked' do
      caster =
        Datacaster.schema do
          switch(:kind).
            on(1, hash_schema(name: string))
        end

      expect(caster.(kind: 1, name: '1').to_dry_result).to eq Success(kind: 1, name: '1')

      caster =
        Datacaster.schema do
          s = Datacaster.schema { string }
          switch(:kind).on('person', hash_schema(kind: s))
        end

      expect(caster.(kind: 'person').to_dry_result).to eq Success(kind: 'person')

      caster =
        Datacaster.schema do
          blockchain = hash_schema(a: string)
          bank = hash_schema(b: string)

          blockchain_or_bank = switch(:kind, blockchain: blockchain, bank: bank)

          blockchain_or_bank & hash_schema(c: string)
        end

      value = {kind: :blockchain, a: 'asd', c: 'asd'}

      expect(caster.(value).to_dry_result).to eq Success(value)
    end
  end
end
