RSpec.describe Datacaster do
  include Dry::Monads[:result]

  DefaultKeys = Datacaster::I18nValues::DefaultKeys
  Key = Datacaster::I18nValues::Key
  Scope = Datacaster::I18nValues::Scope

  before(:all) do
    require 'i18n'
    Datacaster::Config.i18n_initialize!
    I18n.load_path += [__dir__ + '/fixtures/locales.yml']
  end

  describe 'i18n' do
    it 'returns default errors' do
      schema = Datacaster.schema { check { false } }
      expect(schema.(1).raw_errors).to eq [DefaultKeys.new(['.check', 'datacaster.errors.check'], value: 1)]
    end

    it 'overrides default values' do
      schema = Datacaster.schema { check { false } }.i18n_key('.check_me')
      expect(schema.('1').raw_errors).to eq [Key.new('.check_me', value: '1')]
    end

    it 'composes scopes' do
      schema = Datacaster.schema { check { false }.i18n_key('.check_me') }.i18n_scope('.namespace')
      expect(schema.('1').raw_errors).to eq [Key.new('.namespace.check_me', value: '1')]
    end

    it 'allows to redefine array/hash errors with #i18n_key' do
      schema = Datacaster.schema do
        hash_schema(
          a: check { false }
        ).i18n_key('.not_a_hash')
      end.i18n_scope('namespace')

      expect(schema.(1).raw_errors).to eq [Key.new('namespace.not_a_hash', value: 1)]

      schema = Datacaster.schema do
        array_of(check { false }).i18n_key('.not_an_array')
      end.i18n_scope('namespace')

      expect(schema.(1).raw_errors).to eq [Key.new('namespace.not_an_array', value: 1)]
    end

    it 'allows to redefine array/hash errors with #i18n_map_keys' do
      schema = Datacaster.schema do
        hash_schema(
          a: check { false }
        ).i18n_map_keys('.hash_value' => '.not_a_hash')
      end.i18n_scope('namespace')

      expect(schema.(1).raw_errors).to eq [Key.new('namespace.not_a_hash', value: 1)]

      schema = Datacaster.schema do
        array_of(check { false }).i18n_map_keys(
          '.array' => '.not_an_array',
          '.empty' => '.empty_array'
        )
      end.i18n_scope('namespace')

      expect(schema.(1).raw_errors).to eq [Key.new('namespace.not_an_array', value: 1)]
      expect(schema.([]).raw_errors).to eq [Key.new('namespace.empty_array', value: [])]
    end

    it 'works with complex structures' do
      schema = Datacaster.schema do
        nested = hash_schema(
          a: check { false }.i18n_scope('.a'),
          b: check { false }.i18n_scope('namespace2.b'),
        )
        hash_schema(
          related: nested.i18n_scope('.nested'),
          c: check { false }.i18n_scope('.c'),
          d: array_of(check { false }.i18n_key('.d'))
        )
      end.i18n_scope('namespace')

      expect(schema.({d: ['a'], related: {}}).raw_errors).to eq(
        c: [DefaultKeys.new(['namespace.c.check', 'datacaster.errors.check'], value: Datacaster.absent)],
        d: {
          0 => [
            Key.new('namespace.d', value: 'a')
          ]
        },
        related: {
          a: [DefaultKeys.new(['namespace.nested.a.check', 'datacaster.errors.check'], value: Datacaster.absent)],
          b: [DefaultKeys.new(['namespace2.b.check', 'datacaster.errors.check'], value: Datacaster.absent)]
        }
      )
    end

    it 'assigns compile-time variables' do
      schema = Datacaster.schema do
        nested = hash_schema(
          a: check { false }.i18n_key('.a', a: true),
          b: check { false }.i18n_scope('namespace2.b', b1: true, b2: true),
        )
        hash_schema(
          related: nested.i18n_scope('.nested'),
        )
      end.i18n_scope('namespace', namespace: true, b2: false)

      expect(schema.({d: ['a'], related: {}}).raw_errors).to eq(
        related: {
          a: [Key.new('namespace.nested.a', value: Datacaster.absent, namespace: true, a: true, b2: false)],
          b: [DefaultKeys.new(['namespace2.b.check', 'datacaster.errors.check'], value: Datacaster.absent, namespace: true, b1: true, b2: false)]
        }
      )
    end

    it 'assigns run-time variables with #i18n_var(s)!' do
      schema = Datacaster.schema do
        nested = hash_schema(
          a: check { i18n_var!(:a2, true); false }.i18n_key('.a', a1: true),
          b: check { i18n_vars!(b1: false, value: 2); false }.i18n_scope('namespace2.b', b1: true, b2: true),
        )
        hash_schema(
          related: nested.i18n_scope('.nested'),
        )
      end.i18n_scope('namespace', namespace: true, b2: false)

      expect(schema.({d: ['a'], related: {}}).raw_errors).to eq(
        related: {
          a: [Key.new('namespace.nested.a', value: Datacaster.absent, namespace: true, a1: true, a2: true, b2: false)],
          b: [DefaultKeys.new(['namespace2.b.check', 'datacaster.errors.check'], value: 2, namespace: true, b1: false, b2: false)]
        }
      )
    end

    it 'resolves to strings' do
      schema = Datacaster.schema do
        nested = hash_schema(
          a: check { i18n_var!(:a2, true); false }.i18n_key('.a', a1: true),
          b: check { i18n_vars!(b1: false, value: 2); false }.i18n_scope('namespace2.b', b1: true, b2: true),
        )
        hash_schema(
          related: nested.i18n_scope('.nested'),
        )
      end.i18n_scope('namespace', namespace: true, b2: false)

      expect(schema.({d: ['a'], related: {}}).errors).to eq(
        related: {
          a: ['namespace-nested-a, namespace true, a1 true, a2 true, b2 false, value '],
          b: ['namespace2-b-check, namespace true, b1 false, b2 false, value 2']
        }
      )
    end

    it 'resolves to default' do
      schema = Datacaster.schema do
        check { false }
      end.i18n_scope('not_found')

      expect(schema.(1).errors).to eq ['is invalid']
    end
  end
end
