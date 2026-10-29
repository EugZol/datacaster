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

  it 'concurrent casts of one schema keep their own checks' do
    paused = Queue.new
    resume = Queue.new
    # The slow cast waits inside the schema until the fast one has finished
    caster =
      Datacaster.schema do
        switch(:kind).
          on('slow', hash_schema(kind: string, a: cast { |v| paused << true; resume.pop; Datacaster.ValidResult(v) })).
          on('fast', hash_schema(kind: string, b: string))
      end

    slow = Thread.new { caster.(kind: 'slow', a: 'value') }
    paused.pop
    expect(caster.(kind: 'fast', b: 'value').to_dry_result).to eq Success(kind: 'fast', b: 'value')
    resume << true
    expect(slow.value.to_dry_result).to eq Success(kind: 'slow', a: 'value')
  end

  it 'failed left branch of | does not mark its keys as checked' do
    caster =
      Datacaster.schema do
        hash_schema(kind: compare('person'), name: string) |
          hash_schema(kind: compare('company'), company_name: string)
      end
    expect(caster.(kind: 'company', company_name: 'ACME', name: 123).to_dry_result).
      to eq Failure(name: ["must be absent"])
  end

  it 'failed condition of then/else does not mark its keys as checked' do
    caster =
      Datacaster.schema do
        hash_schema(kind: compare('person'), name: string).
          then(pass).
          else(hash_schema(kind: compare('company'), company_name: string))
      end
    expect(caster.(kind: 'company', company_name: 'ACME', name: 123).to_dry_result).
      to eq Failure(name: ["must be absent"])
  end

  it 'failed switch condition does not mark its keys as checked' do
    caster =
      Datacaster.schema do
        switch.
          on(hash_schema(kind: compare('person'), name: string), pass).
          else(hash_schema(kind: compare('company'), company_name: string))
      end
    expect(caster.(kind: 'company', company_name: 'ACME', name: 123).to_dry_result).
      to eq Failure(name: ["must be absent"])
  end

  it 'failed branch inside with_context does not mark its keys as checked' do
    caster =
      Datacaster.schema do
        (
          hash_schema(kind: compare('person'), name: string) |
            hash_schema(kind: compare('company'), company_name: string)
        ).with_context(user: 'user')
      end
    expect(caster.(kind: 'company', company_name: 'ACME', name: 123).to_dry_result).
      to eq Failure(name: ["must be absent"])
  end

  it 'succeeded branch keeps its checks when nothing before it checked structure' do
    caster =
      Datacaster.schema do
        (switch(:kind).on('a', pass) | hash_schema(kind: compare('b'))) & hash_schema(x: string)
      end
    expect(caster.(kind: 'a', x: '1').to_dry_result).to eq Success(kind: 'a', x: '1')
  end

  it 'nested schema on a key already checked unconditionally keeps it checked' do
    caster =
      Datacaster.schema do
        hash_schema(a: pass) & hash_schema(a: hash_schema(b: string))
      end
    expect(caster.(a: {b: 'value', c: 'value'}).to_dry_result).to eq Success(a: {b: 'value', c: 'value'})
  end

  it 'succeeded branch keeps a key accepted whole when it checks inside it' do
    caster =
      Datacaster.schema do
        hash_schema(a: pass) &
          (hash_schema(a: hash_schema(y: string)) | pass)
      end
    expect(caster.(a: {x: 'value', y: 'value'}).to_dry_result).to eq Success(a: {x: 'value', y: 'value'})
  end
end
