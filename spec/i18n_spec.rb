RSpec.describe Datacaster do
  include Dry::Monads[:result]

  Key = Datacaster::I18nValues::Key
  Key = Datacaster::I18nValues::Key
  Scope = Datacaster::I18nValues::Scope

  describe 'i18n' do
    it 'returns default errors' do
      schema = Datacaster.schema { check { false } }
      expect(schema.(1).raw_errors).to eq [Key.new(['.check', 'datacaster.errors.check'], value: 1)]
    end

    it 'overrides default values' do
      schema = Datacaster.schema { check { false } }.i18n_key('.check_me')
      expect(schema.('1').raw_errors).to eq [Key.new('.check_me', value: '1')]
    end

    it 'composes scopes' do
      schema = Datacaster.schema { check { false }.i18n_key('.check_me') }.i18n_scope('.namespace')
      expect(schema.('1').raw_errors).to eq [Key.new('.namespace.check_me', value: '1')]
    end

    it 'works with schema i18n_scope argument' do
      schema = Datacaster.schema(i18n_scope: '.namespace') { check { false }.i18n_key('.check_me') }
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

    it 'allows to redefine switch node errors with #i18n_key' do
      schema =
        Datacaster.schema do
          switch(pick(:key)).
            on(1, hash_schema(other_key: check { false }.i18n_key('.one'))).
            i18n_key('.two').
            i18n_scope('switch')
        end

      expect(schema.(key: 1).raw_errors).to eq({other_key: [Key.new(['switch.other_key.one', 'switch.one'], value: Datacaster.absent)]})
      expect(schema.(key: 2).raw_errors).to eq([Key.new('switch.two', value: {key: 2})])
    end

    it 'allows to redefine array/hash errors with #i18n_map_keys' do
      schema = Datacaster.schema do
        hash_schema(
          a: check { false }
        ).i18n_map_keys('.hash_value' => '.not_a_hash')
      end.i18n_scope('namespace')

      expect(schema.(1).raw_errors).to eq [Key.new('namespace.not_a_hash', value: 1)]

      schema = Datacaster.schema do
        array_of(check { false }, allow_empty: false).i18n_map_keys(
          '.array' => '.not_an_array',
          '.empty' => '.empty_array'
        )
      end.i18n_scope('namespace')

      expect(schema.(1).raw_errors).to eq [Key.new('namespace.not_an_array', value: 1)]
      expect(schema.([]).raw_errors).to eq [Key.new('namespace.empty_array', value: [])]
    end

    it 'auto-scopes hash keys' do
      schema = Datacaster.schema do
        hash_schema(
          a: {b: check { false }}
        )
      end.i18n_scope('namespace')

      expect(schema.({a: {}}).raw_errors).to eq({a: {b: [Key.new([
        'namespace.a.b.check',
        'namespace.a.check',
        'namespace.check',
        'datacaster.errors.check'
      ], value: Datacaster.absent)]}})
    end

    it "doesn't auto-scope array elements" do
      schema = Datacaster.schema do
        array_of(integer)
      end.i18n_scope('namespace')

      expect(schema.(['1']).raw_errors).to eq(0 => [Key.new([
        'namespace.integer',
        'datacaster.errors.integer'
      ], value: '1')])
    end

    it "doesn't auto-scope when explicit scope is attached" do
      schema = Datacaster.schema do
        hash_schema(
          a: integer.i18n_scope('.ah')
        )
      end.i18n_scope('namespace')

      expect(schema.({a: 'v'}).raw_errors).to eq({a: [Key.new([
        'namespace.ah.integer',
        'datacaster.errors.integer'
      ], value: 'v')]})
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
          d: array_of(check { false }.i18n_key('.wrong_d_element'))
        )
      end.i18n_scope('namespace')

      expect(schema.({d: ['a'], related: {}}).raw_errors).to eq(
        c: [Key.new(['namespace.c.check', 'datacaster.errors.check'], value: Datacaster.absent)],
        d: {
          0 => [
            Key.new([
              'namespace.d.wrong_d_element',
              'namespace.wrong_d_element'
            ], value: 'a')
          ]
        },
        related: {
          a: [Key.new(['namespace.nested.a.check', 'datacaster.errors.check'], value: Datacaster.absent)],
          b: [Key.new(['namespace2.b.check', 'datacaster.errors.check'], value: Datacaster.absent)]
        }
      )
    end

    it 'assigns compile-time variables' do
      schema = Datacaster.schema do
        nested = hash_schema(
          a: check { false }.i18n_vars(a: true),
          b: check { false }.i18n_scope('namespace2.b', b1: true, b2: true),
        )
        hash_schema(
          related: nested.i18n_scope('.nested'),
        )
      end.i18n_scope('namespace', namespace: true, b2: false)

      expect(schema.({d: ['a'], related: {}}).raw_errors).to eq(
        related: {
          a: [Key.new(['namespace.nested.a.check', 'namespace.nested.check', 'datacaster.errors.check'], value: Datacaster.absent, namespace: true, a: true, b2: false)],
          b: [Key.new(['namespace2.b.check', 'datacaster.errors.check'], value: Datacaster.absent, namespace: true, b1: true, b2: false)]
        }
      )
    end

    it 'assigns run-time variables with #i18n_var(s)!' do
      schema = Datacaster.schema do
        nested = hash_schema(
          a: check { i18n_var!(:a2, true); false }.i18n_key('.a_wrong', a1: true),
          b: check { i18n_vars!(b1: false, value: 2); false }.i18n_scope('namespace2.b', b1: true, b2: true),
        )
        hash_schema(
          related: nested.i18n_scope('.nested'),
        )
      end.i18n_scope('namespace', namespace: true, b2: false)

      expect(schema.({d: ['a'], related: {}}).raw_errors).to eq(
        related: {
          a: [Key.new(['namespace.nested.a.a_wrong', 'namespace.nested.a_wrong'], value: Datacaster.absent, namespace: true, a1: true, a2: true, b2: false)],
          b: [Key.new(['namespace2.b.check', 'datacaster.errors.check'], value: 2, namespace: true, b1: false, b2: false)]
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
