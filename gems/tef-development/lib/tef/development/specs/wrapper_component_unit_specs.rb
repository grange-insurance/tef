shared_examples_for 'a wrapper component, unit level' do |message_endpoint_names|

  describe 'unique wrapper behavior' do

    # 'clazz' must be defined by an including scope
    # 'configuration' must be defined by an including scope

    let(:component) { clazz.new(configuration) }


    message_endpoint_names.each do |endpoint_name|

      it "knows the name of its message exchange/queue (#{endpoint_name})" do
        expect(component).to respond_to("#{endpoint_name}_name")
      end

    end

  end
end
