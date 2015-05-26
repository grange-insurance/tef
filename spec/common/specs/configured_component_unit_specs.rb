shared_examples_for 'a configured component' do |clazz|

  it 'is purely configured' do
    expect(clazz.instance_method(:initialize).parameters.count).to eq(1)
  end

end


shared_examples_for 'a loosely configured component' do |clazz|

  it_should_behave_like 'a configured component', clazz

  it 'can optionally be given configuration options' do
    expect(clazz.instance_method(:initialize).arity).to eq(-1)
  end

  it 'has sufficient defaults to initialize without a problem' do
    expect { clazz.new }.to_not raise_error
  end

end


shared_examples_for 'a strictly configured component' do |clazz|

  it_should_behave_like 'a configured component', clazz

  it 'must be given configuration options' do
    expect(clazz.instance_method(:initialize).arity).to eq(1)
  end

end
