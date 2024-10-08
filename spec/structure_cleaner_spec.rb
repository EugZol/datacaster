RSpec.describe Datacaster do
  include Dry::Monads[:result]

  it 'transform marks hashes as cleaned' do
    caster =
      Datacaster.schema do
        hash_schema(a: string) & transform { { b: 'value' } }
      end
    expect(caster.(a: 'value').to_dry_result).to eq Success(b: 'value')
  end

  it 'transform can cast to classes' do
    i = Class.new.new

    caster =
      Datacaster.schema do
        hash_schema(a: string) & transform { i }
      end
    expect(caster.(a: 'value').to_dry_result).to eq Success(i)
  end

  it 'defaults marks hashes as cleaned' do
    caster =
      Datacaster.schema do
        hash_schema(a: string) & remove & default({b: 'value'})
      end
    expect(caster.(a: 'value').to_dry_result).to eq Success(b: 'value')
  end

  it 'hash_value is reopened for check with hash_schema' do
    caster =
      Datacaster.schema do
        hash_schema(a: string) & hash_value
      end
    expect(caster.(a: 'value', b: 'value').to_dry_result).to eq Failure(b: ["must be absent"])

    caster =
      Datacaster.schema do
        hash_value & hash_schema(a: string)
      end
    expect(caster.(a: 'value', b: 'value').to_dry_result).to eq Failure(b: ["must be absent"])
  end
end
