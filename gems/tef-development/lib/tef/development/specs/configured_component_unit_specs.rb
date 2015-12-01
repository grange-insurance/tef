shared_examples_for 'a configured component' do

  # 'clazz' must be defined by an including scope

  it 'is purely configured' do
    expect(clazz.instance_method(:initialize).parameters.count).to eq(1)
  end

end


shared_examples_for 'a loosely configured component' do

  describe 'common loosely configured behavior' do
    it_should_behave_like 'a configured component'
  end

  describe 'unique loosely configured behavior' do

    # 'clazz' must be defined by an including scope

    it 'can optionally be given configuration options' do
      expect(clazz.instance_method(:initialize).arity).to eq(-1)
    end

    it 'has sufficient defaults to initialize without a problem' do
      expect { clazz.new }.to_not raise_error
    end

  end

end


shared_examples_for 'a strictly configured component' do

  describe 'common strictly configured behavior' do
    it_should_behave_like 'a configured component'
  end

  describe 'unique strictly configured behavior' do

    # 'clazz' must be defined by an including scope

    it 'must be given configuration options' do
      expect(clazz.instance_method(:initialize).arity).to eq(1)
    end

  end

end
